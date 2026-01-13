prediction_tab_ui <- function() {
  nav_panel(
    "Predykcja",
    div(
      style = "padding: 1.5rem;",
      h2(
        style = "margin-bottom: 1.5rem; color: #2C2D30;",
        "Wyniki klasyfikacji"
      ),
      uiOutput("prediction_cards"),
      hr(style = "margin: 2rem 0;"),
      plotOutput("prediction_chart", height = "450px")
    )
  )
}
