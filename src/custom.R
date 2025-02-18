tagSelectorInput <- function(inputId, label, choices, multi = FALSE) {
  tags$div(
    class = "form-group shiny-input-container",
    tags$label(label, `for` = inputId),
    div(
      id = inputId, class = ifelse(multi, "tag-selector multi", "tag-selector"),
      lapply(seq_along(choices), function(i) {
        tags$span(class = "tag", `data-value` = names(choices)[i], choices[i])
      })
    )
  )
}

updateTagSelectorInput <- function(session, inputId, choices) {
  new_tags <- paste(sapply(seq_along(choices), function(i) {
    as.character(tags$span(class = "tag", `data-value` = names(choices)[i], choices[i]))
  }), collapse = "")

  session$sendCustomMessage("updateTagSelector", list(inputId = inputId, tags = new_tags))
}