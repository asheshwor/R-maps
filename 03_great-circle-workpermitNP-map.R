#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*     Load packages
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
library(maps)
library(geosphere)
#library(ggmap) #only if using google geolocation
require(xlsx) #only if excel file is to be read
library(RColorBrewer)
require(scales)
library(plyr) 
library(ggplot2)
library(sp)
require(rgdal)
#require(raster) #for using raster data
#source("C:/Users/Lenovo/Documents/R_source/fort.R") #for solving fortify error
source("fort.R")
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*     Functions
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# the functions to regroup, and close polygons have been used from
# https://github.com/cengel/GreatCircle/blob/master/GreatCircleFlights.R
# as explained here, 
# http://www.stanford.edu/~cengel/cgi-bin/anthrospace/great-circles-on-a-recentered-worldmap-in-ggplot
### Function to regroup split lines and polygons
# takes dataframe, column with long and unique group variable, returns df with added column named group.regroup
RegroupElements <- function(df, longcol, idcol){  
  g <- rep(1, length(df[,longcol]))
  if (diff(range(df[,longcol])) > 300) {          # check if longitude within group differs more than 300 deg, ie if element was split
    d <- df[,longcol] > mean(range(df[,longcol])) # we use the mean to help us separate the extreme values
    g[!d] <- 1     # some marker for parts that stay in place (we cheat here a little, as we do not take into account concave polygons)
    g[d] <- 2      # parts that are moved
  }
  g <-  paste(df[, idcol], g, sep=".") # attach to id to create unique group variable for the dataset
  df$group.regroup <- g
  df
}
### Function to close regrouped polygons
# takes dataframe, checks if 1st and last longitude value are the same, if not, inserts first as last and reassigns order variable
ClosePolygons <- function(df, longcol, ordercol){
  if (df[1,longcol] != df[nrow(df),longcol]) {
    tmp <- df[1,]
    df <- rbind(df,tmp)
  }
  o <- c(1: nrow(df))  # rassign the order variable
  df[,ordercol] <- o
  df
}
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*     Read and prepare data
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# The work permit data are extracted from Department of Foreign Employment
# website at 
# http://dofe.gov.np/uploads/document/FA66_67_20120621012840.pdf
# A few edits have been done on the names of the countries to match
# with common country names. While I've tried to make the data exact,
# please check the original as I do not claim this to be free from
# errors.

migrnp <- "C:/Users/Lenovo/Dropbox/Napier/R_map/workpermitNepal.xlsx"

np.data <- read.xlsx(migrnp, 7) #read excel sheet 7
#names(np.data) <- c("Country", "Location", "Total", "EDR", "CDR", "WDR", "MWDR", "FWDR")

#np.data <- np.data[!(np.data$Location == "NA"),]
np.data <- np.data[with(np.data, order(-Total)),] #remove 4 debug

#the origin point of the lines
p1 <- c(84.12, 28.39) #center of Nepal, sort of
#countries with lat long found here,
#http://dev.maxmind.com/geoip/legacy/codes/average-latitude-and-longitude-for-countries/
countriesll <- read.csv("D:/R/Map/country_latlon.csv", header=TRUE, stringsAsFactors=FALSE)
names(countriesll) <- c("isocode", "lat", "lon")
#the countries are named by their iso codes, need to find full names so
#here's another table from
# http://blog.plsoucy.com/2012/04/iso-3166-country-code-list-csv-sql/
countries <- read.csv("D:/R/Map/countries.csv", header=TRUE, stringsAsFactors=FALSE, na.string="DNA")
names(countries) <- c("isocode", "Country", "namefrench")
#merge the two
comerged <- merge(countries, countriesll, by="isocode")
comerged <- comerged[,-3] #remove French names
#writing merged data to excel file
#write.xlsx(comerged, "countries.xlsx", sheetName="Countries")
#merge with Nepal data
np.merged <- merge(np.data, comerged, by="Country", all.x=TRUE)
np.merged <- np.merged[with(np.merged, order(-Total)),]
#loc.geo <- data.frame(lon = np.merged$lon, lat = np.merged$lat) #debug alert
#loc.geo <- cbind(np.merged$lon, np.merged$lat)
loc.geo <- data.frame(lon = as.numeric(np.merged$lon), lat = as.numeric(np.merged$lat))
#define colours
#couleur1 <- brewer.pal(12, "Paired")
couleur <- brewer.pal(9, "PuRd")
# read world shapefile from natural earth
wmap <- readOGR(dsn="D:/R/Map/110m_cultural", layer="ne_110m_admin_0_countries")
# convert to dataframe
wmap_df <- fortify(wmap)
#get position of cities from http://www.geonames.org/export/ database
places <- read.delim("D:/R/Map/cities1000.txt", header=FALSE, sep="\t")
##get position of cities from naturalearth.com cities database 10m
places2 <- readOGR(dsn="D:/R/Map/10m_populated_places", layer="ne_10m_populated_places")
# convert to dataframe
places2.df <- data.frame(lon=places2$LONGITUDE, lat = places2$LATITUDE)
#only keep V5 and V6 columns i.e. lat and lon
places.df <- data.frame (places$V6, places$V5)
names(places.df) <- c('lon', "lat")
#collect great circles from p1 to each country
cgc <- gcIntermediate(p1, loc.geo, 100, breakAtDateLine=FALSE, addStartEnd=TRUE, sp=TRUE)
cgc.ff <- fortify.SpatialLinesDataFrame(cgc)
#data frame for id
loc.geo.df <- data.frame(loc.geo) # debug alert
loc.geo.df$location <- np.merged$Country
loc.geo.df$total <- np.merged$Total
loc.geo.df$id <- as.character(c(1:nrow(loc.geo.df))) #making id character
names(loc.geo.df) <- c("lon.old", "lat.old", "location", "total", "id")
cgc.ffm <- merge(cgc.ff, loc.geo.df, all.x=T, by="id")
#move map center to Nepal
center <- 84
# shift coordinates to recenter great circles
cgc.ffm$lon.r <- ifelse(cgc.ffm$long < center -180, cgc.ffm$long +360, cgc.ffm$long)
#shift places
places.df$lon.r <- ifelse(places.df$lon < center -180, places.df$lon +360, places.df$lon)
places2.df$lon.r <- ifelse(places2.df$lon < center -180, places2.df$lon +360, places2.df$lon)
# shift coordinates to recenter worldmap
      # worldmap <- map_data ("world")
      # worldmap$long.recenter <-  ifelse(worldmap$long  < center - 180 , worldmap$long + 360, worldmap$long)
