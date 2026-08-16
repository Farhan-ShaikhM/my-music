from fastapi import FastAPI

app = FastAPI(
    title="My Music API",
    version="0.1.0",
)


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "my-music-api",
    }