library(sf)
library(ggplot2)
library(mapview)

shapefile_path <- "DAMODAR_SHAPEFILE/mrb_rivnets_Q09_10.shp"
basin_shapefile_path <- "DAMODAR_SHAPEFILE/mrb_basins.shp"

damodar_river <- st_read(shapefile_path)
damodar_basin <- st_read(basin_shapefile_path)

ggplot() +
  geom_sf(data = damodar_basin, fill = "lightblue", color ="black", alpha = 0.5) +
  geom_sf(data = damodar_river, color = "blue", size = 1) +
  ggtitle("Damodar River and Basin") +
  theme_minimal()

# Create interactive map with satellite imagery
mapview(damodar_river, map.types = "Esri.WorldImagery")

