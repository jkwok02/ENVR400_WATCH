library(dplyr)
library(tidyverse)
salinity <- read.csv("salinity_daily.csv") #610 subareas
salinity=salinity[,-1]

salinity <- salinity |> 
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(Salinity_10days_before = lag(salinity, 10))|>
  mutate(date=as.Date(date))|>
  filter(date>="2023-03-01"&date<="2023-03-31")


tp <- read.csv("tp.csv") #740 subareas
tp=tp[,-1]
tp<- tp|>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(date=as.Date(date))|>
  mutate(TP_10days_before = lag(tp, 10))|>
  filter(date>="2023-03-01"&date<="2023-03-31")


t2m <- read.csv("t2m.csv")  #740 subareas
t2m=t2m[,-1]
t2m<-t2m|>
  mutate(t2m=t2m- 273.15)|>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(T2M_10days_before = lag(t2m, 10))|>
  mutate(date=as.Date(date))|>
  filter(date>="2023-03-01"&date<="2023-03-31")


windspeed <- read.csv("windspeed.csv") #610 subareas
windspeed<- windspeed|>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(Speed_10days_before = lag(speed, 10))|>
  mutate(date=as.Date(date))|>
  filter(date>="2023-03-01"&date<="2023-03-31")


sst <- read.csv("sst.csv") #740 subareas
sst=sst[,-1]
sst<-sst|>
  mutate(sst=sst- 273.15)|>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(SST_10days_before = lag(sst, 10))|>
  mutate(date=as.Date(date))|>
  filter(date>="2023-03-01"&date<="2023-03-31")

nutrient_0_5 <- read.csv("whole_nutrient_0_5.csv") #740 subareas
nutrient_0_5<-nutrient_0_5|>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(PO4_0_5_10days_before = lag(po4, 10))|>
  mutate(NO3_0_5_10days_before = lag(no3, 10))|>
  mutate(date=as.Date(date))|>
  select(-c(depth, po4, no3))|>
  filter(date>="2023-03-01"&date<="2023-03-31")

nutrient_20 <- read.csv("whole_nutrient_20.csv") #740 subareas
nutrient_20<-nutrient_20|>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(PO4_20_10days_before = lag(po4, 10))|>
  mutate(NO3_20_10days_before = lag(no3, 10))|>
  mutate(date=as.Date(date))|>
  select(-c(depth, po4, no3))|>
  filter(date>="2023-03-01"&date<="2023-03-31")

nutrient_30 <- read.csv("whole_nutrient_30.csv") #740 subareas
nutrient_30<-nutrient_30|>
  group_by(DFO_id)|>
  arrange(date) |>
  mutate(PO4_30_10days_before = lag(po4, 10))|>
  mutate(NO3_30_10days_before = lag(no3, 10))|>
  mutate(date=as.Date(date))|>
  select(-c(depth, po4, no3))|>
  filter(date>="2023-03-01"&date<="2023-03-31")
 
prediction_set<- left_join(salinity, sst,by = c("DFO_id", "date")) 
prediction_set<- left_join(prediction_set, t2m, by = c("DFO_id", "date"))
prediction_set<- left_join(prediction_set, tp, by = c("DFO_id", "date"))
prediction_set<- left_join(prediction_set, windspeed, by = c("DFO_id", "date"))
prediction_set<- left_join(prediction_set, nutrient_0_5, by = c("DFO_id", "date"))
prediction_set<- left_join(prediction_set, nutrient_20, by = c("DFO_id", "date"))
prediction_set<- left_join(prediction_set, nutrient_30, by = c("DFO_id", "date"))


prediction_set2 <- prediction_set %>%
  mutate(
    date_10days_before = date - days(10),
    DOY_10days_before = yday(date_10days_before) 
  ) %>%
  select(-date_10days_before) %>%
  select(-c(speed, salinity, sst, t2m,tp))%>%
  ungroup()

predict_model<- predict(rf_full, newdata = prediction_set2, type = "prob")
predict_result<- predict_model[, 2]  

prediction_set2 <- prediction_set2 |>
  mutate(Predicted_Result = predict_result)


prediction_set3 <- prediction_set2 |>
  filter(date=="2023-03-31")

readr::write_csv(prediction_set3, "prediction_set.csv")
