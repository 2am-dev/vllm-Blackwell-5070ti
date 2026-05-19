# Ubuntu 24.04 Blackwell Inference Server: vLLM + FlashInfer on RTX 5070 Ti
A production-ready, end-to-end blueprint for deploying high-performance local LLM inference via **vLLM**This guide outlines how to co-exist with Docker Desktop on **Ubuntu 24.04 LTS**, bypass lengthy source compilations---
## 🖥️ System Architecture Baseline
* **Host OS:** Ubuntu 24.04 LTS
* **GPU:** NVIDIA GeForce RTX 5070 Ti (16GB VRAM, Blackwell `sm_120` compute capability)
* **System RAM:** 64 GB
* **Driver & Engine Runtimes:** NVIDIA Driver `595.58.03` + Native Docker Engine (CE) + Docker Desktop* **Target Model Matrix:** `Qwen/Qwen2.5-7B-Instruct-AWQ`
---
## 🛑 Post-Mortem: What Does NOT Work (And Why)
Before running the working configuration, review these common pitfalls encountered during our environment| Problem / Error State | Why It Fails | The Working Fix |
| :--- | :--- | :--- |
| `error: externally-managed-environment` (PEP 668) | Ubuntu 24.04 blocks system-wide host `pip install`| `failed to discover GPU vendor from CDI` | **Docker Desktop for Linux** runs containers inside an isolated| `CDI device injection failed: unresolvable CDI devices` | Passing `--device nvidia.com/gpu=all` to a virtualized| `{"detail":"Not Found"}` when hitting `/v1/chat/completions` | Legacy tutorials call the old entrypoint| `flashinfer` installation crashes during build | The project recently split its deployment layers. The---
## 🚀 Step-by-Step Implementation
### Step 1: Environment Swapping (Native Docker Setup)
Because Docker Desktop and Native Docker store their images and files in separate regions, we must swap
on NVIDIA's Blackwell desktop architecture (**RTX 5070 Ti**). 
using ultra-fast nightly wheel streams, implement **FlashInfer** acceleration, and safely manage or tear down your environment.
(co-existing)
bring-up:
commands to protect the OS integrity. | Execute all automation and commands (like Hugging Face downloads) directly **inside** the container. |
user-space virtual machine. It cannot automatically see your physical GPU slots or host CDI maps without broken hacks. | Pivot to **Native Linux Docker Engine (CE)** for direct bare-metal PCI access. |
or misconfigured runtime daemon breaks device tracking. | Configure the runtime daemon native context and pass the standard, high-efficiency `--gpus all` flag. |
`python3 -m vllm.entrypoints.api_server`, which serves a bare-bones generation endpoint missing modern OpenAI routes. | Utilize the production-grade binary CLI runner: **`vllm serve`**. |
package name `flashinfer` is deprecated. | Install the separate, pre-compiled binary modules: **`flashinfer-python`** and **`flashinfer-cubin`**. |
to the native engine context to unlock the raw PCI performance of your 5070 Ti.
1. Gracefully shut down Docker Desktop to release locked system
memory 
systemctl –user stop docker-desktop 
2. Re-route your terminal CLI tool back to the Linux host engine 
docker context use default 
3. Ensure your Ubuntu system has the core native daemons
updated and running 
sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io 
4. Bind the NVIDIA Container Toolkit architecture to the host
Docker configurationsudo nvidia-ctk runtime configure –runtime=docker 
5. Refresh the native docker service 
sudo systemctl restart docker 
### Step 2: Build the Container Spec
Create a file named `Dockerfile` in your working directory and populate it with the following code. This architecture leverages `uv` for lightning-fast module installations and installs pre-built Blackwell-compatible `sm_120` nightly wheel layers.

Use the official NVIDIA CUDA 13.0 development image as our
base layer 
FROM nvidia/cuda:13.0.0-devel-ubuntu24.04 
ENV DEBIAN_FRONTEND=noninteractive 
Install modern Python 3.12 components and the ‘uv’ package
compiler 
RUN apt-get update && apt-get install -y python3.12-dev python3.12-venv curl git && \ curl -LsSf https://astral.sh/uv/install.sh | sh 
ENV PATH=“/root/.local/bin:${PATH}” 
Generate isolated virtual execution paths 
RUN uv venv /opt/venv –python 3.12 ENV PATH=“/opt/venv/bin:$PATH” 
Install vLLM from the official nightly stream containing native
sm_120 code structures 
RUN uv pip install -U –pre vllm –extra-index-url https://wheels.vllm.ai/nightly 
Install FlashInfer using their modern, optimized binary ecosystem
modules 
RUN uv pip install flashinfer-python flashinfer-cubin 
CMD [“bash”] 
Compile the image space (takes ~3 minutes):

