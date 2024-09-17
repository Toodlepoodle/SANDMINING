library(sf)
library(ggplot2)
library(mapview)
library(raster)

shapefile_path <- "DAMODAR_SHAPEFILE/mrb_rivnets_Q09_10.shp"
damodar_river <- st_read(shapefile_path)

# Generate points along the river bank
river_bank_points <- st_sample(damodar_river, size = 100, type = "regular")  # 100 points along the river
river_bank_points <- st_as_sf(river_bank_points)

# Function to extract satellite image around a given point
extract_image_for_point <- function(point, buffer_size = 100) {
  buffered_point <- st_buffer(point, dist = buffer_size)  # Create a buffer around the point
  cropped_raster <- crop(satellite_raster, buffered_point)  # Crop the satellite image to the buffer
  img <- as.array(cropped_raster)
  return(img)
}

# Resize and preprocess image
preprocess_image_for_point <- function(img, size = 64) {
  img_resized <- resize(as.cimg(img), size, size)
  as.numeric(img_resized)  # Convert to numeric vector for the model
}

# Apply the Random Forest model to predict sand mining probability
predict_sand_mining <- function(point) {
  img <- extract_image_for_point(point)  # Extract image around point
  img_preprocessed <- preprocess_image_for_point(img)
   # Predict using the random forest model
  pred <- predict(rf_model, matrix(img_preprocessed, nrow = 1), type = "prob")[, 2]  # Probability for class 1 (YES_SANDMINING)
  return(pred)  # Return the probability
}

# Apply the prediction to each river bank point
river_bank_points$sand_mining_prob <- sapply(1:nrow(river_bank_points), function(i) {
  predict_sand_mining(river_bank_points[i, ])
})
