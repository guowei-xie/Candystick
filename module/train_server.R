train_server <- function(input, output, session) {
  .cnf <- config::get(config = "train")
  ns <- session$ns
  user_id <- "default"
  # Get account info -----------------------------------------------------------
  account_info <- reactive({
    account <- get_user_account(user_id)
    if(!nrow(account)){
      account <- data.frame(
        user_id = user_id,
        initial = .cnf$initial,
        asset = .cnf$initial,
        nums = 0,
        update_time = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
      )
    }
    return(account)
  })
  
  # asset <- reactiveVal(account_info()$asset)
  
  # Data processing ------------------------------------------------------------
  start_date <- format(Sys.Date() - lubridate::years(.cnf$recent_years), "%Y%m%d")
  range_rows <- .cnf$recent_days + .cnf$train_days
  change <- reactiveVal(0)
  # 随机基础行情数据
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
      left_join(stk_limit, by = c("ts_code", "trade_date")) |>
      # 添加：因子指标
      # 筛选：波段范围
      filter(trade_date >= start_date) |>
      random_range(n = range_rows)
      
  })
  
  # Dynamic control ------------------------------------------------------------
  # 计步状态
  step_counter <- reactiveVal(0) 
  step_status <- reactiveVal("open") 
  observeEvent(step_counter(), {
    step <- step_counter()
    if(step %% 1) {
      step_status("open")
    }else{
      step_status("close")
    }
  })
  
  # 移动窗口数据
  train_dat <- reactive({
    req(fct_dat())
    req(step_counter())
    df <- fct_dat()
    mv <- floor(step_counter())
    start <- .cnf$train_days - mv
    end <- .cnf$train_days + .cnf$recent_days - mv
    
    if(start > 0) {
      return(df[start:end, ])
    }
  })
  
  # Action observe -------------------------------------------------------------
  # 自定义配置面板
  observeEvent(input$config_btn, {
    shinyjs::toggle("config_div")
  })
  
  # 快捷填价标签配置
  observeEvent(input$price_config, {
    tags <- input$price_config
    updateRadioGroupButtons(
      session,
      inputId = "price_tag",
      choices = tags[!str_detect(tags, "相关")]
    )
  })
  
  # # 标签查价并填写
  # observeEvent(input$price_tag, {
  #   
  #   print(input$price_tag)
  #   updateNumericInput(
  #     session, 
  #     inputId = "price",
  #     value = input$price_tag
  #   )
  # })
  

 



  

  output$asset <- renderUI({
    asset <- format(100000, big.mark = ",", scientific = FALSE)
    accountDisplay("总资产", asset)
  })

  output$gains <- renderUI({
    gains <- "10%"
    color <- "red"
    accountDisplay("累计收益", gains, color)
  })
  
  output$nums <- renderUI({
    nums <- "10000"
    accountDisplay("训练次数", nums)
  })
}
