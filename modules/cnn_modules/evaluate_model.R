# AI generated code for evaluating a CNN model using torch in R.
library(torch)
library(ggplot2)
library(gridExtra)
source("config.R")
source("modules/data_module.R")

evaluate_model <- function(model, test_data_loader, device = "cpu", 
                          show_visualizations = TRUE,
                          save_results = TRUE,
                          output_dir = NULL) {
  
  # === INICJALIZACJA ===
  cat("\n", paste(rep("=", 80), collapse = ""), "\n")
  cat(sprintf("%50s\n", "EWALUACJA MODELU"))
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  
  if (is.null(output_dir)) {
    output_dir <- file.path(getwd(), PATHS$models, "v2")
  }
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  
  class_names <- load_class_names(paste0(getwd(), "/", PATHS$metadata))
  num_classes <- MODEL_CONFIG$num_classes
  
  model$eval()
  model$to(device = device)
  
  # Inicjalizacja metryk
  test_correct <- 0
  test_total <- 0
  class_correct <- rep(0, num_classes)
  class_total <- rep(0, num_classes)
  confusion_matrix <- matrix(0, nrow = num_classes, ncol = num_classes)
  
  all_predictions <- list()
  all_labels <- list()
  
  # === PRZETWARZANIE BATCHY ===
  cat("Przetwarzanie danych testowych...\n")
  pb <- txtProgressBar(min = 0, max = length(test_data_loader), style = 3, width = 70)
  batch_num <- 0
  
  start_time <- Sys.time()
  
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
      
      # Aktualizuj metryki
      test_correct <- test_correct + sum(as.logical(pred_classes == labels))
      test_total <- test_total + labels$size(1)
      
      # Metryki per klasa
      pred_vec <- as.integer(pred_classes$cpu())
      label_vec <- as.integer(labels$cpu())
      
      for (i in seq_along(label_vec)) {
        true_label <- label_vec[i]
        pred_label <- pred_vec[i]
        
        class_total[true_label] <- class_total[true_label] + 1
        
        if (pred_label == true_label) {
          class_correct[true_label] <- class_correct[true_label] + 1
        }
        
        confusion_matrix[true_label, pred_label] <- 
          confusion_matrix[true_label, pred_label] + 1
      }
      
      all_predictions[[batch_num]] <- pred_classes$cpu()
      all_labels[[batch_num]] <- labels$cpu()
    })
  })
  
  close(pb)
  end_time <- Sys.time()
  eval_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  # === OBLICZANIE METRYK ===
  overall_accuracy <- (test_correct / test_total) * 100
  class_accuracies <- (class_correct / class_total) * 100
  class_accuracies[is.nan(class_accuracies)] <- 0
  
  # Precision, Recall, F1-Score per klasa
  precision <- rep(0, num_classes)
  recall <- rep(0, num_classes)
  f1_score <- rep(0, num_classes)
  
  for (i in 1:num_classes) {
    tp <- confusion_matrix[i, i]
    fp <- sum(confusion_matrix[, i]) - tp
    fn <- sum(confusion_matrix[i, ]) - tp
    
    precision[i] <- ifelse(tp + fp > 0, tp / (tp + fp), 0)
    recall[i] <- ifelse(tp + fn > 0, tp / (tp + fn), 0)
    f1_score[i] <- ifelse(precision[i] + recall[i] > 0, 
                          2 * (precision[i] * recall[i]) / (precision[i] + recall[i]), 
                          0)
  }
  
  # Weighted average
  weights <- class_total / sum(class_total)
  weighted_precision <- sum(precision * weights)
  weighted_recall <- sum(recall * weights)
  weighted_f1 <- sum(f1_score * weights)
  
  # === WYŚWIETLANIE WYNIKÓW ===
  cat("\n\n", paste(rep("=", 80), collapse = ""), "\n")
  cat(sprintf("%50s\n", "WYNIKI EWALUACJI"))
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  
  # Metryki ogólne
  cat("📊 METRYKI OGÓLNE:\n")
  cat(paste(rep("-", 80), collapse = ""), "\n")
  cat(sprintf("  Dokładność (Accuracy):     %6.2f%% (%d/%d)\n", 
              overall_accuracy, test_correct, test_total))
  cat(sprintf("  Precision (weighted):      %6.2f%%\n", weighted_precision * 100))
  cat(sprintf("  Recall (weighted):         %6.2f%%\n", weighted_recall * 100))
  cat(sprintf("  F1-Score (weighted):       %6.2f%%\n", weighted_f1 * 100))
  cat(sprintf("  Czas ewaluacji:            %6.2f s\n", eval_time))
  cat(sprintf("  Prędkość:                  %6.2f próbek/s\n", test_total / eval_time))
  cat("\n")
  
  # Metryki per klasa
  cat("📋 METRYKI PER KLASA:\n")
  cat(paste(rep("-", 80), collapse = ""), "\n")
  cat(sprintf("%-4s %-20s %8s %8s %8s %8s %10s\n", 
              "ID", "Klasa", "Accuracy", "Prec", "Recall", "F1", "Próbki"))
  cat(paste(rep("-", 80), collapse = ""), "\n")
  
  for (i in 1:num_classes) {
    if (class_total[i] > 0) {
      emoji <- if (class_accuracies[i] >= 90) "🟢" 
               else if (class_accuracies[i] >= 70) "🟡" 
               else "🔴"
      
      cat(sprintf("%s %-2d %-20s %7.2f%% %7.2f%% %7.2f%% %7.2f%% %10d\n",
                  emoji, i, 
                  substr(class_names[i], 1, 20),
                  class_accuracies[i],
                  precision[i] * 100,
                  recall[i] * 100,
                  f1_score[i] * 100,
                  class_total[i]))
    }
  }
  cat("\n")
  
  # Statystyki dodatkowe
  valid_indices <- which(class_total > 0)
  best_idx <- valid_indices[which.max(class_accuracies[valid_indices])]
  worst_idx <- valid_indices[which.min(class_accuracies[valid_indices])]
  
  cat("📈 STATYSTYKI DODATKOWE:\n")
  cat(paste(rep("-", 80), collapse = ""), "\n")
  cat(sprintf("  ✅ Najlepsza klasa:        %s (%.2f%%)\n", 
              class_names[best_idx], class_accuracies[best_idx]))
  cat(sprintf("  ❌ Najgorsza klasa:        %s (%.2f%%)\n", 
              class_names[worst_idx], class_accuracies[worst_idx]))
  cat(sprintf("  📊 Średnia dokładność:     %.2f%%\n", mean(class_accuracies[valid_indices])))
  cat(sprintf("  📏 Odchylenie std:         %.2f%%\n", sd(class_accuracies[valid_indices])))
  cat(sprintf("  🎯 Mediana:                %.2f%%\n", median(class_accuracies[valid_indices])))
  cat("\n")
  
  # === TWORZENIE WIZUALIZACJI ===
  if (show_visualizations) {
    cat("🎨 Generowanie wizualizacji...\n\n")
    
    # 1. Wykres dokładności per klasa
    plot_df <- data.frame(
      Class = factor(class_names, levels = class_names),
      Accuracy = class_accuracies,
      F1Score = f1_score * 100
    )
    
    p1 <- ggplot(plot_df, aes(x = Class, y = Accuracy, fill = Accuracy)) +
      geom_col() +
      geom_text(aes(label = sprintf("%.1f%%", Accuracy)), 
                vjust = -0.5, size = 3.5, fontface = "bold") +
      scale_fill_gradient2(low = "#d32f2f", mid = "#fbc02d", high = "#388e3c", 
                          midpoint = 70, limits = c(0, 100)) +
      labs(title = "Dokładność Klasyfikacji per Klasa",
           subtitle = sprintf("Średnia dokładność: %.2f%%", mean(class_accuracies[valid_indices])),
           x = "Klasa", y = "Dokładność (%)") +
      theme_minimal(base_size = 12) +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
        plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
        plot.subtitle = element_text(hjust = 0.5, size = 11),
        legend.position = "right"
      ) +
      ylim(0, 105)
    
    # 2. Macierz pomyłek (heatmap)
    confusion_df <- expand.grid(
      True = 1:num_classes,
      Predicted = 1:num_classes
    )
    confusion_df$Count <- as.vector(confusion_matrix)
    confusion_df$TrueLabel <- factor(class_names[confusion_df$True], levels = class_names)
    confusion_df$PredLabel <- factor(class_names[confusion_df$Predicted], levels = class_names)
    
    p2 <- ggplot(confusion_df, aes(x = PredLabel, y = TrueLabel, fill = Count)) +
      geom_tile(color = "white", size = 0.5) +
      geom_text(aes(label = Count), color = "white", size = 3, fontface = "bold") +
      scale_fill_gradient(low = "#1a237e", high = "#f44336", 
                         breaks = seq(0, max(confusion_df$Count), length.out = 5)) +
      labs(title = "Macierz Pomyłek (Confusion Matrix)",
           subtitle = "Komórki diagonalne = poprawne klasyfikacje",
           x = "Predykcja", y = "Prawdziwa Klasa",
           fill = "Liczba\nPróbek") +
      theme_minimal(base_size = 12) +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
        axis.text.y = element_text(size = 9),
        plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
        plot.subtitle = element_text(hjust = 0.5, size = 10),
        legend.position = "right"
      )
    
    # 3. F1-Score comparison
    metrics_df <- data.frame(
      Class = rep(class_names, 3),
      Metric = rep(c("Accuracy", "Precision", "Recall"), each = num_classes),
      Value = c(class_accuracies, precision * 100, recall * 100)
    )
    
    p3 <- ggplot(metrics_df, aes(x = Class, y = Value, fill = Metric)) +
      geom_col(position = "dodge") +
      scale_fill_manual(values = c("#2196f3", "#4caf50", "#ff9800")) +
      labs(title = "Porównanie Metryk per Klasa",
           x = "Klasa", y = "Wartość (%)") +
      theme_minimal(base_size = 12) +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
        plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
        legend.position = "top"
      ) +
      ylim(0, 105)
    
    ggsave(file.path(output_dir, "accuracy_per_class.png"), 
           plot = p1, width = 12, height = 6, dpi = 300)
    ggsave(file.path(output_dir, "confusion_matrix.png"), 
           plot = p2, width = 10, height = 8, dpi = 300)
    ggsave(file.path(output_dir, "metrics_comparison.png"), 
           plot = p3, width = 14, height = 6, dpi = 300)
    
    # Wyświetl wykresy
    print(p1)
    print(p2)
    print(p3)
  }
  
  if (save_results) {
    cat("💾 Zapisywanie wyników...\n")
    
    # Szczegółowa tabela per klasa
    detailed_results <- data.frame(
      ClassID = 1:num_classes,
      ClassName = class_names,
      Samples = class_total,
      Correct = class_correct,
      Accuracy = round(class_accuracies, 2),
      Precision = round(precision * 100, 2),
      Recall = round(recall * 100, 2),
      F1Score = round(f1_score * 100, 2),
      stringsAsFactors = FALSE
    )
    
    summary_results <- list(
      evaluation_date = Sys.time(),
      overall_metrics = list(
        accuracy = overall_accuracy,
        precision_weighted = weighted_precision * 100,
        recall_weighted = weighted_recall * 100,
        f1_score_weighted = weighted_f1 * 100,
        total_samples = test_total,
        correct_predictions = test_correct,
        evaluation_time_seconds = eval_time,
        samples_per_second = test_total / eval_time
      ),
      per_class_results = detailed_results,
      confusion_matrix = confusion_matrix,
      class_names = class_names,
      model_config = MODEL_CONFIG
    )
    
    saveRDS(summary_results, file.path(output_dir, "evaluation_summary.rds"))
    write.csv(detailed_results, file.path(output_dir, "evaluation_per_class.csv"), 
              row.names = FALSE)
    write.csv(confusion_matrix, file.path(output_dir, "confusion_matrix.csv"))
    
    sink(file.path(output_dir, "evaluation_report.txt"))
    cat("="*80, "\n")
    cat(sprintf("%50s\n", "RAPORT EWALUACJI MODELU"))
    cat("="*80, "\n\n")
    cat(sprintf("Data ewaluacji: %s\n", Sys.time()))
    cat(sprintf("Czas trwania: %.2f s\n\n", eval_time))
    cat(sprintf("Ogólna dokładność: %.2f%%\n", overall_accuracy))
    cat(sprintf("Weighted Precision: %.2f%%\n", weighted_precision * 100))
    cat(sprintf("Weighted Recall: %.2f%%\n", weighted_recall * 100))
    cat(sprintf("Weighted F1-Score: %.2f%%\n\n", weighted_f1 * 100))
    print(detailed_results)
    sink()
    
    cat("\n✅ Wyniki zapisane w:", output_dir, "\n")
    cat("   - evaluation_summary.rds\n")
    cat("   - evaluation_per_class.csv\n")
    cat("   - confusion_matrix.csv\n")
    cat("   - evaluation_report.txt\n")
    cat("   - accuracy_per_class.png\n")
    cat("   - confusion_matrix.png\n")
    cat("   - metrics_comparison.png\n\n")
  }
  
  cat(paste(rep("=", 80), collapse = ""), "\n")
  cat(sprintf("%50s\n", "EWALUACJA ZAKOŃCZONA"))
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  
  invisible(list(
    overall_accuracy = overall_accuracy,
    weighted_precision = weighted_precision,
    weighted_recall = weighted_recall,
    weighted_f1 = weighted_f1,
    class_results = detailed_results,
    confusion_matrix = confusion_matrix,
    predictions = all_predictions,
    labels = all_labels,
    class_names = class_names,
    evaluation_time = eval_time
  ))
}