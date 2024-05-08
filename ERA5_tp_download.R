# ========================================================================
# Download total precipitation (tp) data from ERA5 ncdf4 files

# - units in m 
#   (indicates the equivalent depth of the water accumulated for hour 
#    if it was spread over the area of a single 0.25o x 0.25o grid box)

# - code assumes precipitation is downloaded for accumulated hour of 6-7 am only
# - code downloads precipitation daily for date range of Jan 1, 2016 to Mar 6, 2024
#   (ONLY CHANGE CODE AT LINE 54 FOR DIFFERENT DATE RANGE)
# =========================================================================

# set working directory
# setwd("path")

library(raster)
library(dplyr)
library(tidyr)
library(stringi)
library(geosphere)
library(readxl)


#Bind coordinates
loc <- read_excel("centroid_coordinates.xlsx")

# Check if the conversion was successful
str(loc)

loc$lon <- as.numeric(loc$lon)
loc$lat <- as.numeric(loc$lat)
# Set the coordinates again
library(sp)
coordinates(loc) <- ~lon+lat

#----redo for tp

nc.bricky <- brick("totalprecipitation.nc", varname="tp")
nc.bricky<-raster::extract(nc.bricky,loc)
nc.df.3<-as.data.frame(nc.bricky)
nc.df.3<-cbind(loc$DFO_SUB_ID, nc.df.3)

# edit column names
for ( col in 1:ncol(nc.df.3)){
  colnames(nc.df.3)[col] <-  sub(".06.00.00", "", colnames(nc.df.3)[col])
}

for ( col in 1:ncol(nc.df.3)){
  colnames(nc.df.3)[col] <-  sub("X", "", colnames(nc.df.3)[col])
}


# put dates into one col
nc.df.3 <- pivot_longer(nc.df.3, cols = "2016.01.01":"2024.03.06", 
                        names_to = "Date", 
                        values_to = "tp")
summary(nc.df.3)
tp_loc <- nc.df.3 %>%
  rename(DFO_id = `loc$DFO_SUB_ID`, date = Date)



# Using base R to change the date format
tp_loc$date <- gsub("\\.", "-", tp_loc$date)  # Replace dots with dashes
tp_loc$date <- as.Date(tp_loc$date, format="%Y-%m-%d")  # Convert strings to Date objects


# save
write.csv(finalfinaltp, "D:/UBC/envr400/project/T_P/t2m_finalfinal.csv")
