FROM nvidia/cuda:12.8.0-cudnn-runtime-ubuntu22.04

# Avoid interaction and set shell
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# Set environment variables
ENV HOME=/root
ENV MBER_WEIGHTS_DIR=/mber_weights
ENV HF_HOME=/root/.mber/huggingface

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    git nano vim \
    build-essential \
    ca-certificates \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install micromamba
ENV MAMBA_EXE="/bin/micromamba"
ENV MAMBA_ROOT_PREFIX="/opt/micromamba"
RUN curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest \
    | tar -xvj -C /usr/local/bin/ --strip-components=1 bin/micromamba

WORKDIR /app

COPY . .

# Create environment and set as active for all shells
# Create environment, install dependencies, and clean caches
RUN micromamba env create -f environment.yml && \
    micromamba install -n mber -c conda-forge \
        libstdcxx-ng \
        libgcc-ng \
        -y && \
    micromamba run -n mber pip install \
        torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu128 && \
    micromamba run -n mber pip install \
        -r requirements.txt && \
    micromamba run -n mber pip install \
        -e . -e protocols && \
    micromamba clean --all --yes && \
    rm -rf ~/.cache/pip

# KEY STEPS FOR PERMANENT ACTIVATION:
# 1. Set the PATH so binaries are found immediately
ENV PATH="$MAMBA_ROOT_PREFIX/envs/mber/bin:$PATH"

# Ensure non-login shells (like 'docker exec') also see the environment
ENV MAMBA_DEFAULT_ENV=mber

RUN micromamba run -n mber ./download_weights.sh /root/.mber

CMD ["/bin/bash"]
