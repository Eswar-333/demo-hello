
from flask import Flask
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)

# Enable Prometheus metrics at /metrics
metrics = PrometheusMetrics(app)

@app.route("/")
def hello():
    return "Hello Ravi! This is the final hello project!"

@app.route("/new")
def new():
    return "FINAL CHECK"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5005)
