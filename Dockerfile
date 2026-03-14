# =============================================================================
# Stage 1: Builder - Install dependencies and download models
# =============================================================================
ARG DOCKER_FROM=nvidia/cuda:12.8.0-runtime-ubuntu22.04
FROM ${DOCKER_FROM} AS builder

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    git \
    build-essential \
    ffmpeg \
    sox \
    libsox-fmt-all \
    libsndfile1-dev \
    libmagic1 \
    && rm -rf /var/lib/apt/lists/*

# create virtualenv
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --upgrade pip wheel setuptools

# install torch
RUN pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu128

# install requirements
COPY requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt

# install flash attention
RUN pip install https://github.com/mjun0812/flash-attention-prebuild-wheels/releases/download/v0.7.12/flash_attn-2.6.3+cu128torch2.10-cp310-cp310-linux_x86_64.whl || true

# download models
RUN python -c "from huggingface_hub import snapshot_download; snapshot_download('Qwen/Qwen3-TTS-12Hz-1.7B-Base')"
RUN python -c "from huggingface_hub import snapshot_download; snapshot_download('Qwen/Qwen3-TTS-Tokenizer-12Hz')"
RUN python -c "import whisper; whisper.load_model('base')"

# =============================================================================
# Stage 2: Runtime
# =============================================================================
FROM ${DOCKER_FROM} AS runtime

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    ffmpeg \
    sox \
    libsox-fmt-all \
    libsndfile1 \
    libmagic1 \
    git \
    git-lfs \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

# copy venv
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# copy cached models
COPY --from=builder /root/.cache /root/.cache

ENV PYTHONUNBUFFERED=1

# create working directory
WORKDIR /app

# copy project files
COPY server.py .
COPY handler.py .
COPY demo_speaker0.mp3 .

# expose port optional
EXPOSE 7860

# run runpod serverless handler
CMD ["python", "handler.py"]
