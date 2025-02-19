train_server <- function(input, output, session) {
  .cnf <- config::get(config = "train")
  start_date <- format(
    Sys.Date() - lubridate::years(.cnf$recent_years), "%Y%m%d"
  )
  range_rows <- .cnf$recent_days + .cnf$train_days
  # Account --------------------------------------------------------------------
  user_id <- "default"
  # 账户信息
  account <- reactiveVal(get_user_account(user_id))
  
  
  
  # Data -----------------------------------------------------------------------
  # 随机基础行情数据
  change <- reactiveVal(0)
  stk_daily <- eventReactive(change(), {
    markets <- eval(parse(text = .cnf$market))

    stk_code <- basic |>
      filter(market %in% markets) |>
      pull(ts_code) %>%
      sample(1)

    daily_dat <- try_api(
      api,
      api_name = "daily",
      ts_code = skt_code
    )

    scope_rows <- daily_dat |>
      filter(trade_date >= start_date) |>
      nrow()

    if (scope_rows >= range_rows) {
      return(daily_dat)
    } else {
      change(change() + 1)
    }
  })

  # 股票因子计算
  fct_dat <- reactive({
    req(stk_daily())
    stk_code <- unique(stk_daily()$ts_code)

    stk_limit <- try_api(
      api,
      api_name = "stk_limit",
      ts_code = stk_code
    )
    
    stk_daily() |>
      left_join(basic, by = "ts_code") |>
      left_join(stk_limit, by = c("ts_code", "trade_date"))
      # 添加：因子指标
  })
  
  # 训练数据
  train_dat <- reactive({
    req(fct_dat())
    fct_dat() |>
      filter(trade_date >= start_date) |>
      random_range(n = range_rows)
  })
  
  
  # Step -----------------------------------------------------------------------
  # 计步器与开盘状态控制
  step_counter <- reactiveVal(0) 
  step_status <- reactiveVal("open") 
  observeEvent(step_counter(), {
    step <- step_counter()
    if(step %% 2) {
      step_status("open")
    }else{
      step_status("close")
    }
  })
  
  

  

 



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
