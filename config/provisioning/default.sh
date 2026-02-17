#!/bin/bash

log() { echo -e "\n[Provision] $1\n"; }

########################################
# 환경 변수 확인
########################################

if [ -z "$CIVITAI_TOKEN" ]; then
  echo "CIVITAI_TOKEN not set"
fi

export HF_HUB_ENABLE_HF_TRANSFER=1

########################################
# 경로
########################################

COMFY="/workspace/ComfyUI"
MODELS="$COMFY/models"
CUSTOM="$COMFY/custom_nodes"

########################################
# 패키지
########################################

apt update || true
apt install -y aria2 git ffmpeg || true

pip install huggingface_hub hf_transfer opencv-python-headless imageio-ffmpeg || true

########################################
# 폴더
########################################

mkdir -p \
  $MODELS/diffusion_models \
  $MODELS/text_encoders \
  $MODELS/vae \
  $MODELS/loras

mkdir -p $CUSTOM

########################################
# 다운로드 함수
########################################

download() {
  local dir="$1"
  local url="$2"

  mkdir -p "$dir"

  echo "Downloading: $url"

  if [[ "$url" == *"civitai.com"* ]]; then
    aria2c -x 8 -s 8 -k 1M \
      --header="Authorization: Bearer ${CIVITAI_TOKEN}" \
      -d "$dir" "$url" || true
  else
    aria2c -x 8 -s 8 -k 1M -d "$dir" "$url" || true
  fi
}

########################################
# 노드 설치
########################################

NODES=(
"https://github.com/ltdrdata/ComfyUI-Manager"
"https://github.com/cubiq/ComfyUI_essentials"
"https://github.com/kijai/ComfyUI-KJNodes"
"https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
"https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes"
"https://github.com/PGCRT/CRT-Nodes"
"https://github.com/yolain/ComfyUI-Easy-Use"
"https://github.com/chflame163/ComfyUI_LayerStyle"
"https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
)

for repo in "${NODES[@]}"; do
  name=$(basename "$repo")
  if [ ! -d "$CUSTOM/$name" ]; then
    git clone "$repo" "$CUSTOM/$name" || true
  fi
done

########################################
# 모델 다운로드
########################################

download "$MODELS/diffusion_models" \
"https://civitai.com/api/download/models/2513182?type=Model&format=SafeTensor&size=pruned&fp=fp8"

download "$MODELS/diffusion_models" \
"https://civitai.com/api/download/models/2388627?type=Model&format=SafeTensor&size=full&fp=fp8"

download "$MODELS/loras" \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Stable-Video-Infinity/v2.0/SVI_v2_PRO_Wan2.2-I2V-A14B_HIGH_lora_rank_128_fp16.safetensors"

download "$MODELS/loras" \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Stable-Video-Infinity/v2.0/SVI_v2_PRO_Wan2.2-I2V-A14B_LOW_lora_rank_128_fp16.safetensors"

download "$MODELS/vae" \
"https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"

download "$MODELS/text_encoders" \
"https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

echo "Provisioning finished."
