model_tab_ui <- function() {
  nav_panel(
    "Opis modelu",
    div(
      style = "padding: 1.5rem;",
      class = "main-card",
      h2(
        style = "margin-bottom: 1rem; color: #2C2D30;",
        "Informacje o modelu CNN"
      ),
      info_section(
        "Proces treningu",
        tagList(
          p(
            style = "color: #6B7280; line-height: 1.6;",
            HTML(
              "Model został wytrenowany na zbiorze danych <strong>UrbanSound8K</strong>, który zawiera <strong>8732 próbki dźwiękowe</strong> przyporządkowane do <strong>10 klas.</strong>"
            ),
            HTML(
              "Zbiór danych został podzielony na zestaw treningowy<strong>(65% danych)</strong>, walidacyjny<strong>(25%)</strong> i ewaluacyjny<strong>(10%)</strong>."
            ),
          ),
        )
      ),
      info_section(
        "Metryki wydajności",
        div(
          style = "display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; margin-top: 1rem;",
          metric_card("85,53%", "Dokładność"),
          metric_card("gun_shot", "Najlepsza klasa"),
          metric_card("children_playing", "Najgorsza klasa"),
          metric_card("v1.0", "Wersja modelu")
        )
      ),
      info_section(
        "Wykres rozkładu dokładności rozpoznawania klas",
        img(
          src = "models/v1/accuracy.png",
          width = "90%",
          style = "margin: 0 auto;"
        )
      ),
      info_section(
        "Wykres macierzy pomyłek",
        img(
          src = "models/v1/mistakes_matrix.png",
          width = "90%",
          style = "margin: 0 auto;"
        )
      ),
      info_section(
        "Ocena modelu",
        tagList(
          p(
            style = "color: #6B7280; line-height: 1.6;",
            HTML(
              "Do trenowania modelu V1 użyłem całego zbioru <strong>UrbanSound8K</strong>(z zastosowaniem proprocji wymienionych wyżej) oraz <strong>50 epok treningowych</strong>. To połączenie dało zadowalające wyniki w postaci dokładności rzędu <strong>~85% dokładności</strong> na zbiorze testowym. Z utworzonych wykresów można wywnioskować, że model najlepiej rozpoznaje <strong>strzały z pistoletu</strong> (około 93% dokładności, co wydaje się logiczne, z uwagi na powtarzalność i głośność próbek), a najgorzej radzi sobie z rozpoznawaniem <strong>bawiących się dzieci</strong>(dokładność na poziomie ok. 73%, co może wynikać z charakterystyki próbek, jako mniej powtarzalnych i bardziej zróżnicowanych)."
            )
          ),
          br(),
          p(
            style = "color: #6B7280; line-height: 1.6;",
            HTML(
              "Co więcej, możemy zaobserować <strong>największy skok jakościowy modelu w okolicach 10-13 epoki</strong>, a po 30 epoce skok ten był już minimalny(z 83.85% do 84.54%), co sugeruje, że model osiągnął swój limit przy obecnej architekturze."
            )
          )
        )
      )
    )
  )
}
