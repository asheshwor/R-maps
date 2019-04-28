#load packages
require(tidyverse)
require(ggmap)
require(jsonlite)
require(RColorBrewer)
##### 1. Read output from google takeout
## get your location history from https://takeout.google.com/settings/takeout
data.locationhistory <- fromJSON('X:/google/Takeout/Location History/Location History.json')
##### 2. Extract locations
data.locationhistory <- data.locationhistory$locations
# check columns and rows
# names(data.locationhistory)
# nrow(data.locationhistory)
# lapply(data.locationhistory, class)
#extract lon, lat and time components
#the following is not working as the output from Google takeout seems to be messed up. Hope this is fixed soon. Substracting 4294967296 seem to work for lat. Lon already works for my subset which only had southern hemisphere data
location.df <- data.frame(t = as.POSIXct(as.numeric(data.locationhistory$timestampMs) / 1000,
                                         origin = "1970-01-01"),
                          lon = as.numeric(data.locationhistory$longitudeE7/1E7),
                          lat= as.numeric(data.locationhistory$latitudeE7/1E7))
#filter/subset
location.df <- location.df %>% filter((t > as.POSIXct("2017-01-01 00:00:01")) &
                                        (t < as.POSIXct("2018-01-01 00:00:01")))
#add months
location.df <- location.df %>%
  mutate(doy = strftime(t, format = "%j"),
        m = strftime(t, format = "%b")) %>%
  mutate(m = factor(m, levels = month.abb)) #or month.name
##### 3. Plot simple
#set colour
couleur <- brewer.pal(9, "PuRd")
adl <- "Adelaide, South Australia"
##Google API authentication - new requirement
register_google(key = "*********API KEY************")
adl.map <- qmap(adl, zoom=15, maptype="terrain")
adl.map + geom_point(aes(x = lon, y = lat), size=1,
                     data = location.df,
                     color = "darkgreen", alpha = 0.5)
#### 4. Plot monthly
#png("AdelaideArea15_x.png", 1080, 1080)
adl.map <- qmap(adl, zoom=11, maptype = "terrain", legend = "topleft")

adl.map + geom_point(aes(x = lon, y = lat), size=.75,
                     data = location.df,
                     color = couleur[6], alpha = 0.5) +
  facet_wrap(~m, nrow = 3)
#dev.off()
