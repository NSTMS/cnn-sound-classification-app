footer <- function() {
  div(
    style = "
      background-color: #F9FAFB;
      border-top: 1px solid #E5E7EB;
      padding: 2rem;
      margin-top: 3rem;
      text-align: center;
    ",
    div(
      style = "color: #6B7280; font-size: 0.875rem; line-height: 1.8;",

      div(
        style = "margin-bottom: 0.75rem;",
        tags$i(class = "fab fa-github github-icon"),
        tags$a(
          href = "https://github.com/NSTMS/cnn-sound-classification-app",
          target = "_blank",
          class = "footer-link",
          "GitHub"
        )
      ),

      # Wiersz z informacjami o autorze i prawach autorskich
      div(
        HTML(paste0(
          "©2026 ",
          "<strong>NSTMS</strong>",
          " <span class='footer-divider'>•</span> ",
          "CNN Sound Classification App",
          " <span class='footer-divider'>•</span> ",
          "Zbudowano z ",
          "<span style='color: #C47335;'>❤️</span>",
          " przy użyciu Shiny"
        ))
      ),

      # Wiersz z dodatkowymi informacjami
      div(
        style = "margin-top: 0.75rem; font-size: 0.8rem; color: #9CA3AF;",
        HTML(paste0(
          " <span class='footer-divider'>•</span> ",
          "Jan Idzi",
          " <span class='footer-divider'>•</span> "
        ))
      )
    )
  )
}
