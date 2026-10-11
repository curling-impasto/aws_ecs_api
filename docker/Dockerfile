# Build from the repo root: docker build -f docker/Dockerfile .
# Base image from ECR Public avoids Docker Hub rate limits
FROM public.ecr.aws/docker/library/python:3.12-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=3000

WORKDIR /app

# Dependencies first so this layer is cached when only code changes
COPY application/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY application/src ./src

RUN adduser -S -H appuser
USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["python", "-c", "import os, urllib.request; urllib.request.urlopen(f'http://127.0.0.1:{os.environ[\"PORT\"]}/health')"]

# Shell form is needed to expand PORT, exec keeps uvicorn as PID 1 for clean shutdown
CMD ["sh", "-c", "exec uvicorn src.main:app --host 0.0.0.0 --port ${PORT}"]
