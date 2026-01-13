metric_card <- function(value, label, icon_name = NULL) {
  div(
    style = "text-align: center; padding: 1rem; background-color: #F9FAFB; border-radius: 8px;",
    div(style = "font-size: 2rem; color: #C47335; font-weight: 600;", value),
    div(style = "color: #6B7280; margin-top: 0.5rem;", label)
  )
}

info_section <- function(title, content, style = "") {
  div(
    class = "card",
    style = paste("padding: 1.5rem; margin-bottom: 1.5rem;", style),
    h5(title),
    content
  )
}

bullet_list <- function(items) {
  tags$ul(
    style = "color: #6B7280; line-height: 1.6; margin: 0; padding-left: 1.2rem;",
    lapply(items, function(item) tags$li(item))
  )
}

app_header <- function(title = "🎵 CNN Sound Classification") {
  div(
    style = "background-color: #FFFFFF; border-bottom: 1px solid #E5E7EB; padding: 1.5rem 2rem; margin-bottom: 2rem;",
    h2(style = "margin: 0; color: #2C2D30; font-weight: 600;", title)
  )
}

main_container <- function(...) {
  div(
    style = "max-width: 1400px; margin: 0 auto; padding: 0 2rem;",
    ...
  )
}