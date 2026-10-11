import os

from fastapi import FastAPI

# The shared ALB forwards the full path, so requests arrive as /<prefix>/...
app = FastAPI(title="Sample API", root_path=os.getenv("ROUTE_PREFIX", ""))


@app.get("/")
def root() -> dict[str, str]:
    return {"message": "Sample API"}


@app.get("/health")
def health() -> dict[str, str]:
    # Kept dependency-free so the ALB check reflects process health only
    return {"status": "healthy"}


@app.get("/version")
def version() -> dict[str, str]:
    return {"version": "1.0"}
