library(shiny)
library(shinythemes)
library(shinyjs)
library(tidyverse)
library(config)

source("ui/train_ui.R")
source("ui/battle_ui.R")
source("module/train_server.R")
source("module/battle_server.R")

cnf <- config::get()

ui <- fluidPage(
  theme = shinytheme(cnf$theme),
  useShinyjs(), 
  # tags$head(
  #   tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
  #   tags$script(src = "scripts.js")
  # ),
  
  navbarPage(
    title = cnf$title,
    tabPanel("Train", train_ui("train")),
    tabPanel("Battle", battle_ui("battle"))
  )
)

server <- function(input, output, session) {
  callModule(train_server, "train")
  callModule(battle_server, "battle")
}

shinyApp(ui, server)