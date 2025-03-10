train_ui <- function(id) {
  ns <- NS(id)

  fluidPage(
    mainPanel(
      br(),
      plotOutput(ns("train_chart")),
      uiOutput(ns("factor_charts"))
    ),
    sidebarPanel(
      # Account info -----------------------------------------------------------
      fluidRow(
        column(
          width = 4,
          uiOutput(ns("asset"))
        ),
        column(
          width = 4,
          uiOutput(ns("gains"))
        ),
        column(
          width = 4,
          uiOutput(ns("nums"))
        )
      ),
      hr(),
      # Step counter -----------------------------------------------------------
      textOutput(ns("remaining_days")),
      
      # Action buttons ---------------------------------------------------------
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
            icon = icon("exchange-alt")
          )
        ),
        column(
          width = 5,
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
        icon = icon("play-circle")
      ),
      
      # Price tags -------------------------------------------------------------
      radioGroupButtons(
        inputId = ns("price_tag"),
        label = "快捷填价",
        choices = "待选用"
      ),

      # Configure buttons ------------------------------------------------------
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
            choices = conv_yml2tree(custom, "factor_indicator"),
            returnValue = "text",
            closeDepth = 0,
            selected = str_split(custom$default_selected$factor_indicator, ",")[[1]]
          ),
          treeInput(
            inputId = ns("price_config"),
            label = "选用填价标签:",
            choices = conv_yml2tree(custom, "price_tag"),
            returnValue = "text",
            closeDepth = 0,
            selected = str_split(custom$default_selected$price_tag, ",")[[1]]
          )
        )
      )
    )
  )
}
