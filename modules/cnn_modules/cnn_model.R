library(torch)
source("config.R")

cnn_network <- nn_module(
  "CNNNetwork",
  initialize = function(input_height = MODEL_CONFIG$img_height, 
                       input_width = MODEL_CONFIG$img_width) {
    self$conv1 <- nn_sequential(
      nn_conv2d(
        in_channels = 1,
        out_channels = 16,
        kernel_size = 3,
        stride = 1,
        padding = 2
      ),
      nn_relu(),
      nn_max_pool2d(kernel_size = 2)
    )
    
    self$conv2 <- nn_sequential(
      nn_conv2d(
        in_channels = 16,
        out_channels = 32,
        kernel_size = 3,
        stride = 1,
        padding = 2
      ),
      nn_relu(),
      nn_max_pool2d(kernel_size = 2)
    )
    
    self$conv3 <- nn_sequential(
      nn_conv2d(
        in_channels = 32,
        out_channels = 64,
        kernel_size = 3,
        stride = 1,
        padding = 2
      ),
      nn_relu(),
      nn_max_pool2d(kernel_size = 2)
    )
    
    self$conv4 <- nn_sequential(
      nn_conv2d(
        in_channels = 64,
        out_channels = 128,
        kernel_size = 3,
        stride = 1,
        padding = 2
      ),
      nn_relu(),
      nn_max_pool2d(kernel_size = 2)
    )
    
    self$flatten <- nn_flatten()
    
    # Dummy Forward Pass 
    with_no_grad({
      dummy_input <- torch_randn(1, 1, input_height, input_width)
      dummy_output <- self$conv1(dummy_input)
      dummy_output <- self$conv2(dummy_output)
      dummy_output <- self$conv3(dummy_output)
      dummy_output <- self$conv4(dummy_output)
      dummy_output <- self$flatten(dummy_output)
      linear_input_size <- dummy_output$size(2)
    }) 
    
    cat(sprintf("Obliczony rozmiar warstwy liniowej: %d\n", linear_input_size))
    
    self$linear <- nn_linear(linear_input_size, MODEL_CONFIG$num_classes)
  },
  
  forward = function(input_data) {
    x <- self$conv1(input_data)
    x <- self$conv2(x)
    x <- self$conv3(x)
    x <- self$conv4(x)
    x <- self$flatten(x)
    logits <- self$linear(x)
    return(logits)
  }
)

mel_spec_dataset <- dataset(
  name = "mel_spec_dataset",
  initialize = function(data_list) {
    self$data <- data_list
  },
  .getbatch = function(indices) {
    mel_specs <- list()
    class_ids <- c() 
    
    for (i in seq_along(indices)) {
      item <- self$data[[indices[i]]]
      mel_specs[[i]] <- item$mel_spec
      
      class_id <- item$classID
      if (is.numeric(class_id)) {
        class_ids[i] <- as.integer(class_id)
      } else if (inherits(class_id, "torch_tensor")) {
        class_ids[i] <- as.integer(class_id$item())
      } else {
        class_ids[i] <- as.integer(class_id)
      }
    }
    
    mel_spec_batch <- torch_stack(mel_specs)
    classID_batch <- torch_tensor(class_ids, dtype = torch_long()) 
    
    return(list(
      mel_spec = mel_spec_batch,
      classID = classID_batch
    ))
  },
  .getitem = function(index) {
    item <- self$data[[index]]
    
    class_id <- item$classID
    if (is.numeric(class_id)) {
      class_id_value <- as.integer(class_id)
    } else if (inherits(class_id, "torch_tensor")) {
      class_id_value <- as.integer(class_id$item())
    } else {
      class_id_value <- as.integer(class_id)
    }
    
    return(list(
      mel_spec = item$mel_spec,
      classID = torch_tensor(class_id_value, dtype = torch_long()) 
    ))
  },
  .length = function() {
    length(self$data)
  }
)