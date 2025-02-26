train_server <- function(input, output, session) {
  ns <- session$ns
  .cnf <- config::get(config = "train")
  user_id <- "default"
  # Get account info -----------------------------------------------------------
  account_info <- reactive({
    account <- get_user_account(user_id)
    if (!nrow(account)) {
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
      ts_code = stk_code
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
    train_id <- uuid::UUIDgenerate()

    stk_limit <- try_api(
      api,
      api_name = "stk_limit",
      ts_code = stk_code
    )

    stk_daily() |>
      mutate(train_id = train_id) |>
      left_join(basic, by = "ts_code") |>
      left_join(stk_limit, by = c("ts_code", "trade_date")) |>
      # 添加：因子指标
      add_factor_MA() |>
      add_factor_Boll() |>
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
    if (step %% 1 == 0) {
      step_status("open")
    } else {
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

    if (start > 0) {
      rng_df <- df[start:end, ]

      # 开盘时，当日因子以开盘价计算
      if (step_status() == "open") {
        rng_df[1, "close"] <- rng_df[1, "open"]

        row <- rng_df |>
          add_factor_MA() |>
          add_factor_Boll() |>
          head(1)

        res <- rbind(row, rng_df[-1, ])
      } else {
        res <- rng_df
      }
      return(res)
    }
  })

  # Custom configuration -------------------------------------------------------
  # 自定义配置面板
  observeEvent(input$config_btn, {
    shinyjs::toggle("config_div")
  })

  # 快捷填价标签配置
  observeEvent(c(input$price_config, step_status()), {
    if (step_status() == "open") {
      tags <- input$price_config
    } else {
      # 收盘时只能填写“收盘价”
      tags <- "今日收盘价"
    }

    updateRadioGroupButtons(
      session,
      inputId = "price_tag",
      choices = tags[!str_detect(tags, "相关")]
    )
  })

  # Fill in the price ----------------------------------------------------------
  # 标签填价
  observeEvent(input$price_tag, {
    row <- head(train_dat(), 1)
    col <- pluck(custom$colname_mapping, input$price_tag)

    if (!is.null(col)) {
      updateNumericInput(
        session,
        inputId = "price",
        value = row[[col]]
      )
    }
  })

  # 填价范围限制
  observeEvent(step_status(), {
    row <- head(train_dat(), 1)

    # 收盘时只允许填写收盘价
    if (step_status() == "close") {
      max_price <- row$close
      min_price <- row$close
    } else {
      max_price <- row$up_limit
      min_price <- row$down_limit
    }

    updateNumericInput(
      session,
      inputId = "price",
      max = max_price,
      min = min_price,
    )
  })

  # 价格步幅限制
  observeEvent(train_dat(), {
    row <- head(train_dat(), 1)

    updateNumericInput(
      session,
      inputId = "price",
      step = round(row$pre_close * 0.001, 2)
    )
  })

  # Trading or waiting ---------------------------------------------------------
  # 观望
  observeEvent(input$wait, {
    step_counter(step_counter() + 0.5)
  })

  # 交易
  holding <- reactiveVal(0)
  records <- reactiveVal(data.frame())
  observeEvent(input$trade, {
    req(input$price)
    price <- input$price
    row <- head(train_dat(), 1)
    direction <- ifelse(holding(), "sell", "buy")
    
    res <- trade_record(direction, price, row)
    
    # 交易记录和持仓状态
    if(nrow(res)){
      records(bind_rows(records(), res))
      holding(as.numeric(direction == "buy"))
    }
    
    # 前进步数
    if(step_status() == "open"){
      # 开盘状态
      if(nrow(res)) {
        # 交易失败，前进0.5
        step_counter(step_counter() + 0.5)
      }else{
        # 交易成功，前进1
        step_counter(step_counter() + 1)
      }
    }
    
    if(step_status() == "close"){
      # 收盘状态
      # 交易成功与否，前进0.5
      step_counter(step_counter() + 0.5)
    }
    
    print(records())
  })

  
  # Button styles --------------------------------------------------------------
  # 按钮样式控制
  observe({
    req(holding(), step_status())

    if (!holding()) {
      wait_label <- "空仓观望"
      if (step_status() == "open") {
        trd_label <- "条件价买"
        new_class <- "btn-buy-conditional"
      } else {
        trd_label <- "收盘价买"
        new_class <- "btn-buy-close"
      }
    } else {
      wait_label <- "持仓观望"
      if (step_status() == "open") {
        trd_label <- "条件价卖"
        new_class <- "btn-sell-conditional"
      } else {
        trd_label <- "收盘价卖"
        new_class <- "btn-sell-close"
      }
    }

    btn_class <- c(
      "btn-buy-conditional", "btn-buy-close",
      "btn-sell-conditional", "btn-sell-close"
    )
    removeClass("trade", btn_class)
    addClass(id = "trade", class = new_class)

    updateActionButton(session, "trade", label = trd_label)
    updateActionButton(session, "wait", label = wait_label)
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

  output$nums <- renderUI({
    nums <- "10000"
    accountDisplay("训练次数", nums)
  })
}
