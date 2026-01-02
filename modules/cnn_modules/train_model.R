library(torch)
source("config.R")

train_model <- function(audio_files, labels = NULL) {
  device <- if (cuda_is_available()) "cuda" else "cpu"
  cat(sprintf("Do obliczeń używam: %s\n", device))
  
  for (i in seq_along(audio_files)) {
    audio_files[[i]]$classID <- audio_files[[i]]$classID + 1
  }
  

  # podział danych na podzbiory 
  dataset_length <- length(audio_files)
  train_size <- floor(0.65 * dataset_length)
  val_size <- floor(0.25 * dataset_length)
  eval_size <- dataset_length - train_size - val_size 

  indices <- sample(1:dataset_length)
  train_indices <- indices[1:train_size]
  val_indices <- indices[(train_size + 1):(train_size + val_size)]
  eval_indices <- indices[(train_size + val_size + 1):dataset_length]

  train_data <- audio_files[train_indices]
  val_data <- audio_files[val_indices]
  eval_data <- audio_files[eval_indices]

  train_dataset <- mel_spec_dataset(train_data)
  val_dataset <- mel_spec_dataset(val_data)
  eval_dataset <- mel_spec_dataset(eval_data)

  train_loader <- dataloader(train_dataset, batch_size = MODEL_CONFIG$batch_size, shuffle = TRUE)
  val_loader <- dataloader(val_dataset, batch_size = MODEL_CONFIG$batch_size, shuffle = FALSE)
  eval_loader <- dataloader(eval_dataset, batch_size = MODEL_CONFIG$batch_size, shuffle = FALSE)
  
  model <- cnn_network()
  model$to(device = device)
  
  loss_fn <- nn_cross_entropy_loss()
  optimiser <- optim_adam(model$parameters, lr = MODEL_CONFIG$learning_rate)
  
  # learning rate scheduler
  scheduler <- lr_step(optimiser, step_size = 10, gamma = 0.5)
  
  best_accuracy <- 0
  train_losses <- c()
  val_losses <- c()
  val_accuracies <- c()
  
  for (epoch in 1:MODEL_CONFIG$epochs) {
    cat(sprintf("\nEpoch %d/%d\n", epoch, MODEL_CONFIG$epochs))
    cat(paste(rep("=", 50), collapse = ""), "\n")
    
    model$train()
    train_loss <- 0
    train_correct <- 0
    train_total <- 0
    
    coro::loop(for (batch in train_loader) {
      mel_spec <- batch$mel_spec$to(device = device)
      labels <- batch$classID$to(device = device)
      
      if (length(mel_spec$shape) == 3) mel_spec <- mel_spec$unsqueeze(2)$permute(c(1, 2, 3, 4))
      
      # forward pass
      predictions <- model(mel_spec) 
      loss <- loss_fn(predictions, labels) 
      
      # backward pass
      optimiser$zero_grad() # reset gradientów
      loss$backward() # obliczanie nowych gradientów
      optimiser$step() # aktualizacja wag - krok w stronę minimalnej straty
      
      train_loss <- train_loss + loss$item()
      pred_classes <- torch_argmax(predictions, dim = 2)
      train_correct <- train_correct + (pred_classes == labels)$sum()$item()
      train_total <- train_total + labels$size(1)
    })
    
    avg_train_loss <- train_loss / length(train_loader)
    train_accuracy <- (train_correct / train_total) * 100
    train_losses <- c(train_losses, avg_train_loss)
    
    cat(sprintf("Train Loss: %.4f | Train Accuracy: %.2f%%\n", 
                avg_train_loss, train_accuracy))
    
    # walidacja treningu 
    model$eval()
    val_loss <- 0
    val_correct <- 0
    val_total <- 0
    
    with_no_grad({
      coro::loop(for (batch in val_loader) {
        mel_spec <- batch$mel_spec$to(device = device)
        labels <- batch$classID$to(device = device)
        
        if (length(mel_spec$shape) == 3) mel_spec <- mel_spec$unsqueeze(2)$permute(c(1, 2, 3, 4))
        
        # forward pass
        predictions <- model(mel_spec)
        loss <- loss_fn(predictions, labels)
        
        val_loss <- val_loss + loss$item()
        pred_classes <- torch_argmax(predictions, dim = 2)
        val_correct <- val_correct + (pred_classes == labels)$sum()$item()
        val_total <- val_total + labels$size(1)
      })
    })
    
    avg_val_loss <- val_loss / length(val_loader)
    val_accuracy <- (val_correct / val_total) * 100
    val_losses <- c(val_losses, avg_val_loss)
    val_accuracies <- c(val_accuracies, val_accuracy)
    
    cat(sprintf("Val Loss: %.4f | Val Accuracy: %.2f%%\n", 
                avg_val_loss, val_accuracy))
    
    scheduler$step()
    current_lr <- optimiser$param_groups[[1]]$lr
    cat(sprintf("Learning Rate: %.6f\n", current_lr))
    
    if (val_accuracy > best_accuracy) {
      best_accuracy <- val_accuracy
      model_path <- paste0(getwd(), "/",  PATHS$models, "/", "best_model.pt")
      torch_save(model, model_path)
      cat("✓ Zapisano najlepszy model!\n")
    }
  }
  cat("Trening zakończony.\n")
  
  history <- list(
    train_losses = train_losses,
    val_losses = val_losses,
    val_accuracies = val_accuracies
  )
  history_path <- paste0(getwd(), "/",  PATHS$models, "/", "training_history.rds")
  saveRDS(history, history_path)

  cat("Historia treningu zapisana.\n")

  return(list(
    model = model,
    eval_data = eval_loader 
  ))
}

