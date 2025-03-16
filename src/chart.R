# 基础K线图
candle_chart <- function(df){
  plt_df <- df |>
    mutate(
      candle_lower = pmin(open, close),
      candle_upper = pmax(open, close),
      candle_middle = (candle_lower + candle_upper) / 2,
      candle_max = high,
      candle_min = low,
      direction = ifelse(
        open < close | (open == close & close >= pre_close),
        "up",
        "down"
      ),
      direction = factor(direction, levels = c("up", "down"))
    )  
  
  plt_df |> 
    ggplot(aes(x = trade_date)) +
    geom_boxplot(
      aes(
        lower = candle_lower,
        middle = candle_middle,
        upper = candle_upper,
        ymin = candle_min,
        ymax = candle_max,
        col = direction,
        fill = direction
      ),
      stat = "identity",
      size = .3,
      width = .5
    ) +
    scale_color_manual(values = c("up" = "#f03b20", "down" = "#31a354")) +
    scale_fill_manual(values = c("up" = "#f03b20", "down" = "#31a354")) +
    theme(
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_blank(),
      legend.position = "none",
      panel.border = element_rect(color = "black", size = 1, fill = NA),
      panel.background = element_rect(fill = "white")
    ) +
    labs(x = "", y = "")
}

# 添加横线
add_price_line <- function(plt, price){
  plt +
    geom_hline(
      yintercept = price,
      col = "darkgrey",
      lty = 4,
      alpha = .5
    )
}


# 添加MA线
add_ma_lines <- function(plt, tags){
  ma_tags <-  tags[grep("日均线$", tags)]
  if(!length(ma_tags)) return(plt)

  ma_cols <- unname(custom$colname_mapping[ma_tags]) |> unlist()
  l_colors <- unname(custom$ma_color[ma_tags]) |> unlist()
  
  l_code_str <- "geom_line(aes(y = {ma_col}, group = 1), col = '{l_color}')"
  
  l_code <- map2(ma_cols, l_colors, ~{
    ma_col <- .x
    l_color <- .y
    str_glue(l_code_str)
  }) |>
    paste(collapse = "+")
  
  expr_str <- paste0("plt + ", l_code)
  
  eval(parse(text = expr_str))
}


# 添加Boll线
add_boll_lines <- function(plt, tags){
  boll_tags <-  tags[grep("Boll", tags)]
  boll_tags <- boll_tags[!str_detect(boll_tags, "相关")]
  
  if(!length(boll_tags)) return(plt)
  
  boll_cols <- unname(custom$colname_mapping[boll_tags]) |> unlist()
  
  l_code_str <- "geom_line(aes(y = {boll_col}, group = 1), lty = 4)"
  
  l_code <- map(boll_cols, ~{
    boll_col <- .x
    str_glue(l_code_str)
  }) |>
    paste(collapse = "+")
  
  expr_str <- paste0("plt + ", l_code)
  
  eval(parse(text = expr_str))
}
