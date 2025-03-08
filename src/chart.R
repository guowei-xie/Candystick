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

