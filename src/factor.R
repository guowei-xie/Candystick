add_factor_MA <- function(df, widths = c(5, 10, 20, 30, 60, 90, 120, 180, 360)) {
  df <- arrange(df, desc(trade_date))

  if (length(widths)) {
    meta_ <- widths |>
      map(~ {
        str_glue("ma_{.x} = zoo::rollapply(close, width = {.x}, FUN = mean, align = 'left', fill = NA)")
      }) |>
      paste(collapse = ",")
    
    meta <- paste("df |> mutate(", meta_, ")")
    
    res <- eval(parse(text = meta))
  }else{
    res <- df
  }
  return(res)
}

add_factor_Boll <- function(df, n = 20, sd = 2, maType = "SMA") {
  df |>
    arrange(trade_date) |>
    mutate(
      BB = TTR::BBands(HLC = close, n = n, maType = maType, sd = sd),
      md_band = BB[, "mavg"],  
      up_band = BB[, "up"],     
      dn_band = BB[, "dn"]
    ) %>%
    select(-BB) |>
    arrange(desc(trade_date)) |> view()
}
