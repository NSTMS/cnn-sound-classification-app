history_tab_ui <- function() {
  nav_panel(
    "Historia",
    div(
      style = "padding: 1.5rem;",
      h2(style = "margin-bottom: 1rem; color: #2C2D30;", "Historia analiz"),
      p(
        style = "color: #6B7280; margin-bottom: 1.5rem;",
        "Archiwum poprzednich analiz ścieżek dźwiękowych."
      ),
      DT::dataTableOutput("history_table")
    )
  )
}