docker build -t vllm-blackwell . 
### Step 3: Isolated Model Ingestion
Map a host folder directory to protect your downloads from systemic host environment locks.

Create local data cache store on your host 
mkdir -p ~/models 
Authenticate with the Hugging Face Hub securely inside thecontainer environment 
docker run –rm -it -v ~/models:/models vllm-blackwell hf auth login 
Download the official Qwen2.5 7B Instruct AWQ model directly
into your mounted volume 
docker run –rm -it -v ~/models:/models vllm-blackwell \ hf download Qwen/Qwen2.5-7B-Instruct-AWQ –local-dir /models
Qwen2.5-7B-Instruct-AWQ 
### Step 4: Launch the vLLM Engine
Execute this command to boot up the inference server. It safely sets VRAM allocations to **85%** (keeping
docker run –name vllm-server –rm –gpus all –ipc=host –ulimit memlock=-1 –ulimit stack=67108864 \ -p 18000:8000 -v ~/models:
models \ -e VLLM_ATTENTION_BACKEND=FLASHINFER \ vllm-blackwell \ vllm serve /models/Qwen2.5-7B-Instruct-AWQ \ 
quantization awq \ –gpu-memory-utilization 0.85 \ –max-model-len 16384 \ –enable-chunked-prefill 
---
## ⚡ Verifying and Interacting with the API
When the logs print `Uvicorn running on http://0.0.0.0:8000`, your Blackwell-powered API is hot. Open a### Native cURL Terminal Payload

curl http://localhost:18000/v1/chat/completions \ -H “Content-Type: application/json” \ -d ‘{ “model”: “/models/Qwen2.5-7B-Instruct
AWQ”, “messages”: [ {“role”: “system”, “content”: “You are a highly efficient local AI server running on a Blackwell GPU.”}, {“role”:
“user”, “content”: “Write a 1-sentence confirmation message.”} ], “max_tokens”: 50 }’ 
### Client Frontend Connections (Chatbox, AnythingLLM, VS Code)
To drop manual coding and route this to user-friendly chat apps:
* **AI Provider Type:** `OpenAI` or `Custom OpenAI Compatible`
* **Base Endpoint Endpoint URL:** `http://localhost:18000/v1`
* **Secret Key Pass:** `token-not-needed` (Type any proxy characters to bypass validation)
* **Model Config Name:** `/models/Qwen2.5-7B-Instruct-AWQ`
---
## 🛑 How to Safely Close and Tear Down the Setup
Because this server binds a massive amount of VRAM and holds locks on your network ports, do not simply### 1. Graceful Exit
If you are running the engine in the foreground, go to that active terminal window and press:

Ctrl + C 
This forces vLLM to safely clear its memory cache, dump CUDA graphs, and spin down its background threads### 2. If the Process Hangs (Force Shutdown)
If your terminal disconnected or the engine is trapped in a loop, open a fresh terminal shell and run:

your local desktop environment snappy) and forwards the internal service out to host port **18000**.
separate terminal terminal shell to run tests:
close the terminal window. Use these clean teardown procedures:
cleanly without stranding system hardware assets.
Force kill the specific container processdocker stop vllm-server 
### 3. Clear stranded VRAM completely
To confirm your RTX 5070 Ti memory pool is fully emptied back down to baseline levels, run:

nvidia-smi 
If you still see a dead container thread utilizing hundreds of megabytes of memory under the processes block, completely reset the host native container runtime to scrub it clean:

sudo systemctl restart docker 
---
## 🔄 Switching Workloads (The Day-To-Day Workflow)
Since your system maintains both development layers simultaneously, utilize these toggle commands to pivot depending on your task profile:
* **Pivoting to Heavy Blackwell AI Mode:**

systemctl –user stop docker-desktop && sudo systemctl start docker && docker context use default 
* **Returning to Standard Docker Desktop GUI Mode:**

sudo systemctl stop docker docker.socket containerd && systemctl –user start docker-desktop && docker context use desktop-linux 