# ========================================================================
# Interactive Map of DFO subareas with each centroid plotted.
# Centroids can be clicked to show the subarea ID and
# last PST, AST testing date per CFIA/BCCDC data.
# =========================================================================


## LOAD LIBRARIES -------------
library(leaflet)
library(sf)
library(ggspatial)
library(dplyr)

# # set working directory
#setwd("path")

# LOAD DATA --------------
# get data from dfo_centroids.R file
# set CRS as WGS84 (EPSG=3857) to match with Esri basemap

DFO_subareas <- st_read("DFO_SBAREA_polygon.shp")
DFO_subareas <- st_transform(DFO_subareas, "+proj=longlat +datum=WGS84")

coordinates <- read.csv("centroid_coordinates.csv")
coordinates <- coordinates %>%
  rename(DFO_id = DFO_SUB_ID)

# biotoxin data - download off github:
# https://github.com/Shirleyzhou0503/ENVR400_WATCH/tree/main/Biotoxin%20Data)

psp <- read.csv("psp_data.csv")
asp <- read.csv("asp_data.csv")


# GET LATEST TESTING DATES --------

# find latest testing date for each subarea
latest_test_psp <- psp %>%
  group_by(DFO_id) %>%
  summarise(psp_date = max(date))

latest_test_asp <- asp %>%
  group_by(DFO_id) %>%
  summarise(asp_date = max(date))

#join asp and psp test dates
latest_test_date <- full_join(latest_test_asp, latest_test_psp, by = "DFO_id")

# join test dates to coordinates df
coordinates2 <- left_join(coordinates, latest_test_date, by = "DFO_id")

# MAKE MAPS ----------------
#transform coordinates df to sf object
coordinates_map <- coordinates2 %>% 
  st_as_sf(coords = c("lon", "lat"), crs = (st_crs(3857))) %>% 
  st_transform(st_crs(DFO_subareas))

# plot with leaflet (interactive map)
# find backgrounds here: https://leaflet-extras.github.io/leaflet-providers/preview/
basemap <- leaflet() %>%
  addTiles() %>%
  addProviderTiles("CartoDB.VoyagerLabelsUnder")


dfo_map <- basemap %>%
  # add DFO subarea polygons
  addPolygons(
    data = DFO_subareas,
    # set the color of the polygon
    color = "#ff7800",
    # set the opacity of the outline
    opacity = 1,
    # set the stroke width in pixels
    weight = 1.5,
    # set the fill opacity
    fillOpacity = 0
  )
  
# add DFO subarea ID labels
dfo_map <- dfo_map %>%  
  addCircleMarkers(
      data = coordinates,
      lng = coordinates$lon,
      lat = coordinates$lat,
      radius = 3,
      color = "#03F",
      weight = 3,
      opacity = 0.75,
      dashArray = NULL,
      popup = paste(
        "<b>DFO subarea ID: </b>", coordinates_map$DFO_id,
        "<br><b> Last PST test:</b>", coordinates_map$psp_date,
        "<br><b> Last AST test:</b>", coordinates_map$asp_date
      ))

dfo_map
