library(shiny)
library(bslib)
library(ellmer)
library(plotly)
library(shinychat)
library(ggplot2)


ui <- bslib::page_sidebar(
  sidebar = 
    chat_ui(
      "chat", 
      messages = "Ask me a question about a date. For example: what's today's date? Or, how many days ago was 1801?"
    ),
  card(
    card_header("A date"),
    textOutput("date")
  )
)

server <- function(input, output, session) {

  date_reactive <- reactiveVal()

  output$date <- renderText({ date_reactive() })

  chat <- ellmer::chat_openai(
    system_prompt = 
      "You are an assistant that helps the user with current, past, and future dates. 
      Use the tool `get_date()` to get today's date. 
      Use the tool `update_date()` to update the app to display a relevant date. 
      You should call `update_date()` whenever the user requests information about a date, including the current date."
  )
  
  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    chat_append("chat", stream)
  })

  #' Gets the current date
  #'
  #' @return The current date, as a Date object. 
  get_date <- function() {
    Sys.Date()
  }

  #' Displays a date in the app
  #' @param display_date A date, as a string, to display
  #'
  update_date <- function(display_date) {
    date_reactive(display_date)
  }

  chat$register_tool(tool(get_date, "Gets the user's current date."))

  chat$register_tool(
    tool(
      update_date, 
      "Updates the display to a date.",
      display_date = type_string("A date, as a string, to display. Supply the date in YYYY-MM-DD format unless otherwise requested.")
    )
  )

}

shinyApp(ui, server)


