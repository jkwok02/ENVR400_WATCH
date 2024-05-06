# ========================================================================
# Download wind speed data from ERA5 ncdf4 files
# (https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels?tab=form)

# units in m/s
# surface (10m) wind speed with a u-component ("u10") and v-component ("v10")

# assumes 
# - date range of Jan 1, 2016 to Feb 23, 2024
#   (ONLY change lines 45 and 69 for different date range)
# - wind speed is downloaded ONLY at the hour of 06:00 (for each day)
#   (lines 41 and 64 need to be modified if doing a daily average)
# - wind direction is not considered
# =========================================================================

# set workign directory
# setwd("path")

library(raster)
library(dplyr)
library(tidyr)
library(readxl)

## V-COMPONENT OF WINDSPEED -----------------------------------------------
#select data
nc.brick <- brick("wind.nc", varname="v10")

#Bind coordinates
loc <- read_excel("centroid_coordinates.xlsx")
loc$lon <- as.numeric(loc$lon)
loc$lat <- as.numeric(loc$lat)
coordinates(loc) <- ~lon+lat

#extract and make df
nc.brick<-raster::extract(nc.brick,loc)
nc.df.2<-as.data.frame(nc.brick)
nc.df.2<-cbind(id=loc$id, nc.df.2)

# edit column names
for ( col in 1:ncol(nc.df.2)){
  colnames(nc.df.2)[col] <-  sub(".06.00.00", "", colnames(nc.df.2)[col])
}

for ( col in 1:ncol(nc.df.2)){
  colnames(nc.df.2)[col] <-  sub("X", "", colnames(nc.df.2)[col])
}

# put dates into one col
nc.df.2 <- pivot_longer(nc.df.2, cols = "2016.01.01":"2024.02.23", 
                              names_to = "Date", 
                              values_to = "v10")


## U-COMPONENT OF WIND SPEED ---------------------------------------------
#----redo for u10

# select and extract and make data frame
nc.bricky <- brick("C:/Users/Music/wind/wind.nc", varname="u10")
nc.bricky<-raster::extract(nc.bricky,loc)
nc.df.3<-as.data.frame(nc.bricky)
nc.df.3<-cbind(id=loc$id, nc.df.3)

# edit column names
for ( col in 1:ncol(nc.df.3)){
  colnames(nc.df.3)[col] <-  sub(".06.00.00", "", colnames(nc.df.3)[col])
}

for ( col in 1:ncol(nc.df.3)){
  colnames(nc.df.3)[col] <-  sub("X", "", colnames(nc.df.3)[col])
}


# put dates into one col
nc.df.3 <- pivot_longer(nc.df.3, cols = "2016.01.01":"2024.02.23", 
                        names_to = "Date", 
                        values_to = "u10")

## BIND u10 + v10 ----------------------------------------------------------
speed <- bind_cols(nc.df.2, nc.df.3)

#edit col
speed <- subset(speed, select=-c(4, 5))

#calculate magnitude of speed from vectors
speed <- mutate(speed, sqrt((v10^2)+(u10^2)))

#fix column names
colnames(speed)[c(5)] <- "speed"
colnames(speed)[c(1)] <- "id"
colnames(speed)[c(2)] <- "date"

write.csv(speed, "C:/Users/Music/wind/windspeed.csv", row.names=FALSE)
