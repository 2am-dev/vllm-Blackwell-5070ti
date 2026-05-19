# Use the official NVIDIA CUDA 13.0 development image as our base
FROM nvidia/cuda:13.0.0-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Python 3.12 and uv
RUN apt-get update && apt-get install -y python3.12-dev python3.12-venv curl git && \
    curl -LsSf https://astral.sh/uv/install.sh | sh

ENV PATH="/root/.local/bin:${PATH}"

# Create a virtual environment
RUN uv venv /opt/venv --python 3.12
ENV PATH="/opt/venv/bin:$PATH"

# Install vLLM from the nightly wheel server 
RUN uv pip install -U --pre vllm --extra-index-url https://wheels.vllm.ai/nightly

# Install FlashInfer using their new package names
RUN uv pip install flashinfer-python flashinfer-cubin

CMD ["bash"]
