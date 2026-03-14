import runpod
import requests

def handler(job):
    job_input = job["input"]
    text = job_input.get("text", "")

    response = requests.get(
        "http://127.0.0.1:7860/synthesize_speech/",
        params={"text": text}
    )

    return response.json()

runpod.serverless.start({"handler": handler})
