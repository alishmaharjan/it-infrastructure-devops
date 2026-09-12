from flask import Flask
import os 
import psycopg2

app = Flask(__name__)

@app.route("/")
def home():
	db_status = "unknown"
	
	try:
		conn = psycopg2.connect(
			host=os.getenv("DB_HOST", "db"),
			database=os.getenv("POSTGRES_DB", "devopsdb"),
			user=os.getenv("POSTGRES_USER", "devops"),
			password=os.getenv("POSTGRES_PASSWORD", "devopspass")
		)
		conn.close()
		db_status = "connection success"
	except Exception:
		db_status = "connection failed"
	
	return f"""
	<html>
		<head>
			<title> pratical of trainee</title>
		</head>
		<body>
			<h1>testings flask</h1>
			<p> Backend: Flask</p>
			<p>Database: PostgreSQL</p>
			<p>Database status: <strong>{db_status}</strong></p>
			<p>Reverse Proxy: Nginx</p>
		</body>
	</html>
	"""

@app.route("/health")
def health():
	return {"status": "healthy"}

if __name__ == "__main__":
	app.run(host="0.0.0.0", port=5000)
