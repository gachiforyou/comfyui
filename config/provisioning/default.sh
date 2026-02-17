#!/bin/bash
set -e

echo "===== ComfyUI Provisioning Start ====="

########################################
# 0. 환경 변수 확인
########################################

if [ -z "$HF_TOKEN" ]; then
  echo "HF_TOKEN is not set!"
  exit 1
fi

if [ -z "$CIVITAI_TOKEN" ]; then
  echo "CIVITAI_TOKEN is not set!"
  exit 1
fi

export HF_HUB_ENABLE_HF_TRANSFER=1

########################################
# 1. 기본 경로 설정
########################################

BASE="/workspace/ComfyUI/models"

mkdir -p \
  $BASE/diffusion_models \
  $BASE/loras \
  $BASE/vae \
  $BASE/text_encoders

########################################
# 2. Python 필수 패키지
########################################

echo "Installing required python packages..."

source /venv/main/bin/activate

pip install --upgrade pip
pip install opencv-python imageio imageio-ffmpeg einops timm

########################################
# 3. 다운로드 함수
########################################

download_if_not_exists () {
  FILE_PATH=$1
  URL=$2
  AUTH_HEADER=$3

  if [ -f "$FILE_PATH" ]; then
    echo "✔ Exists: $FILE_PATH"
  else
    echo "⬇ Downloading: $FILE_PATH"
    if [ -z "$AUTH_HEADER" ]; then
      wget -O "$FILE_PATH" "$URL"
    else
      wget --header="$AUTH_HEADER" -O "$FILE_PATH" "$URL"
    fi
  fi
}

########################################
# 4. Diffusion Models (Civitai)
########################################

download_if_not_exists \
  "$BASE/diffusion_models/WAN2_2_MODEL_PRUNED_FP8.safetensors" \
  "https://civitai.com/api/download/models/2513182?type=Model&format=SafeTensor&size=pruned&fp=fp8&token=$CIVITAI_TOKEN"

download_if_not_exists \
  "$BASE/diffusion_models/WAN2_2_MODEL_FULL_FP8.safetensors" \
  "https://civitai.com/api/download/models/2388627?type=Model&format=SafeTensor&size=full&fp=fp8&token=$CIVITAI_TOKEN"

########################################
# 5. LoRA Models (HuggingFace)
########################################

download_if_not_exists \
  "$BASE/loras/SVI_HIGH.safetensors" \
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Stable-Video-Infinity/v2.0/SVI_v2_PRO_Wan2.2-I2V-A14B_HIGH_lora_rank_128_fp16.safetensors" \
  "Authorization: Bearer $HF_TOKEN"

download_if_not_exists \
  "$BASE/loras/SVI_LOW.safetensors" \
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Stable-Video-Infinity/v2.0/SVI_v2_PRO_Wan2.2-I2V-A14B_LOW_lora_rank_128_fp16.safetensors" \
  "Authorization: Bearer $HF_TOKEN"

########################################
# 6. VAE
########################################

download_if_not_exists \
  "$BASE/vae/wan_2.1_vae.safetensors" \
  "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" \
  "Authorization: Bearer $HF_TOKEN"

########################################
# 7. Text Encoder
########################################

download_if_not_exists \
  "$BASE/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
  "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
  "Authorization: Bearer $HF_TOKEN"

echo "===== Provisioning Complete ====="
