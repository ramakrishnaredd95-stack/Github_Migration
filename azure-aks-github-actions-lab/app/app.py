from flask import Flask, jsonify
import os
import socket

app = Flask(__name__)

@app.get("/")
def home():
    return jsonify({
        "application": "shop-api",
        "message": "Hello from AKS",
        "version": os.getenv("APP_VERSION", "local"),
        "hostname": socket.gethostname()
    })

@app.get("/healthz")
def healthz():
    return jsonify({"status": "ok"}), 200

@app.get("/ready")
def ready():
    return jsonify({"ready": True}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
