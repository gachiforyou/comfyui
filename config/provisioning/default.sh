#!/bin/bash
set -e

echo "================================================"
echo "      VAST.AI AUTO-SETUP v3.0 (ENV ENABLED)"
echo "================================================"

########################################
# PATH CONFIG
########################################
VENV_PYTHON="/venv/main/bin/python"
VENV_PIP="/venv/main/bin/pip"
WORKSPACE="/workspace"
COMFY="$WORKSPACE/ComfyUI"
MODEL_DIR="$COMFY/models"
CUSTOM="$COMFY/custom_nodes"

# Vast.ai 템플릿에 입력한 환경 변수를 그대로 사용합니다.
# 변수명: CIVITAI_TOKEN, HUGGINGFACE_TOKEN
echo "Checking Environment Tokens..."
if [ -z "$CIVITAI_TOKEN" ]; then
    echo "WARNING: CIVITAI_TOKEN is not set in Vast.ai Env."
else
    echo "CIVITAI_TOKEN detected."
fi

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
        
        # URL에 이미 쿼리스트링(?)이 있는지 확인하여 토큰 추가
        if [[ "$URL" == *"?"* ]]; then
            FINAL_URL="${URL}&token=${CIVITAI_TOKEN}"
        else
            FINAL_URL="${URL}?token=${CIVITAI_TOKEN}"
        fi

        aria2c \
        -x 16 -s 16 -k 1M \
        --file-allocation=none \
        --console-log-level=error \
        -d "$(dirname "$FILE")" \
        -o "$(basename "$FILE")" \
        "$FINAL_URL"
    else
        echo "Already exists: $(basename "$FILE")"
    fi
}

########################################
# SYSTEM & UPDATE
########################################
apt update && apt install -y aria2
cd "$COMFY"
git pull || true

########################################
# PYTHON DEPENDENCIES
########################################
echo "Installing Python dependencies..."
$VENV_PIP install --upgrade pip --no-cache-dir
$VENV_PIP install --no-cache-dir \
    transformers accelerate diffusers hf_transfer \
    huggingface-hub tokenizers numpy==1.26.4 \
    safetensors opencv-python imageio-ffmpeg einops sentencepiece

# RTX Pro 6000 전용 최적화
$VENV_PIP install xformers --no-cache-dir || true
$VENV_PIP install flash-attn --no-build-isolation || true

########################################
# CUSTOM NODES & REQUIREMENTS
########################################
mkdir -p "$CUSTOM"
cd "$CUSTOM"
install_node https://github.com/ltdrdata/ComfyUI-Manager
install_node https://github.com/cubiq/ComfyUI_essentials
install_node https://github.com/kijai/ComfyUI-KJNodes
install_node https://github.com/yolain/ComfyUI-Easy-Use
install_node https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite

for dir in */ ; do
    if [ -f "$dir/requirements.txt" ]; then
        $VENV_PIP install -r "$dir/requirements.txt" --no-cache-dir || true
    fi
done

########################################
# MODEL DOWNLOADS (ENV TOKEN USED)
########################################
echo "Starting Model Downloads..."
mkdir -p "$MODEL_DIR/checkpoints" "$MODEL_DIR/diffusion_models" "$MODEL_DIR/clip" "$MODEL_DIR/vae" "$MODEL_DIR/loras" "$MODEL_DIR/controlnet"

# Checkpoints & Diffusion
download_if_missing "$MODEL_DIR/checkpoints/flux-dev-fp8.safetensors" "https://huggingface.co/XLabs-AI/flux-dev-fp8/resolve/main/flux-dev-fp8.safetensors" &
download_if_missing "$MODEL_DIR/diffusion_models/flux_dev_diffusion_fp8.safetensors" "https://civitai.com/api/download/models/2142065" &

# LoRAs (경로 소문자 loras 고정)
download_if_missing "$MODEL_DIR/loras/flux_lora_1.safetensors" "https://civitai.com/api/download/models/706528" &
download_if_missing "$MODEL_DIR/loras/flux_lora_2.safetensors" "https://civitai.com/api/download/models/1992217" &

# CLIP & VAE
download_if_missing "$MODEL_DIR/clip/t5xxl_fp8_e4m3fn.safetensors" "https://huggingface.co/hfmaster/models-moved/resolve/main/flux/t5xxl_fp8_e4m3fn.safetensors" &
download_if_missing "$MODEL_DIR/clip/clip_l.safetensors" "https://huggingface.co/camenduru/FLUX.1-dev/resolve/main/clip_l.safetensors" &
download_if_missing "$MODEL_DIR/vae/ae.safetensors" "https://huggingface.co/lovis93/testllm/resolve/main/ae.safetensors" &

wait
echo "All systems ready."

########################################
# LAUNCH
########################################
cd "$COMFY"
$VENV_PYTHON main.py --listen 0.0.0.0 --port 8188 --highvram --force-fp16 --preview-method auto
