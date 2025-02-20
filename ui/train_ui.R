train_ui <- function(id) {
  ns <- NS(id)

  fluidPage(
    mainPanel(
      actionButton(
        inputId = ns("config_btn"),
        label = tags$small("自定义配置"),
        icon = icon("sliders-h"),
        style = "background-color: transparent; border: none; color: grey"
      ),
      
      hidden(
        div(
          id = ns("config_div"),
          br(),
          treeInput(
            inputId = ns("fct_config"),
            label = "选用因子指标:",
            choices = create_tree(cities),
            returnValue = "text",
            closeDepth = 0,
            selected = NULL
          ),
          treeInput(
            inputId = ns("price_config"),
            label = "选用快捷填价:",
            choices = create_tree(cities),
            returnValue = "text",
            closeDepth = 0,
            selected = NULL
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
          width = 6,
          uiOutput(ns("asset"))
        ),
        column(
          width = 6,
          uiOutput(ns("gains"))
        )
      ),
      hr(),
      
      radioGroupButtons(
        inputId = ns("price_tag"),
        label = "快捷填价",
        choices = list("暂无" = 0)
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
              value = NULL,
              min = 0
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
