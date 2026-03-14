import runpod
import requests

def handler(job):
    text = job["input"].get("text", "")

    response = requests.get(
        "http://127.0.0.1:7860/synthesize_speech/",
        params={"text": text}
    )

    return response.json()

runpod.serverless.start({"handler": handler})
