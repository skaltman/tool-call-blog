from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
import chatlas
from typing import List, Dict
from datetime import date
import os

SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]
CREDENTIALS_FILE = "credentials-demo.json"
TOKEN_FILE = "token.json"

def get_date() -> str:
    """
    Get the current date.

    Returns
    -------
    str
        The current date in "YYYY-MM-DD" format.
    """
    return date.today().isoformat()

def authenticate():
    creds = None

    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                CREDENTIALS_FILE,
                scopes=SCOPES
            )
            creds = flow.run_local_server(port=0)
            with open(TOKEN_FILE, "w") as token:
                token.write(creds.to_json())

    return creds

# def authenticate():
#     flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
#     return flow.run_local_server(port=0)

def build_calendar_service(creds):
    return build("calendar", "v3", credentials=creds)

def query_api(service, start_date, end_date):
    time_min = f"{start_date}T00:00:00Z"
    time_max = f"{end_date}T23:59:59Z"

    events = service.events().list(
        calendarId="primary",
        timeMin=time_min,
        timeMax=time_max,
        singleEvents=True,
        orderBy="startTime"
    ).execute().get("items", [])

    return [
        {
            "start": e["start"].get("dateTime", e["start"].get("date")),
            "summary": e.get("summary", "No title")
        }
        for e in events
    ]

def get_calendar_events(start_date: str, end_date: str) -> List[Dict[str, str]]:
    """
    Fetch Google Calendar events between two dates.

    Parameters
    ----------
    start_date : str
        The start date in "YYYY-MM-DD" format.
    end_date : str
        The end date in "YYYY-MM-DD" format.

    Returns
    -------
    List[dict]
        A list of events with 'start' and 'summary' fields.
    """
    creds = authenticate()
    service = build_calendar_service(creds)
    return query_api(service, start_date, end_date)


chat = chatlas.ChatAnthropic(system_prompt=open("prompt-calendar.md", "r").read())

chat.register_tool(get_calendar_events)
chat.register_tool(get_date)
chat.console()

