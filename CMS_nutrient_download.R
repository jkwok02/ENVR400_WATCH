# ========================================================================
# Download nutrient (PO4, NO3) data from Copernicus Marine Service ncdf4 files
# Forecast (2023-present at https://data.marine.copernicus.eu/product/GLOBAL_ANALYSISFORECAST_BGC_001_028/description)
# =========================================================================

# PO4 and NO3 units are mmol/m3

# Copernicus Marine Service allows PO4 and NO3 data to download simultaneously
# Code assumes 
# - PO4 and NO3 data is downloaded in same file "nutrient.nc"
#   (Repeat process for PO4 data/as necessary (lines 89-146))
# - nutrient data is downloaded at a constant depth


library(raster)
library(readxl)
library(sp)
library(dplyr)
library(tidyr)

# set working directory
# setwd("path")

## DATA DOWNLOAD ---------
# read centroids coordinates
# (compute centroids from dfo_centroids.R file)

loc <- data.frame(read_excel("centroid_coordinates.xlsx"))
loc$lon <- as.numeric(loc$lon) # make sure the input is numeric
loc$lat <- as.numeric(loc$lat)
loc <- loc %>% rename(DFO_id = DFO_SUB_ID) # rename col

#select ncdf no3 data
nc.big.brick <- brick("nutrientfile.nc", varname="no3", level=1)

#select ncdf po4 data
# nc.big.brick <- brick("phosphate.nc", varname="po4", level=1)

# check dimensions of data: col(longitude values)  rows(latitude values)  layers(days)
# dim(nc.big.brick)


## FILL NO3 NA VALUES -----------
# define empty results data frame
res <- matrix(nrow = nrow(loc), ncol = length(names(nc.big.brick)))
colnames(res) <- substr(names(nc.big.brick), 2, 11) # select only the day and not the hour
rownames(res) <- loc$DFO_id

  # loop through subareas
  for(i in 1:nrow(loc)){
    
    # extract raster value at location
    no3_i <- as.numeric(raster::extract(nc.big.brick, loc[i,c("lon","lat")], df = TRUE))[-1] # first entry is id
    
    # if raster value is NA: take nearest raster value with non-NA value
    if(is.na(no3_i[1])){
      
      # find idx of closest cell with available data
      r <- nc.big.brick[[1]] # take only first layer
      d <- data.frame( # create distance data frame of only the first layer
        dist = values(distanceFromPoints(r, loc[i,c("lon", "lat")])),
        val = values(r)
      )
      d <- d[order(d$dist),] # sort according to distance
      d <- d[complete.cases(d),] # delete NAs
      idx <- as.numeric(rownames(d[1,])) # get idx of closest distance
      
      # extract the cell value at idx
      no3_i <- as.numeric(raster::extract(nc.big.brick, idx, df = TRUE))[-1] # first entry is id
    }
    
    # add to the results data frame
    res[i,] <- no3_i
    
  }
  
  # save
  res <- cbind(loc$DFO_id, res)
  colnames(res)[1] <- "DFO_id"
  nc.df <- as.data.frame(res)
  
  ## TIDY DATA -----------
  # put dates into one col
  nc.df <- pivot_longer(nc.df, cols = '2023.01.01':'2024.03.09', 
                        names_to = "date", 
                        values_to = "no3")
  
  # Convert the Date column to a Date type
  nc.df <- mutate(nc.df, date = as.Date(date, format = "%Y.%m.%d"))
  
  # add constant depth measurement
  nc.df$depth <- 30

## REPEAT FOR PO4 DATA

#select ncdf po4 data
nc.big.brick2 <- brick("nutrientfile.nc", varname="po4", level=1)

# check dimensions of data: col(lon)  rows(lat)  layers(days)
# dim(nc.big.brick)

## FILL PO4 NA VALUES -----------
# define empty results data frame
res2 <- matrix(nrow = nrow(loc), ncol = length(names(nc.big.brick2)))
colnames(res2) <- substr(names(nc.big.brick2), 2, 11) # select only the day and not the hour
rownames(res2) <- loc$DFO_id

# loop through subareas
for(i in 1:nrow(loc)){
  
  # extract raster value at location
  po4_i <- as.numeric(raster::extract(nc.big.brick2, loc[i,c("lon","lat")], df = TRUE))[-1] # first entry is id
  
  # if raster value is NA: take nearest raster value with non-NA value
  if(is.na(po4_i[1])){
    
    # find idx of closest cell with available data
    r <- nc.big.brick2[[1]] # take only first layer
    d <- data.frame( # create distance data frame of only the first layer
      dist = values(distanceFromPoints(r, loc[i,c("lon", "lat")])),
      val = values(r)
    )
    d <- d[order(d$dist),] # sort according to distance
    d <- d[complete.cases(d),] # delete NAs
    idx <- as.numeric(rownames(d[1,])) # get idx of closest distance
    
    # extract the cell value at idx
    po4_i <- as.numeric(raster::extract(nc.big.brick2, idx, df = TRUE))[-1] # first entry is id
  }
  
  # add to the results data frame
  res2[i,] <- po4_i
  
}

# save
res2 <- cbind(loc$DFO_id, res2)
colnames(res2)[1] <- "DFO_id"
nc.df2 <- as.data.frame(res2)

## TIDY DATA -----------
# put dates into one col
nc.df2 <- pivot_longer(nc.df2, cols = '2023.01.01':'2024.03.09', 
                      names_to = "date", 
                      values_to = "po4")

# Convert the Date column to a Date type
nc.df2 <- mutate(nc.df2, date = as.Date(date, format = "%Y.%m.%d"))

# add constant depth measurement
nc.df2$depth <- 30

# JOINING DATA TOGETHER ---------------
## combine PO4, NO3, dfo_id dataframes

nutrient_df <- full_join(nc.df,
                         nc.df2,
                         by = c("DFO_id" = "DFO_id",
                                "date" = "date",
                                "depth" = "depth"))

write.csv(nutrient_df, "nutrient.csv", row.names=FALSE)
