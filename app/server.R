server <- function(input, output, session) {
addResourcePath("models", "models")
  rv <- reactiveValues(
    current_audio = NULL,
    current_spectrogram = NULL,
    current_prediction = NULL,
    history = data.frame(
      timestamp = character(),
      filename = character(),
      predicted_class = character(),
      confidence = numeric(),
      stringsAsFactors = FALSE
    )
  )
  
  observeEvent(input$upload_audio, {
    req(input$audio_file)
    
    audio_path <- input$audio_file$datapath
    filename <- input$audio_file$name
    notification_id <- showNotification(
      "Przetwarzanie pliku audio...",
      duration = NULL,
      type = "message"
    )
    
    tryCatch({
      resampled_wav <- load_and_resample_audio_sample(audio_path)
      mel_spec <- create_tensorized_and_normalized_mel_spectrogram(resampled_wav)
      prediction <- predict_class(MODEL_PATH, mel_spec, CLASS_LABELS)
      
      rv$current_audio <- resampled_wav
      rv$current_spectrogram <- mel_spec
      rv$current_prediction <- prediction
      
      new_record <- data.frame(
        timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        filename = filename,
        predicted_class = prediction$class[1],
        confidence = round(prediction$probability[1] * 100, 2),
        stringsAsFactors = FALSE
      )
      
      rv$history <- rbind(new_record, rv$history)
      
      removeNotification(notification_id)
      
      showNotification(
        paste("Analiza zakończona! Rozpoznano:", prediction$class[1]),
        type = "message",
        duration = 5
      )
      
      updateTabsetPanel(session, "main_tabs", selected = "Predykcja")
      
    }, error = function(e) {
      removeNotification(notification_id)
      showNotification(
        paste("Błąd podczas przetwarzania:", e$message),
        type = "error",
        duration = 10
      )
    })
  })
  
  output$spectrogram_plot <- renderPlot({
    req(rv$current_audio)
    show_mel_spectogram(rv$current_audio)
  })
  
  output$prediction_cards <- renderUI({
    req(rv$current_prediction)
    
    pred <- rv$current_prediction
    top_class <- pred$class[1]
    top_prob <- pred$probability[1]
    
    div(
      div(
        class = "prediction-card",
        div(class = "prediction-label", "Rozpoznana klasa"),
        div(class = "prediction-value", top_class),
        div(
          style = "margin-top: 1rem;",
          div(class = "prediction-label", "Pewność predykcji"),
          div(class = "prediction-confidence", paste0(round(top_prob * 100, 2), "%"))
        ),
        div(
          style = "margin-top: 1rem;",
          span(class = "status-badge status-success", 
               if(top_prob > 0.9) "Wysoka pewność" else if(top_prob > 0.7) "Średnia pewność" else "Niska pewność")
        )
      )
    )
  })
  
  output$prediction_chart <- renderPlot({
    req(rv$current_prediction)
    
    pred <- rv$current_prediction %>%
      mutate(
        probability_pct = probability * 100,
        class = reorder(class, probability)
      )
    
    colors <- rep("#E5E7EB", nrow(pred))
    colors[which.max(pred$probability)] <- "#C47335"
    
    ggplot(pred, aes(x = probability_pct, y = class)) +
      geom_col(fill = colors, width = 0.7) +
      geom_text(
        aes(label = paste0(round(probability_pct, 1), "%")),
        hjust = -0.1,
        color = "#2C2D30",
        size = 4,
        fontface = "bold"
      ) +
      scale_x_continuous(
        limits = c(0, max(pred$probability_pct) * 1.15),
        expand = c(0, 0)
      ) +
      labs(
        x = "Prawdopodobieństwo (%)",
        y = NULL,
        title = "Rozkład prawdopodobieństwa dla wszystkich klas"
      ) +
      theme_minimal(base_size = 13) +
      theme(
        plot.title = element_text(
          color = "#2C2D30",
          size = 16,
          face = "bold",
          margin = margin(b = 15)
        ),
        axis.text.y = element_text(
          color = "#2C2D30",
          size = 12,
          face = "bold"
        ),
        axis.text.x = element_text(
          color = "#6B7280",
          size = 11
        ),
        axis.title.x = element_text(
          color = "#6B7280",
          size = 12,
          margin = margin(t = 10)
        ),
        panel.grid.major.y = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_line(color = "#F3F4F6", linewidth = 0.5),
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        plot.margin = margin(20, 20, 20, 20)
      )
  }, bg = "white", height = 400)
  
  output$history_table <- DT::renderDataTable({
    req(nrow(rv$history) > 0)
    
    history_display <- rv$history %>%
      mutate(
        confidence = paste0(confidence, "%")
      ) %>%
      rename(
        "Data i czas" = timestamp,
        "Nazwa pliku" = filename,
        "Klasa" = predicted_class,
        "Pewność" = confidence
      )
    
    DT::datatable(
      history_display,
      options = list(
        pageLength = 10,
        ordering = TRUE,
        order = list(list(0, 'desc')),
        dom = 'tip',
        language = list(
          info = "Pokazano _START_ do _END_ z _TOTAL_ wpisów",
          paginate = list(
            previous = "Poprzednia",
            `next` = "Następna"
          )
        )
      ),
      rownames = FALSE,
      selection = 'none',
      class = 'cell-border stripe'
    ) %>%
      DT::formatStyle(
        columns = colnames(history_display),
        backgroundColor = '#FFFFFF',
        color = '#2C2D30'
      ) %>%
      DT::formatStyle(
        'Pewność',
        color = styleInterval(
          cuts = c(70, 90),
          values = c('#DC2626', '#F59E0B', '#059669')
        ),
        fontWeight = 'bold'
      )
  })
}