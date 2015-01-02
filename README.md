Mapping techniques in R
---------
This is a collection of R code for visualizing spatial data. The different types of mapping techniques portrayed here are discussed below. As I explore more techniques, they will be added to the list.

1. Simple country map with point data added
----------
In this example, point data is mapped onto a country map.

https://github.com/asheshwor/R-maps/blob/master/01_simple-map.R

2. Great circle map
----------
Points across the globe are connected using great circle arcs in this example. An excellent way to visualize global inter-connections. In the first example, tourist arrival data for Nepal is visualized with colours representing the number of arrivales. The arrival figures have been extracted from pdf file at http://www.tourism.gov.np/uploaded/TourrismStat2012.pdf with a few edits on the name of countires to match the ones on the map.

https://github.com/asheshwor/R-maps/blob/master/02_great-circle-map.R

![R plot](Plots/gcmap_nepal_tourist_2012.jpg)

Another example of great circle map with international work permits data for Nepal. The figures have been extracted from pdf file at www.dofe.gov.np (in Nepali language) with minor edits on the name of countries.

![R plot](Plots/WorkPermitsNP2011.jpg)

3. Dynamic heatmap using leaflet and leafletheat plugin
----------
See example at http://asheshwor.com.np/host/heatmap.html
![Dynamic heatmap plot](Plots/heatmap4.jpg)