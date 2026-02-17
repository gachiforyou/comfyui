#!/usr/bin/env bash
set -eo pipefail

log(){ echo "[provision] $*"; }

WORKSPACE="${WORKSPACE:-/workspace}"
COMFY_WORKSPACE="${WORKSPACE}/ComfyUI"

PYTHON_BIN="${PYTHON_BIN:-python3}"
PIP_BIN="${PIP_BIN:-pip3}"

APT_PACKAGES=("aria2" "git")
PIP_PACKAGES=("huggingface_hub" "hf_transfer")

# =========================
# MODELS & NODES
# =========================

NODES=(
  "https://github.com/ltdrdata/ComfyUI-Manager"
  "https://github.com/cubiq/ComfyUI_essentials"
  "https://github.com/kijai/ComfyUI-KJNodes"
  "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
  "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes"
  "https://github.com/PGCRT/CRT-Nodes"
  "https://github.com/yolain/ComfyUI-Easy-Use"
)

CLIP_VISION_MODELS=(
  "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"
)

LORA_MODELS=(
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Stable-Video-Infinity/v2.0/SVI_v2_PRO_Wan2.2-I2V-A14B_HIGH_lora_rank_128_fp16.safetensors"
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Stable-Video-Infinity/v2.0/SVI_v2_PRO_Wan2.2-I2V-A14B_LOW_lora_rank_128_fp16.safetensors" 
)

VAE_MODELS=(
  "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
)

UPSCALE_MODELS=(
  
)

DIFFUSION_MODELS=(
  "https://civitai.com/api/download/models/2513182?type=Model&format=SafeTensor&size=pruned&fp=fp8"
  "https://civitai.com/api/download/models/2388627?type=Model&format=SafeTensor&size=full&fp=fp8"
)
)

TEXT_ENCODER_MODELS=(
  "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
)

# =========================
# SETUP
# =========================

log "Installing apt packages..."
apt-get update -y || true
apt-get install -y --no-install-recommends "${APT_PACKAGES[@]}" || true

log "Installing pip packages..."
"$PIP_BIN" install --no-cache-dir "${PIP_PACKAGES[@]}" || true
export HF_HUB_ENABLE_HF_TRANSFER=1

# Ensure ComfyUI exists
if [[ ! -f "$COMFY_WORKSPACE/main.py" ]]; then
  log "ComfyUI not found. Cloning..."
  git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFY_WORKSPACE"
fi

mkdir -p "$COMFY_WORKSPACE/models"

# =========================
# DOWNLOAD FUNCTION
# =========================

download() {
  local dir="$1"
  local url="$2"

  mkdir -p "$dir"

  log "Downloading -> $dir"
  log "URL: $url"

  if command -v aria2c >/dev/null 2>&1; then
    aria2c -x 8 -s 8 -k 1M -d "$dir" "$url" || log "FAILED: $url"
  else
    curl -L -o "$dir/$(basename "$url")" "$url" || log "FAILED: $url"
  fi
}

# =========================
# INSTALL NODES
# =========================

log "Installing custom nodes..."
NODES_DIR="${COMFY_WORKSPACE}/custom_nodes"
mkdir -p "$NODES_DIR"

for repo in "${NODES[@]}"; do
  name="${repo##*/}"
  path="${NODES_DIR}/${name}"

  if [[ -d "$path" ]]; then
    log "Updating $name"
    git -C "$path" pull || true
  else
    log "Cloning $name"
    git clone --depth=1 "$repo" "$path"
  fi
done

# =========================
# DOWNLOAD MODELS
# =========================

for m in "${LORA_MODELS[@]}"; do
  download "${COMFY_WORKSPACE}/models/loras" "$m"
done

for m in "${VAE_MODELS[@]}"; do
  download "${COMFY_WORKSPACE}/models/vae" "$m"
done

for m in "${UPSCALE_MODELS[@]}"; do
  download "${COMFY_WORKSPACE}/models/upscale_models" "$m"
done

for m in "${DIFFUSION_MODELS[@]}"; do
  download "${COMFY_WORKSPACE}/models/diffusion_models" "$m"
done

for m in "${TEXT_ENCODER_MODELS[@]}"; do
  download "${COMFY_WORKSPACE}/models/text_encoders" "$m"
done

for m in "${CLIP_VISION_MODELS[@]}"; do
  download "${COMFY_WORKSPACE}/models/clip_vision" "$m"
done

log "Provisioning complete."
