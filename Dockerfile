FROM nvidia/cuda:12.8.0-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_ROOT_USER_ACTION=ignore \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3-pip python3-dev python-is-python3 \
    build-essential pkg-config libcairo2-dev \
    git wget gosu \
    libgl1 libglib2.0-0 libsm6 libxext6 libgomp1 \
    libgoogle-perftools-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip setuptools wheel packaging

RUN pip install torch torchvision xformers --index-url https://download.pytorch.org/whl/cu128

WORKDIR /app
RUN git clone --depth 1 https://github.com/lllyasviel/stable-diffusion-webui-forge.git /app/forge
WORKDIR /app/forge

RUN pip install "numpy<2.0" "scipy<1.12" -r requirements_versions.txt \
 && pip install --no-build-isolation \
    https://github.com/openai/CLIP/archive/d50d76daa670286dd6cacf3bcd80b5e4823fc8e1.zip \
 && pip install triton accelerate opencv-python insightface onnxruntime-gpu \
 && pip install --force-reinstall --no-deps scikit-image

RUN mkdir -p /mnt/outputs \
    /app/forge/models/Stable-diffusion /app/forge/models/Lora

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 7860
ENTRYPOINT ["/entrypoint.sh"]
