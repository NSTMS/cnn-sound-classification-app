source("app/components/ui_components.R")
source("app/components/ui_sidebar.R")
source("app/components/ui_home_tab.R")
source("app/components/ui_spectrogram_tab.R")
source("app/components/ui_prediction_tab.R")
source("app/components/ui_history_tab.R")
source("app/components/ui_model_tab.R")

ui <- fluidPage(
  theme = theme,
  tags$head(tags$style(HTML(css_))),
  shinyFeedback::useShinyFeedback(),
  
  app_header("CNN Sound Classification App"),
  
  main_container(
    fluidRow(
      sidebar_panel_ui(),
      column(
        width = 9,
        navset_card_tab(
          id = "main_tabs",
          home_tab_ui(),
          spectrogram_tab_ui(),
          prediction_tab_ui(),
          history_tab_ui(),
          model_tab_ui()
        )
      )
    )
  )
)