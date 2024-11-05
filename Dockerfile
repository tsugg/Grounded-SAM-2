FROM pytorch/pytorch:2.3.1-cuda12.1-cudnn8-devel as base

# Arguments to build Docker Image using CUDA
ARG USE_CUDA=0
ARG TORCH_ARCH="8.6"

ENV AM_I_DOCKER=True
ENV BUILD_WITH_CUDA="${USE_CUDA}"
ENV TORCH_CUDA_ARCH_LIST="${TORCH_ARCH}"
ENV CUDA_HOME=/usr/local/cuda-12.1/
# Ensure CUDA is correctly set up
ENV PATH=/usr/local/cuda-12.1/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/cuda-12.1/lib64:${LD_LIBRARY_PATH}

# Install required packages and specific gcc/g++
RUN apt-get update && apt-get install --no-install-recommends \
    wget \
    ffmpeg=7:* \
    libsm6=2:* \
    libxext6=2:* \
    git=1:* \
    vim=2:* \
    ninja-build \
    gcc-10 \
    g++-10 \
    build-essential \
    ca-certificates \
    -y \
    && apt-get clean && apt-get autoremove && rm -rf /var/lib/apt/lists/*

ENV CC=gcc-10
ENV CXX=g++-10

WORKDIR /app

RUN mkdir -p /app/extensions/Grounded-SAM-2/
COPY . /app/extensions/Grounded-SAM-2/

# Install essential Python packages
RUN python -m pip install --upgrade pip setuptools wheel numpy \
    opencv-python transformers supervision pycocotools addict yapf timm

# Install segment_anything package in editable mode
RUN python -m pip install -e extensions/Grounded-SAM-2/

# Install grounding dino
RUN python -m pip install --no-build-isolation -e extensions/Grounded-SAM-2/grounding_dino \
    && pip install -r extensions/Grounded-SAM-2/grounding_dino/requirements.txt

# Copy from shoe-splatter
COPY --from=shoe-splatter/shoe-splatter:latest /app /app

# Install shoe_splatter
RUN python -m pip install -e .

# Bash as default entrypoint.
CMD /bin/bash -l
