FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04

# ENV
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    CUDA_HOME=/usr/local/cuda \
    PATH=/usr/local/cuda/bin:$PATH \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Install python and depen
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    python3-dev \
    git \
    wget \
    gosu \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgoogle-perftools-dev \
    && rm -rf /var/lib/apt/lists/*

# For easy auto install
RUN ln -sf /usr/bin/python3.10 /usr/bin/python


# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip

# build deps
RUN pip install --no-cache-dir setuptools wheel packaging

# CLIP fix
RUN pip install --no-cache-dir --no-build-isolation \
https://github.com/openai/CLIP/archive/d50d76daa670286dd6cacf3bcd80b5e4823fc8e1.zip


# Install PyTorch with CUDA 12.8 support CHANGE LINK IF YOU GET RTX 6000 or New card idk what can happen  https://download.pytorch.org/whl/(cu128) <--- this part only
RUN pip install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128


# Make /app dir for forge
WORKDIR /app

# Clone repo IF NOT WORK CHANGE LINK FORM webui repo
RUN git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git /app/forge

WORKDIR /app/forge

# Create directory in /mnt for ComfyUI
RUN mkdir -p /mnt/models/Stable-diffusion \
    /mnt/models/Lora \
    /mnt/models/VAE \
    /mnt/models/ControlNet \
    /mnt/models/ESRGAN \
    /mnt/models/GFPGAN \
    /mnt/models/hypernetworks \
    /mnt/models/embeddings \
    /mnt/outputs

# Remove existing model directories and create symbolic links from forge directories to /mnt
RUN rm -rf /app/forge/models/Stable-diffusion \
    /app/forge/models/Lora \
    /app/forge/models/VAE \
    /app/forge/models/ControlNet \
    /app/forge/models/ESRGAN \
    /app/forge/models/GFPGAN \
    /app/forge/embeddings \
    /app/forge/outputs && \
    ln -s /mnt/models/Stable-diffusion /app/forge/models/Stable-diffusion && \
    ln -s /mnt/models/Lora /app/forge/models/Lora && \
    ln -s /mnt/models/VAE /app/forge/models/VAE && \
    ln -s /mnt/models/ControlNet /app/forge/models/ControlNet && \
    ln -s /mnt/models/ESRGAN /app/forge/models/ESRGAN && \
    ln -s /mnt/models/GFPGAN /app/forge/models/GFPGAN && \
    ln -s /mnt/models/embeddings /app/forge/embeddings && \
    ln -s /mnt/outputs /app/forge/outputs

# Install pip dependencies
RUN pip install --no-cache-dir -r requirements_versions.txt

# For performance
RUN pip install --no-cache-dir \
    xformers \
    triton \
    accelerate \
    opencv-python \
    insightface \
    onnxruntime-gpu

# Open port
EXPOSE 7860

# Create entrypoint script — runs as root, detects volume owner, drops to that user
RUN printf '#!/bin/bash\nset -e\n\n\
# Detect the UID/GID of the mounted outputs volume\n\
# This will match whoever owns ~/ai/Data/outputs on the host\n\
OWNER_UID=$(stat -c "%%u" /mnt/outputs)\n\
OWNER_GID=$(stat -c "%%g" /mnt/outputs)\n\
\n\
echo "Detected volume owner: UID=$OWNER_UID GID=$OWNER_GID"\n\
\n\
# Create a runtime user matching the host user (if not already root)\n\
if [ "$OWNER_UID" != "0" ]; then\n\
    # Create group if it does not exist\n\
    getent group "$OWNER_GID" || groupadd -g "$OWNER_GID" hostgroup\n\
    # Create user if it does not exist\n\
    getent passwd "$OWNER_UID" || useradd -m -u "$OWNER_UID" -g "$OWNER_GID" hostuser\n\
    # Give that user ownership of the app directory\n\
    chown -R "$OWNER_UID:$OWNER_GID" /app/forge\n\
fi\n\
\n\
echo "Starting Forge WebUI as UID=$OWNER_UID..."\n\
\n\
cd /app/forge\n\
\n\
# Drop from root to the host user and launch\n\
exec gosu "$OWNER_UID:$OWNER_GID" python launch.py \\\n\
    --listen \\\n\
    --port 7860 \\\n\
    --xformers \\\n\
    --enable-insecure-extension-access \\\n\
    --api \\\n\
    --opt-sdp-attention \\\n\
    --no-half-vae \\\n\
    "$@"\n' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Stay as root so entrypoint can chown and use gosu
ENTRYPOINT ["/entrypoint.sh"]
