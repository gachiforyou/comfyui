#!/bin/bash
set -e

echo "===== COMFYUI AUTO PROVISION START ====="

########################################
# 환경 변수 확인
########################################

if [ -z "$HF_TOKEN" ]; then
  echo "HF_TOKEN not set"
  exit 1
fi

if [ -z "$CIVITAI_TOKEN" ]; then
  echo "CIVITAI_TOKEN not set"
  exit 1
fi

export HF_HUB_ENABLE_HF_TRANSFER=1

BASE="/workspace/ComfyUI"
MODEL_DIR="$BASE/models"
NODE_DIR="$BASE/custom_nodes"

mkdir -p \
  $MODEL_DIR/diffusion_models \
  $MODEL_DIR/loras \
  $MODEL_DIR/vae \
  $MODEL_DIR/text_encoders \
  $NODE_DIR

########################################
# Python 환경
########################################

source /venv/main/bin/activate

pip install --upgrade pip
pip install opencv-python imageio imageio-ffmpeg einops timm

########################################
# Custom Nodes 자동 설치
########################################

install_node () {
  REPO=$1
  NAME=$(basename $REPO)
  cd $NODE_DIR

  if [ -d "$NAME" ]; then
    echo "Updating $NAME"
    cd $NAME
    git pull
    cd ..
  else
    echo "Installing $NAME"
    git clone $REPO
  fi

  if [ -f "$NAME/requirements.txt" ]; then
    pip install -r "$NAME/requirements.txt"
  fi
}

install_node https://github.com/ltdrdata/ComfyUI-Manager
install_node https://github.com/cubiq/ComfyUI_essentials
install_node https://github.com/kijai/ComfyUI-KJNodes
install_node https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
install_node https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes
install_node https://github.com/PGCRT/CRT-Nodes
install_node https://github.com/yolain/ComfyUI-Easy-Use
install_node https://github.com/pythongosssss/ComfyUI-Custom-Scripts
install_node https://github.com/chflame163/ComfyUI_LayerStyle

########################################
# 다운로드 함수 (이어받기 지원)
########################################

download_if_missing () {
  FILE=$1
  URL=$2
  HEADER=$3

  if [ -f "$FILE" ]; then
    echo "Exists: $FILE"
  else
    echo "Downloading: $FILE"
    if [ -z "$HEADER" ]; then
      wget -c -O "$FILE" "$URL"
    else
      wget -c --header="$HEADER" -O "$FILE" "$URL"
    fi
  fi
}

########################################
# Diffusion Models (Civitai)
########################################

download_if_missing \
"$MODEL_DIR/diffusion_models/WAN2_2_FULL_FP8.safetensors" \
"https://civitai.com/api/download/models/2555640?type=Model&format=SafeTensor&size=full&fp=fp8&token=$CIVITAI_TOKEN"

download_if_missing \
"$MODEL_DIR/diffusion_models/WAN2_2_PRUNED_FP8.safetensors" \
"https://civitai.com/api/download/models/2513182?type=Model&format=SafeTensor&size=pruned&fp=fp8&token=$CIVITAI_TOKEN"

########################################
# LoRA
########################################

download_if_missing \
"$MODEL_DIR/loras/SVI_HIGH.safetensors" \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Stable-Video-Infinity/v2.0/SVI_v2_PRO_Wan2.2-I2V-A14B_HIGH_lora_rank_128_fp16.safetensors" \
"Authorization: Bearer $HF_TOKEN"

download_if_missing \
"$MODEL_DIR/loras/SVI_LOW.safetensors" \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Stable-Video-Infinity/v2.0/SVI_v2_PRO_Wan2.2-I2V-A14B_LOW_lora_rank_128_fp16.safetensors" \
"Authorization: Bearer $HF_TOKEN"

download_if_missing \
"$MODEL_DIR/loras/WAN22_LIGHTX2V_HIGH.safetensors" \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_Lightx2v/Wan_2_2_I2V_A14B_HIGH_lightx2v_4step_lora_v1030_rank_64_bf16.safetensors" \
"Authorization: Bearer $HF_TOKEN"

download_if_missing \
"$MODEL_DIR/loras/LIGHTX2V_DISTILL_480P.safetensors" \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" \
"Authorization: Bearer $HF_TOKEN"

########################################
# VAE
########################################

download_if_missing \
"$MODEL_DIR/vae/wan_2.1_vae.safetensors" \
"https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" \
"Authorization: Bearer $HF_TOKEN"

########################################
# Text Encoder
########################################

download_if_missing \
"$MODEL_DIR/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
"https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
"Authorization: Bearer $HF_TOKEN"

echo "===== AUTO PROVISION COMPLETE ====="
