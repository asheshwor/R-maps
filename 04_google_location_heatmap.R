#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*     Load packages
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
library(rCharts)
library(plyr)
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*       Function to read coordinates
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#Function based on code by mdsumner
#from http://stackoverflow.com/questions/10492896/getkmlcoordinates-returns-a-list-of-lists-instead-of-a-list-of-segments
getKMLcoordinates_01 <- function (kmlfile, ignoreAltitude = FALSE) 
{
  if (missing(kmlfile)) 
    stop("kmlfile is missing")
  kml <- paste(readLines(kmlfile, encoding = "UTF-8"), collapse = " ")
  #re <- "<coordinates> *([^<]+?) *<\\/coordinates>"
  re <- "<gx:coord> *([^<]+?) *<\\/gx:coord>"
  ## ++ new code
  ## remove tabs first
  kml <- gsub("\\t", "", kml)
  mtchs <- gregexpr(re, kml)[[1]]
  coords <- list()
  for (i in 1:(length(mtchs))) {
    kmlCoords <- unlist(strsplit(gsub(re, "\\1", substr(kml, 
                                                        mtchs[i], (mtchs[i] + attr(mtchs, "match.length")[i])), 
                                      perl = TRUE), split = " "))
    m <- t(as.matrix(sapply(kmlCoords, function(x) as.numeric(unlist(strsplit(x, 
                                                                              ","))), USE.NAMES = FALSE)))
    if (!ignoreAltitude && dim(m)[2] != 3) 
      message(paste("no altitude values for KML object", 
                    i))
    coords <- append(coords, ifelse(ignoreAltitude, list(m[, 
                                                           1:2]), list(m)))
  }
  coords
}
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*       Setting up directory and files list
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
dirName <- "X:/History_full/2014/" #files for 2014 downloaded as 13 kml files
fileList <- c(dir(dirName))
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*       Extracting coordinates from KML
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
lat <- numeric(0)
lon <- numeric(0)
# WARNING!! may take a while to loop through
for (i in 1:length(fileList)) {
  dirTemp <- paste(dirName, fileList[i], sep="")
  hist <- getKMLcoordinates_01(dirTemp) #read KML file
  maxl <- length(hist)
  for (j in 1:maxl) {
    hist.0 <- hist[[j]]
    lat <- c(lat, hist.0[2])
    lon <- c(lon, hist.0[1])
  }
}
hist.df2 <- data.frame(lon, lat)
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*       Heatmap for location history
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
hist.df2$lon <- round(hist.df2$lon, 4) #optional
hist.df2$lat <- round(hist.df2$lat, 4)
hist.df2$id <- paste0(hist.df2$lon,"-", hist.df2$lat) #create identifier for each point
#randomize rows (optional) so that the actual sequence of co-ordinates is not revealed
hist.df2 <- hist.df2[sample(1:nrow(hist.df2), nrow(hist.df2)),]
hist.json <- ddply(hist.df2, .(lat, lon), summarise, count=length(id))
#draw leaflet map
leaf <- Leaflet$new()
leaf$setView(c(-34.928649, 138.599993), 13) #center map at Adelaide, South Australia
leaf$tileLayer(provider = "MapQuestOpen.OSM")
hist.json <- toJSONArray2(hist.json, json=F, names=F)
#Using leaflet-heat plugin by Vladimir Agafonkin https://github.com/mourner
leaf$addAssets(jshead = c("http://leaflet.github.io/Leaflet.heat/dist/leaflet-heat.js"
))
L2$setTemplate(afterScript = sprintf("
                                     <script>
                                     var locationPoints = %s
                                     var heat = L.heatLayer(locationPoints).addTo(map)           
                                     </script>
                                     ", rjson::toJSON(hist.json)
))
#viewing
leaf
#saving
leaf$save("leafletmap.html", standalone=TRUE)
#voila :)