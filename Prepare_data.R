pacman::p_load(dplyr,tidyverse, stringr,tidyr,lubridate,readxl)


load("all_biotoxin_results_2016-2024.rdata")
biotoxin_df <- biotoxin_data |>
  select(-subarea_id_for_excel, -pdf_source, -subarea_name) |>
  filter(test == "ASP" | test == "PSP")

biotoxin_df$subarea_id <- str_extract(biotoxin_df$subarea_id, "\\d+-\\d+")

centroid_coordinates <- read_excel("centroid_coordinates.xlsx")
centroid_coordinates$LABEL <- sapply(str_split(centroid_coordinates$LABEL, "-"), function(x) {
  padded_parts <- str_pad(x, width = 2, side = "left", pad = "0")
  paste(padded_parts[1], padded_parts[2], sep = "-")
})

centroid_coordinates <- centroid_coordinates |>
  mutate(LABEL = str_replace(LABEL, "-NA", "-00")) |>
  rename(Subarea_id=LABEL,DFO_id=DFO_SUB_ID)

biotoxin_df2 <- left_join(biotoxin_df, centroid_coordinates, by = c("subarea_id" = "Subarea_id"))

asp_df <- biotoxin_df2 %>%
  filter(test == "ASP") %>%
  mutate(reg=ifelse(result>=20, 1, 0))

asp_model<-data.frame(subarea_id=asp_df$subarea_id, Above_Reg=asp_df$reg, 
                      date=asp_df$harvest_date, species=asp_df$species,DFO_id=asp_df$DFO_id, longitude=asp_df$lon, latitude=asp_df$lat)

psp_df <- biotoxin_df2%>%
  filter(test == "PSP") %>%
  mutate(reg=ifelse(result>=80, 1, 0))

psp_model<-data.frame(subarea_id=psp_df$subarea_id, Above_Reg=psp_df$reg, 
                      date=psp_df$harvest_date, species=psp_df$species,DFO_id=psp_df$DFO_id, longitude=psp_df$lon, latitude=psp_df$lat)

#salinity data------------------
# salinity <- read_csv("salinity.csv")
# salinity=salinity[,-1]

# salinity_daily <- salinity |>
#   mutate(date=as.Date(paste0(date, "-01")))|>
#   mutate(last_day = as.Date(paste0(format(date, "%Y-%m-"), days_in_month(date)))) |>
#   rowwise() |>
#   do({
#     data.frame(DFO_id = .$DFO_id,
#                date = seq(from = .$date, to = .$last_day, by = "day"),
#                salinity = .$salinity)
#   }) |>
#   ungroup()

salinity_daily<- read.csv("salinity_daily.csv")
salinity_daily=salinity_daily[,-1]

salinity_asp <- salinity_daily |>
  filter(DFO_id %in% asp_model$DFO_id) |>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(Salinity_10days_before = lag(salinity, 10))|>
  mutate(date=as.Date(date))
  
salinity_psp <- salinity_daily |>
  filter(DFO_id %in% psp_model$DFO_id)|>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(Salinity_10days_before = lag(salinity, 10))|>
  mutate(date=as.Date(date))

variable1_asp <- left_join(asp_model, salinity_asp , by = c("DFO_id", "date"))
variable1_psp <- left_join(psp_model, salinity_psp , by = c("DFO_id", "date"))

#tp ------------------
tp <- read_csv("tp.csv")
tp=tp[,-1]
tp<- tp|>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(TP_10days_before = lag(tp, 10))|>
  mutate(date=as.Date(date))

variable2_asp <- left_join(variable1_asp, tp, by = c("DFO_id", "date"))
variable2_psp <- left_join(variable1_psp, tp, by = c("DFO_id", "date"))

#air temperature--------------
t2m <- read_csv("t2m.csv")
t2m=t2m[,-1]
t2m<-t2m|>
  mutate(t2m=t2m- 273.15)|>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(T2M_10days_before = lag(t2m, 10))|>
  mutate(date=as.Date(date))

variable3_asp  <- left_join(variable2_asp , t2m, by = c("DFO_id", "date"))
variable3_psp  <- left_join(variable2_psp , t2m, by = c("DFO_id", "date"))

#wind--------------
windspeed <- read_csv("windspeed.csv")
windspeed<- windspeed|>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(Speed_10days_before = lag(speed, 10))|>
  mutate(date=as.Date(date))

variable4_asp  <- left_join(variable3_asp , windspeed, by = c("DFO_id", "date"))
variable4_psp  <- left_join(variable3_psp , windspeed, by = c("DFO_id", "date"))

#sst data-------------------------
sst <- read_csv("sst.csv")
sst=sst[,-1]
sst<-sst|>
  mutate(sst=sst- 273.15)|>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(SST_10days_before = lag(sst, 10))|>
  mutate(date=as.Date(date))

variable5_asp  <- left_join(variable4_asp , sst, by = c("DFO_id", "date"))
variable5_psp  <- left_join(variable4_psp , sst, by = c("DFO_id", "date"))


#nutrient data
nutrient_0_5 <- read_csv("nutrient_0.5.csv")
nutrient_0_5<-nutrient_0_5|>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(PO4_0_5_10days_before = lag(po4, 10))|>
  mutate(NO3_0_5_10days_before = lag(no3, 10))|>
  mutate(date=as.Date(date))|>
  select(-depth)

nutrient_20 <- read_csv("nutrient_20.csv")
nutrient_20<-nutrient_20|>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(PO4_20_10days_before = lag(po4, 10))|>
  mutate(NO3_20_10days_before = lag(no3, 10))|>
  mutate(date=as.Date(date))|>
  select(-depth)

nutrient_30 <- read_csv("nutrient_30.csv")
nutrient_30<-nutrient_30|>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(PO4_30_10days_before = lag(po4, 10))|>
  mutate(NO3_30_10days_before = lag(no3, 10))|>
  mutate(date=as.Date(date))|>
  select(-depth)

variable6_asp  <- variable5_asp  |>
  left_join(nutrient_0_5, by = c("DFO_id", "date")) |>
  left_join(nutrient_20, by = c("DFO_id", "date")) |>
  left_join(nutrient_30, by = c("DFO_id", "date"))

variable6_psp  <- variable5_psp  |>
  left_join(nutrient_0_5, by = c("DFO_id", "date")) |>
  left_join(nutrient_20, by = c("DFO_id", "date")) |>
  left_join(nutrient_30, by = c("DFO_id", "date"))


#day of year----------
variable6_asp <- variable6_asp %>%
  mutate(
    date_10days_before = date - days(10), # Subtracting 10 days directly from the date
    DOY_10days_before = yday(date_10days_before) # Calculating DOY for the date 10 days before
  ) %>%
  select(-date_10days_before) 

variable6_psp <- variable6_psp %>%
  mutate(
    date_10days_before = date - days(10), # Subtracting 10 days directly from the date
    DOY_10days_before = yday(date_10days_before) # Calculating DOY for the date 10 days before
  ) %>%
  select(-date_10days_before) 

#check NAs
#rows_with_na <- randomf %>% filter(if_any(everything(), is.na))