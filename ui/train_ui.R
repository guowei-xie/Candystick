train_ui <- function(id) {
  ns <- NS(id)
  
  fluidPage(
    mainPanel(
      actionButton(
        inputId = ns("config_btn"), 
        label = tags$small("指标配置"),
        icon = icon("sliders-h"), 
        style = "background-color: transparent; border: none; color: grey"
      ),
      
      hidden(
        div(
          id = ns("config_div"),
          br(),
          checkboxGroupInput(
            inputId = ns("MA_config"),  # 注意：使用 ns() 包装 inputId
            label = "MA：",
            choices = c("MA5", "MA10", "MA20", "MA30", "MA60", "MA90", "MA120", "MA180"),
            selected = c("MA5", "MA10", "MA20", "MA30"),
            inline = TRUE
          )
        ),
        hr()
      ),
      br(),
      plotOutput(ns("train_chart")),
      uiOutput(ns("factor_charts"))
    ),
    
    sidebarPanel(
      fluidRow(
        column(
          width = 4,
          uiOutput(ns("asset"))
        ),
        column(
          width = 4,
          uiOutput(ns("profit")) 
        ),
        column(
          width = 4,
          uiOutput(ns("gains")) 
        )
      ),
      br(),
      hr(),
      
      tagSelectorInput(
        inputId = ns("price_tag"),
        label = "快捷填价",
        choices = c("MA5", "MA10", "Boll上轨", "Boll下轨")
      ),
      
      fluidRow(
        style = "display: flex; align-items: center;",
        column(
          width = 4,
          actionButton(
            inputId = ns("wait"),
            label = "观望",
            width = "100%",
            icon = icon("eye"), 
            style = "background-color: #f8f9fa; border: 1px solid #ccc;"
          )
        ),
        column(
          width = 5,
          actionButton(
            inputId = ns("trade"),
            label = "交易",
            width = "100%",
            icon = icon("exchange-alt"),
            style = "background-color: red; color: white; border: none;"
          )
        ),
        column(
          width = 3,
          div(
            style = "margin-top: -10px;", 
            numericInput(
              inputId = ns("price"),
              label = tags$small("价格"),
              value = NULL
            )
          )
        )
      ),
      br(),
      actionButton(
        inputId = ns("continue"),
        label = "继续训练",
        width = "100%",
        style = "display: none;",
        icon = icon("play-circle")
      )
    )
  )
}