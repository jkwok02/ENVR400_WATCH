# ENVR400_WATCH
This code repository was used in the data downloading, tidying, and model building for the research project by students (Jasmine Kwok, Shirley Zhou, Vanessa Xiong and Wenwen Wang) in UBC's Research in Environmental Science course (ENVR 400 2024W2) in partnership with the First Nations Healthy Authority. The research report is entitled "Predicting Dangerous Biotoxin Levels along the Coast of British Columbia: Achieving Food Sovereignty and Safety for Coastal Indigenous Communities" and can be found on UBC's cIRcle repository of research materials.

## PREPROCESS MODEL DATA
Use code in the following files to tidy data for use in the model
- ORAS5_Download ... salinity
- CMS_nutrient_download ... nitrate and phosphate at various constant depths


## REANALYSIS DATA FOLDER CONTAINS DATA USED TO RUN THE MODEL
- sea-surface temperature (sst)
- air temperature at 2m (t2m)
- total precipitation (tp)
- nutrient (phosphate and nitrate at various depths)
- salinity
- wind speed

## GIS 
- use **dfo_centroids** to compute centroids of each DFO subarea
- **map_dfo_subareas_label** to produce a DFO subarea map with centroids that show DFO subarea ID and latest testing date as shown here:
https://github.com/Shirleyzhou0503/ENVR400_WATCH/assets/99441762/43c0fd44-fc73-4def-9617-31b87147c7dd
