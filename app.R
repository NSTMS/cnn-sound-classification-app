library(shiny)
library(bslib)
library(ggplot2)

source("modules/cnn_modules/predict_class.R")
source("modules/audio_module.R")

# Ścieżki i konfiguracja
model_path <- file.path(getwd(), PATHS$models, "v1", "model_v1.pt")
class_labels <- load_class_names(paste0(getwd(), "/", PATHS$metadata))


ui <- page_fluid(
  theme = bs_theme(
    version = 5,
    bg = "#ffffff",
    fg = "#1a1a1a",
    primary = "#2c3e50",
    secondary = "#34495e",
    base_font = font_google("Libre Baskerville"),
    heading_font = font_google("Playfair Display")
  ),
  
  tags$head(
    tags$style(HTML("
      body {
        background: #f8f9fa;
      }
      
      .card {
        background: #ffffff;
        border: 1px solid #e8e8e8;
        border-radius: 4px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
        transition: box-shadow 0.3s ease;
      }
      
      .card:hover {
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
      }
      
      .card-header {
        background: #fafafa;
        border-bottom: 1px solid #e8e8e8;
        font-weight: 600;
        font-size: 1rem;
        letter-spacing: 0.3px;
        color: #2c3e50;
      }
      
      .btn-primary {
        background: #2c3e50;
        border: none;
        border-radius: 2px;
        padding: 10px 28px;
        font-weight: 500;
        letter-spacing: 0.5px;
        transition: all 0.2s ease;
      }
      
      .btn-primary:hover {
        background: #34495e;
      }
      
      .btn-secondary {
        background: #6b7280;
        border: none;
        border-radius: 2px;
        padding: 12px 36px;
        font-weight: 500;
        letter-spacing: 0.5px;
        transition: all 0.2s ease;
        color: white;
      }
      
      .btn-secondary:hover {
        background: #4b5563;
        color: white;
      }
      
      /* Custom file input */
      .custom-file-input-wrapper {
        position: relative;
        display: inline-block;
        width: 100%;
      }
      
      .custom-file-input {
        position: absolute;
        opacity: 0;
        width: 100%;
        height: 100%;
        cursor: pointer;
      }
      
      .custom-file-label {
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 3rem 2rem;
        border: 2px dashed #d1d5db;
        border-radius: 4px;
        background: #fafafa;
        transition: all 0.2s ease;
        cursor: pointer;
        text-align: center;
      }
      
      .custom-file-label:hover {
        border-color: #2c3e50;
        background: #f3f4f6;
      }
      
      .custom-file-label i {
        font-size: 2rem;
        color: #6b7280;
        margin-right: 1rem;
      }
      
      .custom-file-text {
        color: #4b5563;
        font-size: 0.95rem;
      }
      
      .custom-file-text strong {
        color: #2c3e50;
        font-weight: 600;
      }
      
      .file-info {
        margin-top: 1rem;
        padding: 0.75rem;
        background: #eff6ff;
        border-left: 3px solid #2563eb;
        border-radius: 2px;
        font-size: 0.9rem;
        color: #1e40af;
      }
      
      h2 {
        color: #2c3e50;
        font-weight: 600;
        margin-bottom: 0.5rem;
        letter-spacing: -0.5px;
      }
      
      .plot-container {
        background: #ffffff;
        border: 1px solid #e8e8e8;
        border-radius: 2px;
        padding: 1.5rem;
        margin-top: 1rem;
        min-height: 450px;
        display: flex;
        align-items: center;
        justify-content: center;
      }
      
      .nav-link {
        color: #6b7280;
        border: none;
        border-bottom: 2px solid transparent;
        border-radius: 0;
        transition: all 0.2s ease;
      }
      
      .nav-link:hover {
        color: #2c3e50;
        border-bottom-color: #d1d5db;
      }
      
      .nav-link.active {
        color: #2c3e50;
        background: transparent;
        border-bottom-color: #2c3e50;
      }
      
      .history-item {
        padding: 1rem;
        border-bottom: 1px solid #e8e8e8;
        transition: background 0.2s ease;
        cursor: pointer;
      }
      
      .history-item:hover {
        background: #f9fafb;
      }
      
      .history-item:last-child {
        border-bottom: none;
      }
      
      .history-filename {
        font-weight: 600;
        color: #2c3e50;
        margin-bottom: 0.25rem;
      }
      
      .history-timestamp {
        font-size: 0.85rem;
        color: #6b7280;
      }
    "))
  ),
  
  div(
    style = "max-width: 1400px; margin: 0 auto; padding: 2rem;",
    
    # Nagłówek
    div(
      style = "text-align: center; margin-bottom: 3rem; padding-bottom: 2rem; border-bottom: 1px solid #e8e8e8;",
      h2("Audio Classification", style = "font-size: 2.2rem; margin-bottom: 0.5rem;"),
      p("Neural network-based sound analysis", 
        style = "color: #6b7280; font-size: 1rem; font-family: 'Libre Baskerville', serif;")
    ),
    
    # Główna zawartość
    layout_columns(
      col_widths = c(4, 8),
      
      # Panel kontrolny
      card(
        card_header("Wybierz plik audio"),
        card_body(
          div(
            class = "custom-file-input-wrapper",
            fileInput(
              "audio_file",
              NULL,
              accept = c(".wav")
            ),
          ),
          uiOutput("file_info"),
          div(
            style = "margin-top: 1.5rem;",
            uiOutput("status_info")
          )
        )
      ),
      
      # Panel wyników
      card(
        card_body(
          navset_card_tab(
            nav_panel(
              "Spektrogram",
              div(
                class = "plot-container",
                uiOutput("mel_spec_content")
              )
            ),
            nav_panel(
              "Predykcja",
              div(
                class = "plot-container",
                uiOutput("prediction_content")
              )
            ),
            nav_panel(
              "Historia",
              div(
                style = "margin-top: 1rem;",
                uiOutput("history_list")
              )
            )
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  # Reaktywne wartości
  audio_data <- reactiveVal(NULL)
  current_filename <- reactiveVal(NULL)
  predictions <- reactiveVal(NULL)
  mel_spec_generated <- reactiveVal(FALSE)
  prediction_generated <- reactiveVal(FALSE)
  
  # Historia spektrogramów
  history <- reactiveVal(list())
  
  # Wczytanie i przetworzenie audio
  observeEvent(input$audio_file, {
    req(input$audio_file)
    
    tryCatch({
      resampled <- load_and_resample_audio_sample(input$audio_file$datapath)
      audio_data(resampled)
      current_filename(input$audio_file$name)
      predictions(NULL)
      mel_spec_generated(FALSE)
      prediction_generated(FALSE)
      
      output$file_info <- renderUI({
        div(
          class = "file-info",
          icon("file-audio", style = "margin-right: 8px;"),
          strong(input$audio_file$name)
        )
      })
      
      output$status_info <- renderUI({
        div(
          style = "padding: 0.875rem; background: #f0fdf4; 
                   border-left: 3px solid #16a34a; border-radius: 2px;",
          icon("check-circle", style = "color: #16a34a; margin-right: 8px;"),
          span("Plik wczytany pomyślnie", style = "color: #15803d; font-weight: 500;")
        )
      })
    }, error = function(e) {
      output$status_info <- renderUI({
        div(
          style = "padding: 0.875rem; background: #fef2f2; 
                   border-left: 3px solid #dc2626; border-radius: 2px;",
          icon("exclamation-circle", style = "color: #dc2626; margin-right: 8px;"),
          span(paste("Błąd:", e$message), style = "color: #991b1b; font-weight: 500;")
        )
      })
    })
  })
  
  # Obsługa przycisku generowania spektrogramu
  output$mel_spec_content <- renderUI({
    if (!mel_spec_generated()) {
      div(
        style = "text-align: center;",
        actionButton(
          "generate_mel_spec",
          "Wygeneruj spektrogram",
          class = "btn-secondary",
          icon = icon("chart-area")
        )
      )
    } else {
      plotOutput("mel_spec_plot", height = "450px")
    }
  })
  
  observeEvent(input$generate_mel_spec, {
    req(audio_data())
    mel_spec_generated(TRUE)
    
    # Dodaj do historii
    timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    new_entry <- list(
      filename = current_filename(),
      timestamp = timestamp,
      audio_data = audio_data()
    )
    current_history <- history()
    history(c(list(new_entry), current_history))
  })
  
  # Wyświetlenie spektrogramu
  output$mel_spec_plot <- renderPlot({
    req(audio_data(), mel_spec_generated())
    show_mel_spectogram(audio_data())
  }, bg = "white")
  
  # Obsługa przycisku predykcji
  output$prediction_content <- renderUI({
    if (!prediction_generated()) {
      div(
        style = "text-align: center;",
        actionButton(
          "generate_prediction",
          "Uruchom klasyfikację",
          class = "btn-secondary",
          icon = icon("brain")
        )
      )
    } else {
      plotOutput("prediction_plot", height = "450px")
    }
  })
  
  observeEvent(input$generate_prediction, {
    req(audio_data())
    
    withProgress(message = 'Klasyfikacja w toku...', value = 0, {
      tryCatch({
        incProgress(0.3, detail = "Tworzenie spektrogramu...")
        mel_spec <- create_tensorized_and_normalized_mel_spectrogram(audio_data())
        
        incProgress(0.4, detail = "Uruchamianie modelu...")
        pred <- predict_class(model_path, mel_spec, class_labels)
        predictions(pred)
        prediction_generated(TRUE)
        
        incProgress(0.3, detail = "Gotowe!")
        
        output$status_info <- renderUI({
          div(
            style = "padding: 0.875rem; background: #eff6ff; 
                     border-left: 3px solid #2563eb; border-radius: 2px;",
            icon("brain", style = "color: #2563eb; margin-right: 8px;"),
            span("Klasyfikacja zakończona", style = "color: #1e40af; font-weight: 500;")
          )
        })
      }, error = function(e) {
        output$status_info <- renderUI({
          div(
            style = "padding: 0.875rem; background: #fef2f2; 
                     border-left: 3px solid #dc2626; border-radius: 2px;",
            icon("exclamation-circle", style = "color: #dc2626; margin-right: 8px;"),
            span(paste("Błąd predykcji:", e$message), style = "color: #991b1b; font-weight: 500;")
          )
        })
      })
    })
  })
  
  # Wykres predykcji
  output$prediction_plot <- renderPlot({
    req(predictions(), prediction_generated())
    
    pred_data <- predictions()
    pred_data$class <- factor(pred_data$class, levels = pred_data$class[order(pred_data$probability)])
    
    ggplot(pred_data, aes(x = probability, y = class, fill = probability)) +
      geom_col(width = 0.65, alpha = 1) +
      geom_text(
        aes(label = sprintf("%.1f%%", probability * 100)),
        hjust = -0.2,
        color = "#374151",
        size = 4.5,
        fontface = "plain"
      ) +
      scale_fill_gradient(
        low = "#e5e7eb",
        high = "#2c3e50",
        guide = "none"
      ) +
      scale_x_continuous(
        limits = c(0, max(pred_data$probability) * 1.15),
        labels = scales::percent_format(),
        expand = c(0, 0)
      ) +
      labs(
        title = "Classification Probabilities",
        x = "Probability",
        y = NULL
      ) +
      theme_minimal(base_size = 13) +
      theme(
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        panel.grid.major.y = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_line(color = "#e5e7eb", linewidth = 0.5),
        text = element_text(color = "#1a1a1a"),
        plot.title = element_text(
          size = 16,
          face = "plain",
          color = "#2c3e50",
          margin = margin(b = 20),
          hjust = 0
        ),
        axis.text = element_text(color = "#4b5563", size = 11),
        axis.text.y = element_text(hjust = 1),
        axis.title.x = element_text(margin = margin(t = 15), size = 12, color = "#6b7280"),
        plot.margin = margin(20, 20, 20, 20)
      )
  }, bg = "white")
  
  # Historia spektrogramów
  output$history_list <- renderUI({
    current_history <- history()
    
    if (length(current_history) == 0) {
      return(div(
        style = "text-align: center; padding: 3rem; color: #6b7280;",
        icon("history", style = "font-size: 2rem; margin-bottom: 1rem;"),
        p("Brak historii spektrogramów")
      ))
    }
    
    lapply(seq_along(current_history), function(i) {
      entry <- current_history[[i]]
      div(
        class = "history-item",
        onclick = sprintf("Shiny.setInputValue('history_select', %d, {priority: 'event'})", i),
        div(class = "history-filename", entry$filename),
        div(class = "history-timestamp", entry$timestamp)
      )
    })
  })
  
  observeEvent(input$history_select, {
    req(input$history_select)
    current_history <- history()
    selected <- current_history[[input$history_select]]
    
    audio_data(selected$audio_data)
    current_filename(selected$filename)
    mel_spec_generated(TRUE)
    prediction_generated(FALSE)
    predictions(NULL)
    
    output$file_info <- renderUI({
      div(
        class = "file-info",
        icon("history", style = "margin-right: 8px;"),
        strong(selected$filename),
        " (z historii)"
      )
    })
  })
}

shinyApp(ui, server)