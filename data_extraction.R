library(terra)
library(sf)
library(luna)
library(rgee)

# Load shapefile
damodar_river <- vect("DAMODAR_SHAPEFILE/mrb_rivnets_Q09_10.shp")

# Extract coordinates along the river
damodar_points <- geom(damodar_river)  # Extract coordinates
head(damodar_points)

# Set up to fetch satellite imagery
# Example using Landsat imagery

# Specify bounding box for the river region
bbox <- st_bbox(damodar_river)  # Get bounding box of the river

# Define the time range
start_date <- "2020-01-01"
end_date <- "2020-12-31"
test_bbox <- c(xmin = -125, xmax = -66.5, ymin = 24, ymax = 49)

# Download Landsat imagery using getLandsat (with download set to TRUE)
landsat_images <- getLandsat(product = "Landsat_8_OLI_TIRS_C1", 
                             start_date = start_date, 
                             end_date = end_date, 
                             aoi = test_bbox, 
                             download = TRUE, 
                             path = "C:/Users/Sayan/Desktop/SANDMINING/LANDSAT_IMAGES/", 
                             username = "acidtutu", 
                             password = "Iamnumberfour4@")

# Inspect the returned Landsat images metadata
print(landsat_images)

# Visualize the satellite images (assuming the file paths are in landsat_images)
# Replace "path_to_image.tif" with the actual file paths from the landsat_images output
for (image_path in landsat_images$path) {
  landsat_raster <- rast(image_path)
  
  # Plot the satellite image
  plot(landsat_raster, main = paste("Landsat Image:", image_path))
  
  # Overlay the Damodar River on the satellite image
  plot(damodar_river, add = TRUE, col = "blue")
}


# Initialize Earth Engine API
ee_Initialize()

# Define the area of interest
aoi <- ee$Geometry$Rectangle(test_bbox)

# Define the time range
start_date <- '2020-01-01'
end_date <- '2020-01-31'

# Fetch Landsat 8 imagery
collection <- ee$ImageCollection('LANDSAT/LC08/C01/T1')$
  filterBounds(aoi)$
  filterDate(start_date, end_date)

# Print the number of images found
print(collection$size()$getInfo())