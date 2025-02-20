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
  sql <- str_glue(
    "SELECT * FROM user_account WHERE user_id = '{user_id}';"
  )
  sql_query(sql)
}
