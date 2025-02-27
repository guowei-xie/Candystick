trade_record <- function(direction, price, row){
  # 交易价格是否在允许范围
  allow <- price <= row$high & price >= row$low
  
  if(allow){
    res <- data.frame(
      train_id = row$train_id,
      trade_direc = direction,
      trade_price = price,
      ts_code = row$ts_code,
      trade_date = row$trade_date,
      create_time = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    )
  }else{
    res <- data.frame()
  }
  
  return(res)
}
