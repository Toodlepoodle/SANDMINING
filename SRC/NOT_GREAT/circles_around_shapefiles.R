# Load necessary libraries
library(sf)
library(ggplot2)
library(mapview)
library(dplyr)
library(httr)
library(jsonlite)

# Read shapefiles
shapefile_path <- "DAMODAR_SHAPEFILE/mrb_rivnets_Q09_10.shp"
basin_shapefile_path <- "DAMODAR_SHAPEFILE/mrb_basins.shp"

damodar_river <- st_read(shapefile_path)
damodar_basin <- st_read(basin_shapefile_path)

# Create points from the river line
damodar_points <- st_cast(damodar_river, "POINT")

# Create 1 km buffer around each point (1000 meters)
circles <- st_buffer(damodar_points, dist = 1000)

# Plotting the circles and the river
ggplot() +
  geom_sf(data = damodar_basin, fill = "lightblue", color ="black", alpha = 0.5) +
  geom_sf(data = damodar_river, color = "blue", size = 1) +
  geom_sf(data = circles, fill = NA, color = "red", size = 0.5, linetype = "dotted") +
  ggtitle("Damodar River with 1 Km Buffers") +
  theme_minimal()

# Create interactive map with satellite imagery
mapview(circles, map.types = "Esri.WorldImagery")


