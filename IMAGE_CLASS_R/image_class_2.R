setwd("C:/Users/Sayan/Desktop/SANDMINING/IMAGE_CLASS_R/")

library(imager)
library(xgboost)
library(randomForest)
library(caret)

# Function to load and preprocess images
preprocess_image <- function(image_path, size = 64) {
  img <- load.image(image_path)
  img_resized <- resize(img, size, size)
  as.numeric(img_resized)
}

# Function to load images from a directory
load_images_from_directory <- function(directory, size = 64) {
  files <- list.files(directory, full.names = TRUE, recursive = TRUE)
  labels <- gsub(".*/(YES_SANDMINING|NO_SANDMINING)/.*", "\\1", files)
  data <- lapply(files, preprocess_image, size = size)
  matrix(unlist(data), nrow = length(data), byrow = TRUE)
}

# Load training and test images
train_dir <- "TRAINING"
test_dir <- "TEST"

X_train <- load_images_from_directory(train_dir, size = 64)
X_test <- load_images_from_directory(test_dir, size = 64)

# Create labels
y_train <- ifelse(grepl("YES_SANDMINING", list.files(train_dir, full.names = TRUE, recursive = TRUE)), 1, 0)
y_test <- ifelse(grepl("YES_SANDMINING", list.files(test_dir, full.names = TRUE, recursive = TRUE)), 1, 0)

# Train Random Forest model
rf_model <- randomForest(X_train, as.factor(y_train), ntree = 100)

# Predict on test set
predictions <- predict(rf_model, X_test)

# Evaluate model performance
confusionMatrix(predictions, as.factor(y_test))




