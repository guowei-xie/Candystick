library(RSQLite)
library(config)
cnf <- config::get(config = "database")

# Initialize the database path
if (!dir.exists(cnf$path)) {
  dir.create(cnf$path)
}

# Initialize database & table
db <- dbConnect(SQLite(), dbname = paste0(cnf$path, cnf$name))

tbl_exists <- function(db, tbl_name) {
  query <- paste0("SELECT name FROM sqlite_master WHERE type='table' AND name='", tbl_name, "'")
  result <- dbGetQuery(db, query)
  return(nrow(result) > 0)
}

## Initialize user info table
if (!tbl_exists(db, "user_info")) {
  dbExecute(db, "
  CREATE TABLE user_info (
    user_id TEXT PRIMARY KEY,
    user_name TEXT,
    create_time TEXT,
    update_time TEXT
  )")
  message("Initialize user info table！\n")
}

# Initialize user account table
if (!tbl_exists(db, "user_account")) {
  dbExecute(db, "
  CREATE TABLE user_account (
    user_id TEXT PRIMARY KEY,
    initial REAL,
    asset REAL,
    nums REAL,
    update_time TEXT,
    FOREIGN KEY(user_id) REFERENCES user_info(user_id)
  )")
  message("Initialize user account table！\n")
}

dbDisconnect(db)