# download corresponding packages before loading them 
library(raster)
library(stringi)
library(geosphere)
library(dplyr)
library(tidyr)

# tripolar grid, change date below to suit range of data
years <- 2016:2024
months <- stri_pad_left(1:12, 2, 0) # trailing 0s

# load in location dataframe for which to extract the salinity, eg. centroids of the subregions
# or assign coordinates of interest to lat and lon
loc <- read.csv("C:/pathway/to/.csv")
loc <- data.frame(rbind(
  c("1", 48.29785900955495, -123.53198211293895),
  c("2", 49.060905905503304, -123.73782485376022),
  c("3", 48.887131782863634, -125.44062007908802),
  c("4", 50.90261659641116, -128.1068331304296)
))
colnames(loc) <- c("id", "lat", "lon") #id is dfo subarea id

# define results data frame
res <- matrix(nrow = nrow(loc), ncol = length(years)*length(months))
colnames(res) <- paste0(rep(years, each=length(months)), "-", rep(months, length(years)))
rownames(res) <- loc$id

# loop through all input data (file names are per year and month) 
col_idx <- 1 # initiate column index (first year and month)

for(year in years){ 
 for(month in months){
   
   file <- paste0("sosaline_control_monthly_highres_2D_", year, month, "_OPER_v0.1.nc")
   
   # Get lat, lon, salinity from the data
   lat <- raster(file, varname="nav_lat")
   lon <- raster(file, varname="nav_lon")
   sal <- raster(file, varname="sosaline")
  
   # combine to data frame
   globe <- data.frame(cbind(values(lon), values(lat)), values(sal))
   colnames(globe) <- c("lon", "lat", "sal")
   
   # loop through locations
   for(i in 1:nrow(loc)){
     cat("Processing year", year, ", month", month, ", location", i, "/", nrow(loc), "\n")
     
     # calculate distance from location for each point on the global data
     dists <- geosphere::distHaversine(as.numeric(loc[i, c("lon", "lat")]),
                                       globe[,c("lon", "lat")])
     dists <- distm(as.numeric(loc[i, c("lon", "lat")]), globe[,c("lon", "lat")], fun = distHaversine)
     
     # find indices of the 10 closest points on the globe, use a higher number if operations gets stuck
     idx <- which(rank(dists) < 10) 
     
     # extract data frame of neighbors, ordered by distance
     neighbors <- globe[idx,][order(rank(dists)[idx]),] # ordered: 1st row is closest
     
     # loop through neighbors and select the closest with available data
     n <- 1
     while(is.na(neighbors$sal[n])){
       n <- n+1
     }
     sal <- neighbors$sal[n] # get salinity value for neighbor with available data
     
     # add this salinity value to the results dataframe
     res[i, col_idx] <- sal
   }
   
   # move to the next column (month)
   col_idx <- col_idx + 1
 }
  
}

# assign first column as dfo id
colnames(res)[c(1)] <- "DFO_id"

# put dates into one column, change 98 to the number of total rows
res <- pivot_longer(res, cols = c(2:98), 
                    names_to = "date", 
                    values_to = "salinity")

# change format of date to be consistent
res$date <- chartr("_", "-", res$date)

# export as csv
write.csv(salinity, "C:/Users/Music/wind/update_salinity.csv", row.names=FALSE)
