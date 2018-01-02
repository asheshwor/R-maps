#load packages
require(ggmap)
require(jsonlite)
##### 1. Read output from google takeout
## get your location history from https://takeout.google.com/settings/takeout
data.locationhistory <- fromJSON('X:/rdump/google/Takeout/Location History/Location History.json')
##### 2. Extract locations
data.locationhistory <- data.locationhistory$locations #don't see any different
# check columns and rows
# names(data.locationhistory)
# nrow(data.locationhistory)
# lapply(data.locationhistory, class)
#extract lon, lat and time components
location.df <- data.frame(t = as.POSIXct(as.numeric(data.locationhistory$timestampMs) / 1000,
                                         origin = "1970-01-01"),
                          lon = as.numeric(data.locationhistory$longitudeE7/1E7),
                          lat= as.numeric(data.locationhistory$latitudeE7/1E7))
#filter/subset
location.df <- location.df[(location.df$t > as.POSIXct("2017-10-01 00:00:01")) &
             (location.df$t < as.POSIXct("2018-01-01 00:00:01")),]
##### 3. Plot
adl <- "Adelaide, South Australia"
adl.map <- qmap(adl, zoom=15, maptype="terrain")
adl.map + geom_point(aes(x = lon, y = lat), size=1,
                     data = location.df,
                     color = "darkgreen", alpha = 0.5)