wmap_df$long.recenter <- ifelse(wmap_df$long  < center - 180 , wmap_df$long + 360, wmap_df$long)
# now regroup
cgc.ff.r <- ddply(cgc.ffm, .(id), RegroupElements, "lon.r", "id")
#worldmap.rg <- ddply(worldmap, .(group), RegroupElements, "long.recenter", "group")
worldmap.rg <- ddply(wmap_df, .(group), RegroupElements, "long.recenter", "group")
# close polys
#worldmap.cp <- worldmap.rg
worldmap.cp <- ddply(worldmap.rg, .(group.regroup), ClosePolygons, "long.recenter", "order")  # use the new grouping var
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*     Plotting using ggplot2
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
mapLabel <- "Permit figures from Department of Foreign Employment www.dofe.gov.np \n Country boundaries from NaturalEarthData.com \n Location of cities from NaturalEarthData.com & geonames.org"
mapTitle <- "Nepalis working abroad - international work permits issued and destination countries FY 2067-68 (2010-11)"
noteText <- "[ Code @ https://github.com/asheshwor/R-maps/blob/master/02_great-circle-map.R ]"
png(file="tourmap.png", 1280, 720)

ggplot() +
  geom_polygon(aes(long.recenter,lat,group=group.regroup), 
               size = 0.2, fill="darkslategray", colour = NA,
               data=worldmap.cp) + #country backdrop
  geom_point(aes(lon.r, lat), col=couleur[2], size=0.5,
             alpha=0.2, data=places2.df) + #natural earth cities as backdrop
  geom_point(aes(lon.r, lat), col=couleur[2], size=0.2,
             alpha=0.1, data=places.df) + #geonames.org cities as backdrop
  geom_polygon(aes(long.recenter,lat,group=group.regroup), 
               size = 0.1, fill=NA, colour = "slategrey",
               data=worldmap.cp, alpha=0.5) + #country boundary
  geom_line(aes(lon.r, lat, group=group.regroup),
            col=couleur[4],
            size=.3, alpha=0.7, data= cgc.ff.r) + #drawing great circle lines
  geom_line(aes(lon.r,lat, color=total, 
                #alpha=total,
                alpha=0.8,
                group=group.regroup),
            #col=couleur[6],
            size=1.1, data= cgc.ff.r) + #great circle lines overlay
  guides(alpha = "none") +
  scale_colour_gradient(high="red1", low="green3", 
                        trans = "log",
                        name="Permits",
                        labels = comma,
                        #breaks=seq(min(np.data$Total), max(np.data$Total), by=1000)
                        breaks=c(2, 10, 100, 1000, 10000, 400000)
  ) +
  ylim(-60, 90) +
  theme(
    plot.background = element_blank()
    ,panel.grid.major = element_blank()
    ,panel.grid.minor = element_blank()
    ,panel.border = element_blank()
    ,panel.background = element_rect(fill='grey24', colour='black')
    ,legend.position = c(.9,.3)
    ,legend.background = element_rect(fill = "grey24", color="darkgrey")
    ,legend.text = element_text(size = 10, colour = "mintcream")
    ,legend.title = element_text(size = 13, colour = "mintcream")
    ,axis.text.x  = element_blank()
    ,axis.text.y  = element_blank()
    ,axis.ticks  = element_blank()
    ,axis.title  = element_blank()
    ,axis.title  = element_blank()
  ) + 
  geom_text(aes(x= 200, y=-56, 
                label=mapLabel),
            color="lightgrey", size=5) +
  geom_text(aes(x= 84, y=90, 
                label=mapTitle),
            color="lightgrey", size=8) +
  geom_text(aes(x= 0, y=-60, 
                label=noteText),
            color="lightgrey", size=5) +
  coord_equal()
dev.off()