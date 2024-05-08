# ========================================================================
# Download sea-surface temperature(sst) data from ERA5 ncdf4 files
# (https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels?tab=form)

# units in degrees Celsius

# assumes 
# - SST is downloaded ONLY at the hour of 06:00 (for each day)
# - sst values daily
# =========================================================================


library(raster)
library(readxl)
library(sp)

# set working directory
# setwd("path")

# read SST data
nc.brick <- brick("sst.nc", varname="sst", level=1)

# read centroids coordinates
loc <- sploc <- data.frame(read_excel("centroid_coordinates.xlsx"))
loc$lon <- as.numeric(loc$lon) # make sure the input is numeric
loc$lat <- as.numeric(loc$lat)

# transform to spatial data frame
coordinates(sploc) <- ~lon+lat

# FILL NA VALUES ------------------------------------------------------------

# define empty results data frame
res <- matrix(nrow = nrow(loc), ncol = length(names(nc.brick)))
colnames(res) <- substr(names(nc.brick), 2, 11) # select only the day and not the hour
rownames(res) <- loc$DFO_SUB_ID

for(i in 1:nrow(loc)){
  
  # extract raster value at location
  sst_i <- as.numeric(raster::extract(nc.brick, loc[i,c("lon","lat")], df = TRUE))[-1] # first entry is id
  
  # if raster value is NA: take nearest raster value with non-NA value
  if(is.na(sst_i[1])){
    
    # find idx of closest cell with available data
    r <- nc.brick[[1]] # take only first layer
    d <- data.frame( # create distance data frame of only the first layer
      dist = values(distanceFromPoints(r, loc[i,c("lon", "lat")])),
      val = values(r)
      )
    d <- d[order(d$dist),] # sort according to distance
    d <- d[complete.cases(d),] # delete NAs
    idx <- as.numeric(rownames(d[1,])) # get idx of closest distance
    
    # extract the cell value at idx
    sst_i <- as.numeric(raster::extract(nc.brick, idx, df = TRUE))[-1] # first entry is id
  }
  
  # add to the results data frame
  res[i,] <- sst_i
  
}

# save
res <- cbind(loc$DFO_SUB_ID, res)
colnames(res)[1] <- "DFO_SUB_ID"

write.csv(res, "SST.csv", row.names = FALSE)
