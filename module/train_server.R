train_server <- function(input, output, session) {
  ns <- session$ns
  .cnf <- config::get(config = "train")
  user_id <- "default"
  account <- get_user_account(user_id)
  print(account)

  # Data processing ------------------------------------------------------------
  start_date <- format(Sys.Date() - lubridate::years(.cnf$recent_years), "%Y%m%d")
  range_rows <- .cnf$recent_days + .cnf$train_days
  change <- reactiveVal(0)
  # 随机个股基础数据
  stk_daily <- eventReactive(change(), {
    train_id <- uuid::UUIDgenerate() # 训练id
    markets <- eval(parse(text = .cnf$market)) # 市场范围

    # 个股代码
    stk_code <- basic |>
      filter(market %in% markets) |>
      pull(ts_code) %>%
      sample(1)

    # 涨停数据
    stk_limit <- try_api(
      api,
      api_name = "stk_limit",
      ts_code = stk_code
    )

    # 个股日线行情数据
    daily_dat <- try_api(
      api,
      api_name = "daily",
      ts_code = stk_code
    )

    scope_rows <- daily_dat |>
      filter(trade_date >= start_date) |>
      nrow()

    # 当数据行数是否满足训练窗口需求
    if (scope_rows >= range_rows) {
      # 满足时，返回个股的完整数据
      res <- daily_dat |>
        left_join(basic, by = "ts_code") |>
        left_join(stk_limit, by = c("ts_code", "trade_date")) |>
        mutate(train_id = train_id)
      return(res)
    } else {
      # 不满足时，换股
      change(change() + 1)
    }
  })

  # 随机起始点（用于抽取训练窗口数据）
  rdm_start <- reactive({
    req(stk_daily())

    total <- stk_daily() |>
      filter(trade_date >= start_date) |>
      nrow()

    start <- sample((range_rows + 1):total, 1)
    return(start)
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

  # 动态训练窗口与指标数据
  train_dat <- reactive({
    req(stk_daily())
    req(rdm_start())

    df <- stk_daily()
    step_n <- floor(step_counter()) # 已进行步数
    left_idx <- rdm_start() - step_n # 窗口左边界
    right_idx <- left_idx - .cnf$recent_days # 窗口右边界

    # 防止右边界溢出
    req(step_n <= .cnf$train_days)

    # 数据截断到当前步数位置
    df <- df[right_idx:nrow(df), ]

    # 当步数为“开盘”时，避免引入未来价格
    if (step_status() == "open") {
      future_cols <- c("close", "high", "low")
      df[1, future_cols] <- df[1, "open"]
    }

    # 计算因子指标
    df <- df |>
      add_factor_MA() |>
      add_factor_Boll()

    res <- df[1:.cnf$recent_days, ]

    return(res)
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
  observeEvent(c(input$price_tag, train_dat()), {
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
    if (nrow(res)) {
      records(bind_rows(records(), res))
      holding(as.numeric(direction == "buy"))
    }

    # 前进步数
    if (step_status() == "open") {
      # 开盘状态
      if (!nrow(res)) {
        # 交易失败，前进0.5
        step_counter(step_counter() + 0.5)
      } else {
        # 交易成功，前进1
        step_counter(step_counter() + 1)
      }
    }

    if (step_status() == "close") {
      # 收盘状态
      # 交易成功与否，前进0.5
      step_counter(step_counter() + 0.5)
    }
  })

  # 继续训练
  observeEvent(input$continue, {
    change(change() + 1)
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



  # Charts ---------------------------------------------------------------------
  # 训练图
  train_chart <- reactive({
    req(train_dat())
    req(input$price)

    train_dat() |>
      candle_chart() |>
      add_price_line(input$price)
  })

  # Account changes ------------------------------------------------------------
  # 计算单笔收益（含持仓中收益）
  gains <- reactive({
    if (!nrow(records())) {
      return(data.frame())
    }

    rcds <- select(records(), trade_direc, trade_price, trade_date)

    if (tail(rcds, 1)$trade_direc == "sell") {
      # 已清仓收益
      gains <- trade_gains(rcds)
    } else {
      # 持仓中收益
      curr <- head(train_dat(), 1) # 当前
      gains <- rbind(
        rcds,
        data.frame(
          trade_direc = "sell",
          trade_price = curr$close,
          trade_date = curr$trade_date
        )
      ) |>
        trade_gains()
    }

    return(gains)
  })

  # 资产变动
  init_asset <- reactiveVal(account$asset)
  asset <- eventReactive(gains(), {
    if (nrow(gains())) {
      asset <- init_asset() * prod(1 + gains()$gains)
    } else {
      asset <- init_asset()
    }
    return(asset)
  })

  # End of training ------------------------------------------------------------
  # 训练结束状态/次数
  end_of_training <- reactiveVal(FALSE)
  train_nums <- reactiveVal(account$nums)
  # 更新训练结束状态
  observe({
    req(step_counter())
    if (step_counter() > .cnf$train_days) {
      end_of_training(TRUE)
    } else {
      end_of_training(FALSE)
    }
  })

  # 训练结束时强制平仓/数据落库/状态重置
  observeEvent(end_of_training(), {
    req(end_of_training() == TRUE)
    row <- head(train_dat(), 1)
    if (holding()) {
      res <- trade_record("sell", row$close, row)
      records(bind_rows(records(), res))
    }

    # 训练记录落库
    data.frame(
      user_id = user_id,
      train_id = row$train_id,
      ts_code = row$ts_code,
      start_date = start_date,
      rdm_start = rdm_start(),
      train_days = .cnf$train_days,
      recent_days = .cnf$recent_days,
      recent_years = .cnf$recent_years,
      create_time = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    ) |>
      write_df_to_db("train_records")

    # 训练次数+1
    train_nums(train_nums() + 1)

    # 账户变动落库
    data.frame(
      user_id = account$user_id,
      initial = account$initial,
      asset = asset(),
      nums = train_nums(),
      update_time = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    ) |>
      write_df_to_db("user_account")

    # 账户初始资金更新
    init_asset(asset())

    # 交易记录落库
    write_df_to_db(records(), "trade_records")
    # 交易记录重置
    records(data.frame())

    # 持仓状态重置
    holding(0)
  })


  # 继续训练按钮事件
  observeEvent(input$continue, {
    end_of_training(FALSE)
    step_counter(0)
    change(change() + 1)
  })

  # 隐藏交易按钮/展示继续训练按钮
  observeEvent(end_of_training(), {
    if (end_of_training()) {
      shinyjs::hide("price")
      shinyjs::hide("price_tag")
      shinyjs::hide("trade")
      shinyjs::hide("wait")
      shinyjs::show("continue")
    } else {
      shinyjs::hide("continue")
      shinyjs::show("price")
      shinyjs::show("price_tag")
      shinyjs::show("trade")
      shinyjs::show("wait")
    }
  })


  # Render output --------------------------------------------------------------
  output$asset <- renderUI({
    asset <- format(asset(), big.mark = ",", scientific = FALSE)
    accountDisplay("总资产", asset)
  })

  output$gains <- renderUI({
    gains <- round(asset() / account$initial - 1, 4)
    gains <- paste0(gains * 100, "%")

    if (gains >= 0) {
      color <- "red"
    } else {
      color <- "green"
    }
    accountDisplay("累计收益", gains, color)
  })

  output$nums <- renderUI({
    accountDisplay("训练次数", train_nums())
  })

  output$remaining_days <- renderText({
    paste0("剩余K线：", .cnf$train_days - floor(step_counter()))
  })

  output$train_chart <- renderPlot({
    train_chart()
  })
}
