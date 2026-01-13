home_tab_ui <- function() {
  nav_panel(
    "Strona główna",
    div(
      class = "main-card",
      h2("Aplikacja do rozpoznawania dźwięków z użyciem CNN"),
      p(HTML(
        "Aby wygenerować spektogram i otrzymać predykcję klasy dźwięku, prześlij plik audio w formacie <strong>WAV</strong>."
      )),
    ),
  )
}
