sidebar_panel_ui <- function() {
  column(
    width = 3,
    div(
      class = "card",
      style = "padding: 1.5rem;",
      div(
        class = "file-input-wrapper",
        fileInput(
          "audio_file",
          NULL,
          accept = c(".wav"),
          buttonLabel = "Wybierz plik",
          placeholder = "Przeciągnij lub wybierz plik"
        )
      ),

      actionButton(
        "upload_audio",
        "Analizuj dźwięk",
        class = "btn-primary w-100",
        style = "margin-top: 1rem;"
      ),

      hr(style = "margin: 2rem 0;"),

      div(
        style = "color: #6B7280; font-size: 0.875rem; line-height: 1.6;",
        p(strong("Obsługiwane formaty:")),
        p("• WAV"),
        p(strong("Rozpoznawane klasy:")),
        p(paste("•", paste(CLASS_LABELS, collapse = ", ")))
      )
    )
  )
}
