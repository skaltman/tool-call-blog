library(httr)
library(jsonlite)
library(gargle)
library(dplyr)
library(tibble)
library(ellmer)

USER_EMAIL <- "tool.call.demo@gmail.com"

calendar_authenticate <- function() {
  my_app <- gargle_oauth_client_from_json("credentials-demo.json")

  token_fetch(
    scopes = "https://www.googleapis.com/auth/calendar.readonly",
    app = my_app,
    email = USER_EMAIL,
    cache = ".secrets"
  )
}

query_api <- function(start_date, end_date, token) {
  res <-
    GET(
      url = "https://www.googleapis.com/calendar/v3/calendars/primary/events",
      config(token = token),
      query = list(
        timeMin = glue::glue("{start_date}T00:00:00Z"),
        timeMax = glue::glue("{end_date}T23:59:59Z"),
        singleEvents = "true",
        orderBy = "startTime"
      )
    )

  content(res, as = "parsed", simplifyVector = TRUE)$items
}

#' Gets the calendar events between start_date and end_date
#'
#' @param start_date Start date, in YYYY-MM-DD format.
#' @param end_date End date, in YYYY-MM-DD format.
#' @return A tibble containing the calendar events in the date range. 
get_calendar_events <- function(start_date, end_date) {

  token <- calendar_authenticate()

  events <- query_api(start_date, end_date, token)

  if (length(events) == 0) { return(tibble()) }

  tibble(
    id = events$id,
    summary = events$summary,
    start = events$start$dateTime,
    end =  events$end$dateTime
  )
}

#' Gets the current date
#'
#' @return The current date, as a Date object. 
get_date <- function() {
  Sys.Date()
}

chat <- chat_claude(system_prompt = readLines("prompt-calendar.md"))

chat$register_tool(tool(
  get_calendar_events,
  "Fetches calendar events between a specified start and end date.",
  start_date = type_string(
       "The start date from which to fetch calendar events. It should be a string representing the 
date in the format YYYY-MM-DD.",
       required = TRUE
  ),
  end_date = type_string(
       "The end date up to which to fetch calendar events. It should be a string representing the 
date in the format YYYY-MM-DD.",
       required = TRUE
  )
))

chat$register_tool(tool(get_date, "Gets the user's current date."))


live_console(chat)
