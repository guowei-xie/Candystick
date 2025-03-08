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


conv_yml2tree <- function(yml, key) {
  yml[[key]] |>
    imap_dfr(~ tibble(
      keys = .y,
      vals = str_split(.x, ",")[[1]]
    )) |>
    create_tree()
}


