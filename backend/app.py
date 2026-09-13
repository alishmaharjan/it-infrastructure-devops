from flask import Flask, render_template
import os
import psycopg2

app = Flask(__name__)

HEALTH_FILE = "/health/health_status.txt"


def get_db_status():
    try:
        conn = psycopg2.connect(
            host=os.getenv("DB_HOST", "db"),
            database=os.getenv("POSTGRES_DB", "devopsdb"),
            user=os.getenv("POSTGRES_USER", "devops"),
            password=os.getenv("POSTGRES_PASSWORD", "devopspass")
        )
        conn.close()
        return "connection success"
    except Exception:
        return "connection failed"


def get_health_data():
    data = {}

    try:
        with open(HEALTH_FILE, "r") as file:
            for line in file:
                line = line.strip()

                if "=" in line:
                    key, value = line.split("=", 1)
                    data[key] = value

    except Exception:
        return {
            "timestamp": "N/A",
            "cpu": "N/A",
            "ram": "N/A",
            "disk": "N/A",
            "docker": "UNKNOWN",
            "backend": "UNKNOWN",
            "overall_status": "UNKNOWN"
        }

    return {
        "timestamp": data.get("TIMESTAMP", "N/A"),
        "cpu": data.get("CPU", "N/A"),
        "ram": data.get("RAM", "N/A"),
        "disk": data.get("DISK", "N/A"),
        "docker": data.get("DOCKER", "UNKNOWN"),
        "backend": data.get("BACKEND", "UNKNOWN"),
        "overall_status": data.get("OVERALL", "UNKNOWN")
    }


@app.route("/")
def home():
    return render_template(
        "home.html",
        db_status=get_db_status()
    )


@app.route("/health")
def health():
    return {"status": "healthy"}


@app.route("/dashboard")
def dashboard():
    data = get_health_data()

    return render_template(
        "dashboard.html",
        **data
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
