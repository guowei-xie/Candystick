library(shiny)
library(shinythemes)
library(shinyjs)
library(tidyverse)
library(config)
source("src/custom.R")
source("src/helper.R")
source("src/database.R")
source("ui/train_ui.R")
source("ui/battle_ui.R")
source("module/train_server.R")
source("module/battle_server.R")

cnf <- config::get()

api <- Tushare::pro_api(token = Sys.getenv("tushare_token"))

basic <- try_api(api, api_name = "stock_basic")

ui <- fluidPage(
  theme = shinytheme(cnf$theme),
  useShinyjs(), 
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$script(src = "scripts.js")
  ),
  
  navbarPage(
    title = cnf$title,
    tabPanel("训练", train_ui("train")),
    tabPanel("对战", battle_ui("battle"))
  )
)

server <- function(input, output, session) {
  callModule(train_server, "train")
  callModule(battle_server, "battle")
}

shinyApp(ui, server)