#!/bin/bash
set -e

echo "================================================"
echo "      VAST.AI AUTO-SETUP v3.1 (LIGHT VERSION)"
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

########################################
# SYSTEM & UPDATE
########################################
apt update && apt install -y git
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

# GPU 최적화
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

# requirements 자동 설치
for dir in */ ; do
    if [ -f "$dir/requirements.txt" ]; then
        $VENV_PIP install -r "$dir/requirements.txt" --no-cache-dir || true
    fi
done

########################################
# CREATE MODEL DIRS (ONLY STRUCTURE)
########################################
mkdir -p \
"$MODEL_DIR/checkpoints" \
"$MODEL_DIR/diffusion_models" \
"$MODEL_DIR/clip" \
"$MODEL_DIR/vae" \
"$MODEL_DIR/loras" \
"$MODEL_DIR/controlnet"

echo "Environment ready. (Models should be downloaded manually)"

########################################
# LAUNCH
########################################
cd "$COMFY"
$VENV_PYTHON main.py --listen 0.0.0.0 --port 8188 --highvram --force-fp16 --preview-method auto
