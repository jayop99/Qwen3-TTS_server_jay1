import runpod
from server import synthesize_speech

def handler(job):
    job_input = job["input"]
    
    text = job_input.get("text", "")
    
    audio = synthesize_speech(text)
    
    return {"audio": audio}

runpod.serverless.start({"handler": handler})
