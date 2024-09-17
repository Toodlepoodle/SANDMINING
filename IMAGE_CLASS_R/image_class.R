setwd("/home/sayan/SANDMINING/IMAGE_CLASS_R/")
library(keras)
library(abind)

train_dir <- "/home/sayan/SANDMINING/IMAGE_CLASS_R/TRAINING"
test_dir <- "/home/sayan/SANDMINING/IMAGE_CLASS_R/TEST"

# Create image data generators
train_datagen <- image_data_generator(
  rescale = 1/255,  # Normalize pixel values
  shear_range = 0.2,
  zoom_range = 0.2,
  horizontal_flip = TRUE
)

test_datagen <- image_data_generator(
  rescale = 1/255  # Normalize pixel values
)

# Create data generators
train_generator <- flow_images_from_directory(
  train_dir,
  generator = train_datagen,
  target_size = c(128, 128),
  batch_size = 32,
  class_mode = "binary",  # Binary classification
  shuffle = TRUE
)

test_generator <- flow_images_from_directory(
  test_dir,
  generator = test_datagen,
  target_size = c(128, 128),
  batch_size = 32,
  class_mode = "binary",  # Binary classification
  shuffle = FALSE
)

# Function to extract all images and labels from a generator
extract_images_labels <- function(generator, num_batches) {
  images <- NULL
  labels <- NULL
  
  for (i in 1:num_batches) {
    # Simulating the generator output
    batch <- list(array(runif(32 * 128 * 128 * 3), dim = c(32, 128, 128, 3)), 
                  sample(0:1, 32, replace = TRUE))
    
    images <- if (is.null(images)) {
      batch[[1]]
    } else {
      abind(images, batch[[1]], along = 1)
    }
    labels <- c(labels, batch[[2]])
  }
  
  return(list(images = images, labels = labels))
}


# Calculate the number of batches
num_train_batches <- ceiling(train_generator$n / train_generator$batch_size)
num_test_batches <- ceiling(test_generator$n / test_generator$batch_size)

# Extract training and testing images and labels
train_data <- extract_images_labels(train_generator, num_train_batches)
test_data <- extract_images_labels(test_generator, num_test_batches)

train_images <- train_data$images
train_labels <- train_data$labels
test_images <- test_data$images
test_labels <- test_data$labels

train_images <- train_images / 255
test_images <- test_images / 255

model <- keras_model_sequential()
model %>%
  layer_flatten(input_shape = c(28, 28)) %>%
  layer_dense(units = 128, activation = 'relu') %>%
  layer_dense(units = 10, activation = 'softmax')
