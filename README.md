# ENVR400_WATCH
This code repository was used in the data downloading, tidying, and model building for the research project by students (Jasmine Kwok, Shirley Zhou, Vanessa Xiong and Wenwen Wang) in UBC's Research in Environmental Science course (ENVR 400 2024W2) in partnership with the First Nations Healthy Authority. The research report is entitled "Predicting Dangerous Biotoxin Levels along the Coast of British Columbia: Achieving Food Sovereignty and Safety for Coastal Indigenous Communities" and can be found on UBC's cIRcle repository of research materials.

## Code to preprocess model data after download
Use code in the following files to tidy data for use in the model
- ORAS5_Download ... salinity
- CMS_nutrient_download ... nitrate and phosphate at various constant depths
- ERA5_sst_download ... Sea-surface temperature
- ERA5_tp_download ... Total precipitation
- ERA5_wind_download ... Wind speed

## Data used to run the model
- Read Me file for the following data available at:
  https://drive.google.com/file/d/1FuOWLCernbXmF0BFKj0oDpX0Jolid0Mu/view?usp=sharing
  
- Input Data for the full Random Forest AST and PST models available at:
  https://drive.google.com/drive/folders/1C8_5hLy07HLbb5SbIRdVBmJtP83nNHML?usp=sharing
- Centroids available at:
  https://drive.google.com/drive/folders/1I4dIQ_fQHJqYhPb6n1FaDa4PX8qZJjKg?usp=sharing
- Individual files for each predictor variable's tidied data available at:
  https://drive.google.com/drive/folders/167ejhUG79VrJ703xWs2LNgqh_a54-1hI?usp=sharing
- Lighthouse data (only used to compare/affirm use of climate reanalysis data) available at:
  https://drive.google.com/drive/folders/161jRYao0kUcOHZnv2jl-QajI-8hW63Wk?usp=sharing

## GIS Code
- use **dfo_centroids** to compute centroids of each DFO subarea
- **map_dfo_subareas_label** to produce a DFO subarea map with centroids that show DFO subarea ID and latest testing date as shown here:
  https://github.com/Shirleyzhou0503/ENVR400_WATCH/assets/99441762/43c0fd44-fc73-4def-9617-31b87147c7dd
