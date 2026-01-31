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
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

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

# Create entrypoint script that ensures proper symlinks
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Ensure /mnt directories exist or not\n\
mkdir -p /mnt/models/Stable-diffusion \\\n\
         /mnt/models/Lora \\\n\
         /mnt/models/VAE \\\n\
         /mnt/models/ControlNet \\\n\
         /mnt/models/ESRGAN \\\n\
         /mnt/models/GFPGAN \\\n\
         /mnt/models/hypernetworks \\\n\
         /mnt/models/embeddings \\\n\
         /mnt/outputs\n\
\n\
# Function to create symlink safely\n\
create_symlink() {\n\
    local target=$1\n\
    local link=$2\n\
    \n\
    if [ -L "$link" ]; then\n\
        # Already a symlink, remove it\n\
        rm -f "$link"\n\
    elif [ -d "$link" ]; then\n\
        # Directory exists, remove it\n\
        rm -rf "$link"\n\
    elif [ -f "$link" ]; then\n\
        # File exists, remove it\n\
        rm -f "$link"\n\
    fi\n\
    \n\
    # Create the symlink\n\
    ln -s "$target" "$link"\n\
}\n\
\n\
# Create all symlinks\n\
create_symlink /mnt/models/Stable-diffusion /app/forge/models/Stable-diffusion\n\
create_symlink /mnt/models/Lora /app/forge/models/Lora\n\
create_symlink /mnt/models/VAE /app/forge/models/VAE\n\
create_symlink /mnt/models/ControlNet /app/forge/models/ControlNet\n\
create_symlink /mnt/models/ESRGAN /app/forge/models/ESRGAN\n\
create_symlink /mnt/models/GFPGAN /app/forge/models/GFPGAN\n\
create_symlink /mnt/models/embeddings /app/forge/embeddings\n\
create_symlink /mnt/outputs /app/forge/outputs\n\
\n\
echo "Symlinks created successfully"\n\
echo "Starting Forge WebUI..."\n\
\n\
# Launch Forge\n\
cd /app/forge\n\
python launch.py \\\n\
    --listen \\\n\
    --port 7860 \\\n\
    --xformers \\\n\
    --enable-insecure-extension-access \\\n\
    --api \\\n\
    --opt-sdp-attention \\\n\
    --no-half-vae \\\n\
    "$@"' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]
