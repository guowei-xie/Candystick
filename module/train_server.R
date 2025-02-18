train_server <- function(input, output, session) {
  
  observeEvent(input$config_btn, {
    shinyjs::toggle("config_div")
  })

  output$asset <- renderUI({
    asset <- format(100000, big.mark = ",", scientific = FALSE)
    accountDisplay("总资产", asset)
  })

  output$gains <- renderUI({
    gains <- "10%"
    color <- "red"
    accountDisplay("累计收益", gains, color)
  })
}
