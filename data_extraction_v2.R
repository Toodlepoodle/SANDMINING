library(raster)
library(terra)
library(sf)
library(sp)
library(ggplot2)
library(rgee)
library(dplyr)
library(reticulate)

# Authenticate with Google Earth Engine
ee_Initialize()

  # Define your polygon coordinates (e.g., a point in New Delhi, India)
coords <- data.frame(
  lon = 77.1025,
  lat = 28.6139
)

# Convert to an sf object
point_sf <- st_as_sf(coords, coords = c("lon", "lat"), crs = 4326)

# Create a Google Earth Engine geometry from the sf object
point_geom <- ee$Geometry$Point(coords$lon, coords$lat)

# Define Landsat 8 collection and filter by date and location
landsat_collection <- ee$ImageCollection("LANDSAT/LC08/C01/T1_TOA") %>%
  ee$ImageCollection$filterBounds(point_geom) %>%
  ee$ImageCollection$sort("system:time_start") %>%
  ee$ImageCollection$first()

# Select bands of interest (e.g., B2, B3, B4)
bands <- c("B2", "B3", "B4")
landsat_image <- landsat_collection$select(bands)

# Extract pixel values
pixel_values <- ee$Image$sampleRegions(
  collection = ee$FeatureCollection(point_geom),
  scale = 30
)

# Get values
values_list <- ee_get_values(pixel_values)

# Print values
print(values_list)