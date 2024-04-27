library(sf)
library(ggplot2)
library(tidyverse)
library(ggspatial)
library(tidyverse)
library(bcmaps)
library(leaflet)

# set working directory
# setwd("C:/path")

# read shapefile
## shapefile downloaded from: https://catalogue.data.gov.bc.ca/dataset/dfo-fisheries-management-sub-areas
DFO_subareas <- st_read("DFO_SBAREA_polygon.shp")

# get centroids of polygons
centroids_nad83 <- st_centroid(DFO_subareas) # NAD83

# get centroid lat
# transform to latitude/longitude
centroids <- st_transform(centroids_nad83, crs = "WGS84")

# keep only relevant cols
centroids <- centroids[,-c(2:5)]

# data frame with every centroid's coordinates
coordinates <- data.frame(cbind(centroids$LABEL, 
                                centroids$DFO_SUB_ID, 
                                st_coordinates(centroids)))

# change col names
colnames(coordinates) <- c("LABEL", "DFO_id", "lon", "lat")

# change DFO_id to numeric type
coordinates$DFO_id <- as.numeric(coordinates$DFO_id)

# save coordinates df as csv
write.csv(coordinates,file='centroid_coordinates.csv')

## DF -> SP OBJECT (add geometry) -------------
centroids_map <- coordinates %>% 
  st_as_sf(coords = c("lon", "lat"), crs = (st_crs(4269))) %>% 
  st_transform(st_crs(DFO_subareas))

# save as shapefile to be used in ArcGIS Pro
sf::st_write(centroids_map, 
#             "C:/path",
             driver = "ESRI shapefile")

# PLOT CENTROIDS IN R ----------------------------
ggplot() + 
  # add static map
  annotation_map_tile(
    type = "osm", # from OpenStreetMap
    cachedir = "maps/", # download map into a cache directory in your folder
    zoom = 4) + # sets the zoom level relative to the default
  geom_sf(data = DFO_subareas, color = "darkgray", alpha = 0.9) + 
  geom_sf(data = bc_bound, fill = "green", alpha = 0.1) +
  geom_sf(data = centroids, color = "#ff7800", size = 0.5, alpha = 0.8) +
  coord_sf(xlim = c(-122, -139), ylim = c(46.5, 56.5), crs=4269) +
  annotate("text", 
           x=-138.95, 
           y=46.5, 
           label="Basemap: Leaflet (2024); \nSubareas: BC Data Catalogue (2021)", 
           size=4,
           hjust=0) +
  theme(axis.title.x=element_blank(), axis.title.y = element_blank())


# plot subareas
plot_biotoxin <- ggplot(DFO_subareas) +
  geom_sf(data = DFO_subareas, color = "darkgray") +
  coord_sf()
