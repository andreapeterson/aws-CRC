from flask import Flask, jsonify
from flask_cors import CORS
from main import fetch_strava_data

app = Flask(__name__)
CORS(app)

@app.route("/strava-metrics")
def strava_metrics():
    try:
        metrics = fetch_strava_data()
        return jsonify(metrics)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5050)
