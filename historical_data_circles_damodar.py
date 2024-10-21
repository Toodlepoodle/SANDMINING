import os
import geopandas as gpd
import matplotlib.pyplot as plt
from shapely.geometry import Point
import folium

print("Current Working Directory:", os.getcwd())

os.chdir("C:/Users/Sayan/Desktop/SANDMINING")

# Load shapefiles
shapefile_path = "DAMODAR_SHAPEFILE/mrb_rivnets_Q09_10.shp"
basin_shapefile_path = "DAMODAR_SHAPEFILE/mrb_basins.shp"

# Reading river and basin shapefiles
damodar_river = gpd.read_file(shapefile_path)
damodar_basin = gpd.read_file(basin_shapefile_path)

# Create points from the river geometry
damodar_points = damodar_river.geometry.apply(lambda x: [Point(pt) for pt in x.coords])

# Flatten the points list
damodar_points = gpd.GeoDataFrame(geometry=[pt for sublist in damodar_points for pt in sublist], crs=damodar_river.crs)

# Create 1 km (1000 meters) buffer around each point
circles = damodar_points.buffer(1000)
circles_gdf = gpd.GeoDataFrame(geometry=circles, crs=damodar_river.crs)
