import os
import redis as redis_lib
from flask import Flask, jsonify, request, abort
from celery import Celery
from celery.result import AsyncResult

app = Flask(__name__)

redis_host = os.environ.get("REDIS_HOST", "localhost")
redis_port = int(os.environ.get("REDIS_PORT", "6379"))
broker_url = f"redis://{redis_host}:{redis_port}/0"
backend_url = f"redis://{redis_host}:{redis_port}/1"

celery_client = Celery(broker=broker_url, backend=backend_url)
_redis = redis_lib.Redis(host=redis_host, port=redis_port, socket_connect_timeout=2)


@app.route("/health")
def health():
    try:
        _redis.ping()
        broker_ok = True
    except redis_lib.exceptions.RedisError:
        broker_ok = False

    status = "ok" if broker_ok else "degraded"
    return jsonify({"status": status, "broker": broker_ok}), (200 if broker_ok else 503)


@app.route("/")
def index():
    return "hello"


@app.route("/jobs", methods=["POST"])
def submit_job():
    data = request.get_json(silent=True) or {}
    iterations = data.get("iterations", 10_000_000)

    try:
        iterations = int(iterations)
    except (TypeError, ValueError):
        abort(400, description="iterations must be an integer")

    if not (1_000_000 <= iterations <= 1_000_000_000):
        abort(400, description="iterations must be between 1_000_000 and 1_000_000_000")

    task = celery_client.send_task(
        "tasks.monte_carlo_pi",
        kwargs={"iterations": iterations},
    )

    return (
        jsonify({"job_id": task.id, "status": "submitted", "iterations": iterations}),
        202,
    )


@app.route("/jobs/<job_id>")
def get_job(job_id):
    result = AsyncResult(job_id, app=celery_client)

    response = {"job_id": job_id, "status": result.state}

    if result.state == "PROGRESS":
        response["progress"] = result.info
    elif result.state == "SUCCESS":
        response["result"] = result.result
    elif result.state == "FAILURE":
        response["error"] = str(result.result)

    return jsonify(response)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
