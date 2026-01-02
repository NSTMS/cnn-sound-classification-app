library(torch)
library(ggplot2)
library(gridExtra)
source("config.R")
source("modules/data_module.R")

# Funkcja do ładowania nazw klas
load_class_names <- function(metadata_path) {
  metadata <- load_metadata(metadata_path)
  class_mapping <- unique(metadata[, c("classID", "class")])
  class_mapping <- class_mapping[order(class_mapping$classID), ]
  return(as.character(class_mapping$class))
}

evaluate_model <- function(model, test_data_loader, device = "cpu", 
                          show_confusion_matrix = TRUE,
                          save_results = TRUE) {
  
  cat("\n")
  cat(paste(rep("=", 70), collapse = ""), "\n")
  cat("                    ROZPOCZYNAM EWALUACJĘ MODELU                    \n")
  cat(paste(rep("=", 70), collapse = ""), "\n\n")
  
  # Wczytaj nazwy klas jeśli nie podano
  class_names <- load_class_names(paste0(getwd(), "/",  PATHS$metadata))
  model$eval()
  model$to(device = device)
    
  test_correct <- 0
  test_total <- 0
  class_correct <- numeric(MODEL_CONFIG$num_classes)
  class_total <- numeric(MODEL_CONFIG$num_classes)
  
  # Macierz pomyłek (confusion matrix)
  confusion_matrix <- matrix(0, nrow = MODEL_CONFIG$num_classes, 
                            ncol = MODEL_CONFIG$num_classes)
  
  predictions_list <- list()
  labels_list <- list()
  
  cat("Przetwarzam dane testowe...\n")
  pb <- txtProgressBar(min = 0, max = length(test_data_loader), style = 3)
  batch_num <- 0
  
  with_no_grad({
    coro::loop(for (batch in test_data_loader) {
      batch_num <- batch_num + 1
      setTxtProgressBar(pb, batch_num)
      
      mel_spec <- batch$mel_spec$to(device = device)
      labels <- batch$classID$to(device = device)
      
      if (length(mel_spec$shape) == 3) {
        mel_spec <- mel_spec$unsqueeze(2)$permute(c(1, 2, 3, 4))
      }
      
      predictions <- model(mel_spec)
      pred_classes <- torch_argmax(predictions, dim = 2)
      
      test_correct <- test_correct + (pred_classes == labels)$sum()$item()
      test_total <- test_total + labels$size(1)
      
      # Statystyki per klasa i macierz pomyłek
      for (i in 1:labels$size(1)) {
        true_label <- labels[i]$item()
        pred_label <- pred_classes[i]$item()
        
        class_total[true_label] <- class_total[true_label] + 1
        
        if (pred_label == true_label) {
          class_correct[true_label] <- class_correct[true_label] + 1
        }
        
        # Wypełnij macierz pomyłek
        confusion_matrix[true_label, pred_label] <- 
          confusion_matrix[true_label, pred_label] + 1
      }
      
      predictions_list[[length(predictions_list) + 1]] <- pred_classes$cpu()
      labels_list[[length(labels_list) + 1]] <- labels$cpu()
    })
  })
  close(pb)
  
  overall_accuracy <- (test_correct / test_total) * 100
  
  # === WYŚWIETLANIE WYNIKÓW ===
  cat("\n\n")
  cat(paste(rep("=", 70), collapse = ""), "\n")
  cat("                        WYNIKI EWALUACJI                            \n")
  cat(paste(rep("=", 70), collapse = ""), "\n\n")
  
  cat(sprintf("📊 OGÓLNA DOKŁADNOŚĆ: %.2f%% (%d/%d poprawnych predykcji)\n\n", 
              overall_accuracy, test_correct, test_total))
  
  cat(paste(rep("-", 70), collapse = ""), "\n")
  cat("📋 DOKŁADNOŚĆ PER KLASA:\n")
  cat(paste(rep("-", 70), collapse = ""), "\n\n")
  
  class_results <- data.frame(
    ClassID = 1:MODEL_CONFIG$num_classes,
    ClassName = class_names,
    Correct = class_correct,
    Total = class_total,
    Accuracy = sprintf("%.2f%%", (class_correct / class_total) * 100)
  )
  
  for (i in 1:MODEL_CONFIG$num_classes) {
    if (class_total[i] > 0) {
      class_acc <- (class_correct[i] / class_total[i]) * 100
      
      # Emoji na podstawie dokładności
      emoji <- if (class_acc >= 90) "🟢" else if (class_acc >= 70) "🟡" else "🔴"
      
      cat(sprintf("%s Klasa %d (%s):\n", 
                  emoji, i, class_names[i]))
      cat(sprintf("   Dokładność: %.2f%% (%d/%d)\n", 
                  class_acc, class_correct[i], class_total[i]))
      cat("\n")
    }
  }
  
  # Najlepsza i najgorsza klasa
  valid_classes <- which(class_total > 0)
  class_accuracies <- (class_correct / class_total)[valid_classes] * 100
  
  best_class_idx <- valid_classes[which.max(class_accuracies)]
  worst_class_idx <- valid_classes[which.min(class_accuracies)]
  
  cat(paste(rep("-", 70), collapse = ""), "\n")
  cat("🏆 STATYSTYKI DODATKOWE:\n")
  cat(paste(rep("-", 70), collapse = ""), "\n\n")
  cat(sprintf("✅ Najlepsza klasa:  %s (%.2f%%)\n", 
              class_names[best_class_idx], 
              (class_correct[best_class_idx] / class_total[best_class_idx]) * 100))
  cat(sprintf("❌ Najgorsza klasa:  %s (%.2f%%)\n", 
              class_names[worst_class_idx], 
              (class_correct[worst_class_idx] / class_total[worst_class_idx]) * 100))
  cat(sprintf("📈 Średnia dokładność: %.2f%%\n", mean(class_accuracies)))
  cat(sprintf("📊 Odchylenie std:     %.2f%%\n\n", sd(class_accuracies)))
  
  # === WIZUALIZACJE ===
  if (show_confusion_matrix) {
    cat("Generuję wizualizacje...\n\n")
    
    # 1. Wykres dokładności per klasa
    plot_data <- data.frame(
      Class = factor(class_names, levels = class_names),
      Accuracy = (class_correct / class_total) * 100
    )
    
    p1 <- ggplot(plot_data, aes(x = Class, y = Accuracy, fill = Accuracy)) +
      geom_bar(stat = "identity") +
      geom_text(aes(label = sprintf("%.1f%%", Accuracy)), 
                vjust = -0.5, size = 3) +
      scale_fill_gradient2(low = "red", mid = "yellow", high = "green", 
                          midpoint = 70, limits = c(0, 100)) +
      labs(title = "Dokładność per Klasa",
           x = "Klasa", y = "Dokładność (%)") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1),
            plot.title = element_text(hjust = 0.5, face = "bold")) +
      ylim(0, 105)
    
    # 2. Macierz pomyłek (heatmap)
    confusion_df <- as.data.frame(as.table(confusion_matrix))
    colnames(confusion_df) <- c("True", "Predicted", "Count")
    confusion_df$True <- factor(class_names[confusion_df$True], levels = class_names)
    confusion_df$Predicted <- factor(class_names[confusion_df$Predicted], levels = class_names)
    
    p2 <- ggplot(confusion_df, aes(x = Predicted, y = True, fill = Count)) +
      geom_tile(color = "white") +
      geom_text(aes(label = Count), color = "black", size = 3) +
      scale_fill_gradient(low = "white", high = "darkblue") +
      labs(title = "Macierz Pomyłek (Confusion Matrix)",
           x = "Predykcja", y = "Prawdziwa Klasa") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1),
            axis.text.y = element_text(angle = 0),
            plot.title = element_text(hjust = 0.5, face = "bold"))
    
    # Wyświetl wykresy
    print(p1)
    print(p2)
  }
  
  # Zapisz szczegółowe wyniki
  if (save_results) {
    results_summary <- list(
      overall_accuracy = overall_accuracy,
      total_correct = test_correct,
      total_samples = test_total,
      class_results = class_results,
      confusion_matrix = confusion_matrix,
      class_names = class_names
    )
    
    saveRDS(results_summary, "evaluation_results.rds")
    write.csv(class_results, "evaluation_per_class.csv", row.names = FALSE)
    
    cat("✅ Wyniki zapisane jako:\n")
    cat("   - evaluation_results.rds (pełne wyniki)\n")
    cat("   - evaluation_per_class.csv (wyniki per klasa)\n\n")
  }
  
  cat(paste(rep("=", 70), collapse = ""), "\n")
  cat("                    EWALUACJA ZAKOŃCZONA                            \n")
  cat(paste(rep("=", 70), collapse = ""), "\n\n")
  
  # Zwróć wyniki
  return(list(
    overall_accuracy = overall_accuracy,
    class_accuracies = (class_correct / class_total) * 100,
    class_correct = class_correct,
    class_total = class_total,
    confusion_matrix = confusion_matrix,
    predictions = predictions_list,
    labels = labels_list,
    class_names = class_names,
    class_results = class_results
  ))
}

# === PRZYKŁAD UŻYCIA ===
# model_results <- train_model(data)
# evaluation <- evaluate_model(
#   model = model_results$model, 
#   test_data = model_results$eval_data,
#   device = "cpu",
#   show_confusion_matrix = TRUE,
#   save_results = TRUE
# )
# 
# # Dostęp do wyników:
# cat("Ogólna dokładność:", evaluation$overall_accuracy, "%\n")
# print(evaluation$class_results)