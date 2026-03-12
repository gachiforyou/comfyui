#!/bin/bash
set -e

echo "================================================"
echo "     VAST.AI ULTIMATE COMFYUI SETUP v2"
echo "================================================"

########################################
# PATH
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

download_if_missing () {

FILE=$1
URL=$2

if [ ! -f "$FILE" ]; then

echo "Downloading $(basename "$FILE")"

mkdir -p "$(dirname "$FILE")"

aria2c \
-x 16 \
-s 16 \
-k 1M \
--file-allocation=none \
-d "$(dirname "$FILE")" \
-o "$(basename "$FILE")" \
"$URL"

else

echo "Already exists: $(basename "$FILE")"

fi

}

########################################
# INSTALL ARIA2 (FAST DOWNLOAD)
########################################

apt update
apt install -y aria2

########################################
# UPDATE COMFYUI
########################################

echo "Updating ComfyUI..."

cd "$COMFY"
git pull || true

########################################
# PYTHON ENV
########################################

echo "Installing Python dependencies..."

$VENV_PIP install --upgrade pip --no-cache-dir

$VENV_PIP install --no-cache-dir \
transformers==4.44.2 \
accelerate==0.33.0 \
diffusers==0.36.0 \
huggingface-hub==0.36.2 \
tokenizers==0.19.1 \
numpy==1.26.4 \
protobuf \
boto3 \
opencv-python \
imageio-ffmpeg \
einops \
sentencepiece \
safetensors

########################################
# SPEED OPTIMIZATION
########################################

echo "Installing speed optimizations..."

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
install_node https://github.com/olduvai-jp/ComfyUI-S3-IO

########################################
# NODE REQUIREMENTS
########################################

echo "Installing node requirements..."

for dir in */ ; do

if [ -f "$dir/requirements.txt" ]; then

echo "Installing requirements for $dir"

$VENV_PIP install -r "$dir/requirements.txt" --no-cache-dir || true

fi

done

########################################
# MODEL FOLDERS
########################################

mkdir -p "$MODEL_DIR/checkpoints"
mkdir -p "$MODEL_DIR/diffusion_models"
mkdir -p "$MODEL_DIR/clip"
mkdir -p "$MODEL_DIR/vae"
mkdir -p "$MODEL_DIR/loras"
mkdir -p "$MODEL_DIR/controlnet"

########################################
# FLUX MODEL SET
########################################

echo "Installing Flux models..."

download_if_missing \
"$MODEL_DIR/checkpoints/flux-dev-fp8.safetensors" \
"https://huggingface.co/XLabs-AI/flux-dev-fp8/resolve/main/flux-dev-fp8.safetensors" &

download_if_missing \
"$MODEL_DIR/diffusion_models/flux_dev_diffusion_fp8.safetensors" \
"https://civitai.com/api/download/models/2142065?type=Model&format=SafeTensor&size=pruned&fp=fp8" &

download_if_missing \
"$MODEL_DIR/loras/flux_lora_1.safetensors" \
"https://civitai.com/api/download/models/706528?type=Model&format=SafeTensor" &

download_if_missing \
"$MODEL_DIR/loras/flux_lora_2.safetensors" \
"https://civitai.com/api/download/models/1992217?type=Model&format=SafeTensor" &

download_if_missing \
"$MODEL_DIR/clip/t5xxl_fp8_e4m3fn.safetensors" \
"https://huggingface.co/hfmaster/models-moved/resolve/0cd2fcc2a918ea05bdb0ae06739701c31fa499ee/flux/t5xxl_fp8_e4m3fn.safetensors" &

download_if_missing \
"$MODEL_DIR/clip/clip_l.safetensors" \
"https://huggingface.co/camenduru/FLUX.1-dev/resolve/main/clip_l.safetensors" &

download_if_missing \
"$MODEL_DIR/controlnet/flux_union_controlnet.safetensors" \
"https://huggingface.co/Shakker-Labs/FLUX.1-dev-ControlNet-Union-Pro/resolve/main/diffusion_pytorch_model.safetensors" &

download_if_missing \
"$MODEL_DIR/vae/ae.safetensors" \
"https://huggingface.co/lovis93/testllm/resolve/ed9cf1af7465cebca4649157f118e331cf2a084f/ae.safetensors" &

wait

echo "Flux models installed."

########################################
# START COMFYUI
########################################

echo "Launching ComfyUI..."

cd "$COMFY"

$VENV_PYTHON main.py \
--listen 0.0.0.0 \
--port 8188 \
--force-fp16 \
--preview-method auto \
--disable-auto-launch
