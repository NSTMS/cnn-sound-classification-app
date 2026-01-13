spectrogram_tab_ui <- function() {
  nav_panel(
    "Spektrogram",
    div(
      style = "padding: 1.5rem;",
      h2(style = "margin-bottom: 1rem; color: #2C2D30;", "Mel-Spektrogram"),
      p(
        style = "color: #6B7280; margin-bottom: 1.5rem;",
        "Reprezentacja resamplowanej ścieżki dźwiękowej w formie mel-spektogramu."
      ),
      plotOutput("spectrogram_plot", height = "500px")
    )
  )
}
