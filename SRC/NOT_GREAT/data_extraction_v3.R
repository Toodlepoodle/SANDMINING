library(sen2r)
library(shinyFiles)
library(shinydashboard)
library(shinyjs)
library(shinyWidgets)

  
sen2r::sen2r(
  gui = TRUE  # This opens a GUI to input credentials and preferences.
)

# Example coordinates (longitude, latitude) in India
lon <- 85.3240  # Longitude
lat <- 23.8250  # Latitude
aoi <- sf::st_as_sf(data.frame(
  id = 1,
  geometry = sf::st_sfc(sf::st_point(c(lon, lat)), crs = 4326)  # Define CRS as WGS84
))

# Define the time range (e.g., the last year)
time_range <- c("2023-01-01", "2023-01-02")

# Set the output folder where data will be downloaded
out_folder <- "SENTINEL_DATA"

# Download Sentinel-2 data
sen2r(
  gui = FALSE,  # To use the script-based approach
  extent = aoi,  # Area of interest (single point in this case)
  timewindow = time_range,
  list_prods = c("BOA"),  # Surface reflectance product (Bottom of Atmosphere)
  res_s2 = "10m",  # Spatial resolution
  sel_sensor = c("s2a", "s2b"),  # Sentinel-2A and 2B
  online = TRUE,  # Accessing online API
  order_lta = TRUE,  # Allow ordering data not available in LTA
  path_l1c = out_folder,
  path_l2a = out_folder,
  path_out = out_folder,
  processing_order = "by_date"
)
