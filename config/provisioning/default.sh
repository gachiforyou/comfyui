#!/bin/bash
set -e

echo "================================================"
echo "      VAST.AI ULTIMATE COMFYUI SETUP v2.1"
echo "================================================"

########################################
# PATH & CONFIG (경로 대소문자 통일)
########################################
VENV_PYTHON="/venv/main/bin/python"
VENV_PIP="/venv/main/bin/pip"
WORKSPACE="/workspace"
COMFY="$WORKSPACE/ComfyUI"
MODEL_DIR="$COMFY/models"
CUSTOM="$COMFY/custom_nodes"

# 중요: Civitai에서 모델을 받으려면 API Key가 필수입니다.
# https://civitai.com/user/settings 에서 하단 API Key를 생성해 넣으세요.
CIVITAI_TOKEN="여기에_본인의_시비타이_API키_입력"

########################################
# FUNCTIONS
########################################
install_node () {
    REPO=$1
    NAME=$(basename "$REPO")
    if [ ! -d "$CUSTOM/$NAME" ]; then
        echo "Installing node: $NAME"
        git clone --depth=1 "$REPO" "$CUSTOM/$NAME"
    else
        echo "Node exists: $NAME"
    fi
}

download_if_missing () {
    FILE=$1
    URL=$2
    if [ ! -f "$FILE" ]; then
        echo "Downloading $(basename "$FILE")..."
        mkdir -p "$(dirname "$FILE")"
        # aria2c 옵션 최적화 및 토큰 처리
        aria2c \
        -x 16 \
        -s 16 \
        -k 1M \
        --file-allocation=none \
        --console-log-level=error \
        -d "$(dirname "$FILE")" \
        -o "$(basename "$FILE")" \
        "$URL"
    else
        echo "Already exists: $(basename "$FILE")"
    fi
}

########################################
# SYSTEM PREPARE
########################################
apt update && apt install -y aria2

########################################
# UPDATE COMFYUI
########################################
echo "Updating ComfyUI..."
cd "$COMFY"
git pull || true

########################################
# PYTHON ENV & DEPENDENCIES
########################################
echo "Installing Python dependencies..."
$VENV_PIP install --upgrade pip --no-cache-dir
$VENV_PIP install --no-cache-dir \
    transformers==4.44.2 \
    accelerate==0.33.0 \
    diffusers==0.36.0 \
    huggingface-hub \
    tokenizers \
    numpy==1.26.4 \
    safetensors \
    opencv-python \
    imageio-ffmpeg \
    einops \
    sentencepiece

# RTX Pro 6000 최적화 (Flash Attention 등)
$VENV_PIP install xformers --no-cache-dir || true
$VENV_PIP install flash-attn --no-build-isolation || true

########################################
# CUSTOM NODES
########################################
mkdir -p "$CUSTOM"
cd "$CUSTOM"
install_node https://github.com/ltdrdata/ComfyUI-Manager
install_node https://github.com/cubiq/ComfyUI_essentials
install_node https://github.com/kijai/ComfyUI-KJNodes
install_node https://github.com/yolain/ComfyUI-Easy-Use
install_node https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite

# Node Requirements 설치
for dir in */ ; do
    if [ -f "$dir/requirements.txt" ]; then
        echo "Installing requirements for $dir"
        $VENV_PIP install -r "$dir/requirements.txt" --no-cache-dir || true
    fi
done

########################################
# MODEL DIRECTORIES (소문자로 경로 강제)
########################################
mkdir -p "$MODEL_DIR/checkpoints"
mkdir -p "$MODEL_DIR/diffusion_models"
mkdir -p "$MODEL_DIR/clip"
mkdir -p "$MODEL_DIR/vae"
mkdir -p "$MODEL_DIR/loras"
mkdir -p "$MODEL_DIR/controlnet"

########################################
# MODEL DOWNLOADS (Flux & LoRA)
########################################
echo "Starting Model Downloads..."

# Checkpoints
download_if_missing "$MODEL_DIR/checkpoints/flux-dev-fp8.safetensors" "https://huggingface.co/XLabs-AI/flux-dev-fp8/resolve/main/flux-dev-fp8.safetensors" &

# Diffusion Models
download_if_missing "$MODEL_DIR/diffusion_models/flux_dev_diffusion_fp8.safetensors" "https://civitai.com/api/download/models/2142065?token=$CIVITAI_TOKEN" &

# LoRAs (경로 /loras 확인 필수)
download_if_missing "$MODEL_DIR/loras/flux_lora_1.safetensors" "https://civitai.com/api/download/models/706528?token=$CIVITAI_TOKEN" &
download_if_missing "$MODEL_DIR/loras/flux_lora_2.safetensors" "https://civitai.com/api/download/models/1992217?token=$CIVITAI_TOKEN" &

# CLIP & VAE
download_if_missing "$MODEL_DIR/clip/t5xxl_fp8_e4m3fn.safetensors" "https://huggingface.co/hfmaster/models-moved/resolve/main/flux/t5xxl_fp8_e4m3fn.safetensors" &
download_if_missing "$MODEL_DIR/clip/clip_l.safetensors" "https://huggingface.co/camenduru/FLUX.1-dev/resolve/main/clip_l.safetensors" &
download_if_missing "$MODEL_DIR/vae/ae.safetensors" "https://huggingface.co/lovis93/testllm/resolve/main/ae.safetensors" &

wait
echo "All models installed successfully."

########################################
# LAUNCH COMFYUI
########################################
echo "Launching ComfyUI on RTX Pro 6000..."
cd "$COMFY"
$VENV_PYTHON main.py --listen 0.0.0.0 --port 8188 --highvram --force-fp16 --preview-method auto
