#drawing points on basic country map
#example of plotting meteorological stations on country map of Nepal

#load packages
library(maps)
library(mapdata)
library(mapproj)
library(maptools)
library(RColorBrewer)
library(classInt)
library(rgdal)
library(scales)
#set working directory
setwd("C:/Users/Lenovo/Dropbox/Napier/R_map/climate")
#read csv file
# csv file made from data at http://www.dhm.gov.np/meteorological-station
# accessed on 15 June 2013 1100hrs Nepal ST
data <- read.csv('stations.csv', header = TRUE)
latround <- floor(data$lat/100)
lonround <- floor(data$lon/100)
latact <- latround+(data$lat-100*latround)/60
lonact <- lonround+(data$lon-100*lonround)/60
#plot unprojected nepal map
map("worldHires", "Nepal",  xlim=c(80,88.2), ylim=c(26,30.5), col="gray80", fill=TRUE, add=F)
map.axes()
title(paste("Meteorological stations in Nepal"))
#north arrow
#SpatialPolygonsRescale(layout.north.arrow(2), offset= c(720,150), scale = -50, plot.grid=T)
#scale
map.scale(80.5, 26.5, ratio=F, relwidth=0.2, cex=0.9)
#plot met stations points
points(lonact, latact, pch=19, col="red", cex=.4)
