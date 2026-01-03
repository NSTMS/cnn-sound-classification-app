library(torch)
load_cnn_model <- function(model_path) {
  if(!file.exists(model_path)) {
    stop(paste("NIe znaleziono pliku: ", model_path))
  }
  model <- torch::torch_load(model_path)
  return(model)
}

predict_class <- function(model_path, mel_spec_tensor, class_labels) {
  device <- if (cuda_is_available()) "cuda" else "cpu"
  
  model <- load_cnn_model(model_path)
  model$to(device = device)
  model$eval()

  with_no_grad({
    # [batch=1, channel=1, freq, time]
    input_tensor <- mel_spec_tensor$unsqueeze(1)$unsqueeze(1)$to(device = device)
    outputs <- model(input_tensor)
    probabilities <- nnf_softmax(outputs, dim = -1) 
    probs_squeezed <- probabilities$squeeze()
    
    topk_result <- torch_topk(probs_squeezed, k = 3)
    topk_values <- as.numeric(topk_result[[1]]$cpu())  
    topk_indices <- as.integer(topk_result[[2]]$cpu())

    predicted_classes <- class_labels[topk_indices]
    
    results <- data.frame(
      class = predicted_classes,
      probability = round(topk_values, 4),
      stringsAsFactors = FALSE
    )
    
    return(results)
  })
}