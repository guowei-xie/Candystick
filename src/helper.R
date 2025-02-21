try_api <- function(func, ...){
  res <- tryCatch(
    {
      func(...)
    },
    error = function(e) {
      message(paste("An error occurred:", e$message))
      return(data.frame())
    })
  
  return(res)
}

random_range <- function(df, n) {
  df <- arrange(df, desc(trade_date))
  total <- nrow(df)
  start <- sample(1:(total - n + 1), 1)
  range <- df[start:(start + n - 1), ]
  return(range)
}

conv_yml2tree <- function(file, key) {
  file <- "custom.yml"
  key <- "factor_indicator"
  yml <- yaml::yaml.load_file(file)
  
  yml[[key]] |>
    imap_dfr(~ tibble(
      keys = .y,
      vals = str_split(.x, ",")[[1]]
    )) |>
    create_tree()
}

