accountDisplay <- function(label, value, color = "black", fontSize = "24px", fontWeight = "bold") {
  tags$div(
    style = "text-align: center;",
    tags$small(label),
    tags$br(),
    tags$span(
      style = paste0(
        "font-size: ", fontSize, ";",
        "font-weight:", fontWeight, ";",
        "color: ", color, ";"
      ),
      value
    )
  )
}