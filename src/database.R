sql_query <- function(sql){
  cnf <- config::get(config = "database")
  
  db <- dbConnect(
    SQLite(),
    dbname = paste0(cnf$path, cnf$name)
  )
  
  res <- dbGetQuery(db, sql)
  dbDisconnect(db)
  return(res)
}

get_user_account <- function(user_id){
  cnf <- config::get(config = "database")
  
  sql <- str_glue(
    "SELECT * FROM user_account WHERE user_id = '{user_id}' ORDER BY update_time DESC LIMIT 1;"
  )
  res <- sql_query(sql)
  
  if(!nrow(res)){
    res <- data.frame(
      user_id = user_id,
      initial = cnf$initial,
      asset = cnf$initial,
      nums = 0,
      update_time = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    )
  }
  return(res)
}

write_df_to_db <- function(df, tbl, type="append"){
  cnf <- config::get(config = "database")
  
  db <- dbConnect(
    SQLite(),
    dbname = paste0(cnf$path, cnf$name)
  )
  
  if(type == "append"){
    dbWriteTable(db, tbl, df, append = TRUE)
  }
  
  if(type == "overwrite"){
    dbWriteTable(db, tbl, df, overwrite = TRUE)
  }
  
  dbDisconnect(db)
}