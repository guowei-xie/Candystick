add_factor_MA <- function(df, tags) {
  ma_tags <-  tags[grep("日均线$", tags)]
  if(!length(ma_tags)) return(df)
  
  widths <- gsub("日均线", "", ma_tags) |> as.numeric()
  
  df <- arrange(df, desc(trade_date))
  
  if (length(widths)) {
    meta_ <- widths |>
      map(~ {
        str_glue("ma_{.x} = zoo::rollapply(close, width = {.x}, FUN = mean, align = 'left', fill = NA)")
      }) |>
      paste(collapse = ",")
    
    meta <- paste("df |> mutate(", meta_, ")")
    
    res <- eval(parse(text = meta)) |>
      mutate(across(where(is.numeric), ~ round(., 2)))
  }else{
    res <- df
  }
  return(res)
}

add_factor_Boll <- function(df, tags, n = 20, sd = 2, maType = "SMA") {
  boll_tags <-  tags[grep("Boll", tags)]
  if(!length(boll_tags)) return(df)
  
  df |>
    arrange(trade_date) |>
    mutate(
      BB = TTR::BBands(HLC = close, n = n, maType = maType, sd = sd),
      md_band = BB[, "mavg"],  
      up_band = BB[, "up"],     
      dn_band = BB[, "dn"]
    ) %>%
    select(-BB) |>
    arrange(desc(trade_date)) |>
    mutate(across(where(is.numeric), ~ round(., 2)))
}