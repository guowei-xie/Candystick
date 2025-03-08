# 交易记录
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

# 单笔收益计算
trade_gains <- function(rcds){
  if(!nrow(rcds)) return(0)
  buy_rcds <- filter(rcds, trade_direc == "buy")
  sell_rcds <- filter(rcds, trade_direc == "sell")
  gains <- sell_rcds$trade_price / buy_rcds$trade_price - 1
  
  data.frame(
    buy_date = buy_rcds$trade_date,
    sell_date = sell_rcds$trade_date,
    gains = gains
  )
}
