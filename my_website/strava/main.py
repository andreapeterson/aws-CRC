import os
import requests
from dotenv import load_dotenv
from datetime import datetime

load_dotenv()


CLIENT_ID = os.getenv("STRAVA_CLIENT_ID")
CLIENT_SECRET = os.getenv("STRAVA_CLIENT_SECRET")
REFRESH_TOKEN = os.getenv("STRAVA_REFRESH_TOKEN")

STRAVA_OAUTH_URL = "https://www.strava.com/oauth/token"
STRAVA_ACTIVITIES = "https://www.strava.com/api/v3/athlete/activities"

start_of_year = int(datetime(2025, 1, 1).timestamp())

def refresh_access_token():
    response = requests.post(STRAVA_OAUTH_URL, data={
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "grant_type": "refresh_token",
        "refresh_token": REFRESH_TOKEN,
    })
    data = response.json()
    if response.status_code != 200:
        raise RuntimeError(f"Token refresh failed: {data}")

    return data["access_token"]


def fetch_activities(access_token, per_page=200):
    headers = {"Authorization": f"Bearer {access_token}"}
    params = {"per_page": per_page, "page": 1, "after": start_of_year}
    response = requests.get(STRAVA_ACTIVITIES, headers=headers, params=params)
    return response.json()


def aggregate_metrics(activities):
    miles_ran = miles_walked = total_minutes = elevation_gain_ft = 0

    for act in activities:
        dist_miles = act["distance"] / 1609.34
        minutes = act["moving_time"] / 60
        elev_ft = act.get("total_elevation_gain", 0) * 3.28084

        if act["type"] == "Run":
            miles_ran += dist_miles
        elif act["type"] == "Walk":
            miles_walked += dist_miles

        total_minutes += minutes
        elevation_gain_ft += elev_ft

    return {
        "milesRan": round(miles_ran, 1),
        "milesWalked": round(miles_walked, 1),
        "totalActivityMinutes": int(total_minutes),
        "elevationGain": int(elevation_gain_ft),
    }


def fetch_strava_data():
    access_token = refresh_access_token()
    activities = fetch_activities(access_token)
    summary = aggregate_metrics(activities)
    return summary

if __name__ == "__main__":
    # for debugging
    print(fetch_strava_data())