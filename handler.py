import runpod
from server import app
from fastapi.testclient import TestClient

client = TestClient(app)

def handler(job):
    job_input = job["input"]

    text = job_input.get("text", "")

    response = client.get("/synthesize_speech/", params={"text": text})

    return response.json()

runpod.serverless.start({"handler": handler})
