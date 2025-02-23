library(shiny)
library(shinythemes)
library(shinyWidgets)
library(shinyjs)
library(tidyverse)
library(config)
source("src/helper.R")
source("src/database.R")
source("src/custom.R")
source("src/factor.R")
source("ui/train_ui.R")
source("ui/battle_ui.R")
source("module/train_server.R")
source("module/battle_server.R")
source("global.R")

ui <- fluidPage(
  theme = shinytheme(cnf$theme),
  useShinyjs(), 
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