#!/bin/bash
set -e

log() { echo -e "\n[Provision] $1\n"; }

########################################
# 0. 환경 변수 (Vast에서 주입된 값 사용)
########################################

if [ -z "$CIVITAI_TOKEN" ]; then
  echo "ERROR: CIVITAI_TOKEN not set"
  exit 1
fi

export HF_HUB_ENABLE_HF_TRANSFER=1

########################################
# 1. 기본 경로
########################################

COMFY="/workspace/ComfyUI"
MODELS="$COMFY/models"
CUSTOM="$COMFY/custom_nodes"

########################################
# 2. 시스템 패키지
########################################

apt update
apt install -y aria2 git ffmpeg

pip install --upgrade pip
pip install huggingface_hub hf_transfer opencv-python-headless imageio-ffmpeg

########################################
# 3. Wan 2.2 폴더 구조
########################################

mkdir -p \
  $MODELS/checkpoints \
  $MODELS/diffusion_models \
  $MODELS/unet \
  $MODELS/text_encoders \
  $MODELS/vae \
  $MODELS/loras \
  $MODELS/controlnet \
  $MODELS/upscale_models

mkdir -p $CUSTOM

########################################
# 4. 다운로드 함수
########################################

download() {
  local dir="$1"
  local url="$2"

  mkdir -p "$dir"

  if [[ "$url" == *"civitai.com"* ]]; then
    aria2c -x 8 -s 8 -k 1M \
      --header="Authorization: Bearer ${CIVITAI_TOKEN}" \
      -d "$dir" "$url"
  else
    aria2c -x 8 -s 8 -k 1M -d "$dir" "$url"
  fi
}

########################################
# 5. 커스텀 노드 설치
########################################

log "Installing custom nodes..."

NODES=(
"https://github.com/ltdrdata/ComfyUI-Manager"
"https://github.com/cubiq/ComfyUI_essentials"
"https://github.com/kijai/ComfyUI-KJNodes"
"https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
"https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes"
"https://github.com/PGCRT/CRT-Nodes"
"https://github.com/yolain/ComfyUI-Easy-Use"
)

for repo in "${NODES[@]}"; do
  name=$(basename "$repo")
  if [ ! -d "$CUSTOM/$name" ]; then
    git clone "$repo" "$CUSTOM/$name"
  fi
done

########################################
# 6. Diffusion Models
########################################

log "Downloading Diffusion Models..."

DIFFUSION_MODELS=(
"https://civitai.com/api/download/models/2513182?type=Model&format=SafeTensor&size=pruned&fp=fp8"
"https://civitai.com/api/download/models/2388627?type=Model&format=SafeTensor&size=full&fp=fp8"
)

for model in "${DIFFUSION_MODELS[@]}"; do
  download "$MODELS/diffusion_models" "$model"
done

########################################
# 7. LoRAs
########################################

log "Downloading LoRAs..."

LORA_MODELS=(
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Stable-Video-Infinity/v2.0/SVI_v2_PRO_Wan2.2-I2V-A14B_HIGH_lora_rank_128_fp16.safetensors"
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Stable-Video-Infinity/v2.0/SVI_v2_PRO_Wan2.2-I2V-A14B_LOW_lora_rank_128_fp16.safetensors"
)

for model in "${LORA_MODELS[@]}"; do
  download "$MODELS/loras" "$model"
done

########################################
# 8. VAE
########################################

log "Downloading VAE..."

download "$MODELS/vae" \
"https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"

########################################
# 9. Text Encoder
########################################

log "Downloading Text Encoder..."

download "$MODELS/text_encoders" \
"https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

########################################
# 10. 권한 정리
########################################

chown -R user:user /workspace

log "Provisioning Complete."
