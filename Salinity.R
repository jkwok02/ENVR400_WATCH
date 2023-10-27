pacman::p_load(tidyverse, reshape, data.table, lubridate, dplyr)

G_data<-read.csv("LightStation_SST+Salinity_DATA_Active_Sites/DATA_-_Active_Sites/McInnes_Island/McInnes_Island_-_Average_Monthly_Sea_Surface_Salinities_1954-2022.csv")

colnames(G_data)<- G_data[1,]

G_data<- G_data[-1,]|>
  mutate(across(2:13, ~ ifelse(. == 999.99, NA, as.numeric(.))))|>
  filter(YEAR>1992)

G_30yr_Mean <- data.frame(colMeans(G_data[,2:13], na.rm = TRUE))
colnames(G_30yr_Mean)<- "Mean_Salinity"

G_data_2016<- G_data[24:30,]|>
  pivot_longer(cols = 2:13, names_to = "Month", values_to = "Salinity")

#Repeating the 30yr mean data for each month for each year in our analysis
G_2016_30mean<- rep(G_30yr_Mean$Mean_Salinity, times = (nrow(G_data_2016)/12))

#Binding the repeated 30yr mean salinity data and current analysis salinity data
G_data_final<-cbind(G_data_2016,G_2016_30mean)%>% mutate(Anomaly = Salinity-G_2016_30mean) 

Month_vec<-c("01","02","03","04","05","06","07","08","09","10","11","12")
Month_num <-rep(Month_vec, times = nrow(G_data_final)/12)

G_data_final2<-G_data_final|>
  mutate(G_data_final, Month_num=Month_num, .after = "Month") |>
  mutate('Date_for_plot'= make_date(year = YEAR, month = Month_num))

G_data_final2$Ystart=0
G_data_final2$Col=ifelse(G_data_final2$Anomaly>=0,"blue","red")

ggplot(data = G_data_final2, mapping = aes(Date_for_plot,Anomaly))+
  geom_segment(data = G_data_final2, 
               mapping =aes(Date_for_plot=Date_for_plot,
                            y=Ystart,
                            xend=Date_for_plot,
                            yend=Anomaly,
                            color=Col),
               linewidth = 1.5) + 
  xlab("Time") + 
  ylab ("Salinity Anomaly") + 
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.background = element_blank(), 
        axis.line = element_line(colour = "black")) +
  scale_y_continuous(expand = c(0,0)) + 
  theme(axis.title = element_text(size = 8.5)) +
  theme(legend.position="none")

