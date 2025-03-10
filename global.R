cnf <- config::get()

custom <- yaml::yaml.load_file("custom.yml")

api <- Tushare::pro_api(token = cnf$tushare_token)

basic <- try_api(api, api_name = "stock_basic")

