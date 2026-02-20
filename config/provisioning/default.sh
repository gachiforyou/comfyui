########################################
# 0. 기본 설정
########################################

export HF_HUB_ENABLE_HF_TRANSFER=1

COMFY_DIR="/workspace/ComfyUI"
MODEL_DIR="$COMFY_DIR/models"
CUSTOM_NODE_DIR="$COMFY_DIR/custom_nodes"

########################################
# 1. ComfyUI 최신화
########################################

cd $COMFY_DIR
git pull
pip install -r requirements.txt

########################################
# 2. 폴더 생성
########################################

mkdir -p \
  $MODEL_DIR/diffusion_models \
  $MODEL_DIR/loras \
  $MODEL_DIR/text_encoders \
  $MODEL_DIR/checkpoints \
  $MODEL_DIR/vae \
  $MODEL_DIR/latent_upscale_models \
  $CUSTOM_NODE_DIR

########################################
# 3. 노드 설치 함수
########################################

install_node () {
  REPO_URL=$1
  FOLDER_NAME=$(basename "$REPO_URL")
  TARGET_DIR="$CUSTOM_NODE_DIR/$FOLDER_NAME"

  if [ -d "$TARGET_DIR" ]; then
    echo "✅ Node exists: $FOLDER_NAME"
  else
    echo "⬇ Installing node: $FOLDER_NAME"
    git clone "$REPO_URL" "$TARGET_DIR"
  fi
}

########################################
# 4. requirements 자동 설치
########################################

install_requirements () {
  for dir in $CUSTOM_NODE_DIR/*; do
    if [ -f "$dir/requirements.txt" ]; then
      echo "📦 Installing requirements for $(basename $dir)"
      pip install -r "$dir/requirements.txt"
    fi
  done
}

########################################
# 5. 네가 지정한 노드 전부 설치
########################################

install_node https://github.com/ltdrdata/ComfyUI-Manager
install_node https://github.com/cubiq/ComfyUI_essentials
install_node https://github.com/kijai/ComfyUI-KJNodes
install_node https://github.com/yolain/ComfyUI-Easy-Use
install_node https://github.com/princepainter/ComfyUI-PainterLTXV2
install_node https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
install_node https://github.com/olduvai-jp/ComfyUI-S3-IO

########################################
# 6. 노드 의존성 설치
########################################

install_requirements

########################################
# 7. 추가 패키지 안정화
########################################

pip install --upgrade transformers accelerate safetensors
pip install boto3 imageio-ffmpeg

########################################
# 8. 다운로드 함수
########################################

download_if_missing () {
  FILE_PATH=$1
  URL=$2

  if [ -f "$FILE_PATH" ]; then
    echo "✅ Already exists: $FILE_PATH"
  else
    echo "⬇ Downloading: $FILE_PATH"
    wget --header="Authorization: Bearer $HF_TOKEN" -O "$FILE_PATH" "$URL"
  fi
}

########################################
# 9. LTX2 19B Distilled 모델 세트
########################################

# Diffusion transformer_only
download_if_missing \
"$MODEL_DIR/diffusion_models/ltx-2-19b-distilled_transformer_only_bf16.safetensors" \
"https://huggingface.co/Kijai/LTXV2_comfy/resolve/main/diffusion_models/ltx-2-19b-distilled_transformer_only_bf16.safetensors"

# Full distilled checkpoint
download_if_missing \
"$MODEL_DIR/checkpoints/ltx-2-19b-distilled.safetensors" \
"https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-distilled.safetensors"

# Embedding connector
download_if_missing \
"$MODEL_DIR/checkpoints/ltx-2-19b-embeddings_connector_distill_bf16.safetensors" \
"https://huggingface.co/Kijai/LTXV2_comfy/resolve/main/text_encoders/ltx-2-19b-embeddings_connector_distill_bf16.safetensors"

# Text encoder
download_if_missing \
"$MODEL_DIR/text_encoders/gemma_3_12B_it.safetensors" \
"https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it.safetensors"

# VAE video
download_if_missing \
"$MODEL_DIR/vae/LTX2_video_vae_bf16.safetensors" \
"https://huggingface.co/Kijai/LTXV2_comfy/resolve/main/VAE/LTX2_video_vae_bf16.safetensors"

# VAE audio
download_if_missing \
"$MODEL_DIR/vae/LTX2_audio_vae_bf16.safetensors" \
"https://huggingface.co/Kijai/LTXV2_comfy/resolve/main/VAE/LTX2_audio_vae_bf16.safetensors"

# LoRA detailer
download_if_missing \
"$MODEL_DIR/loras/ltx-2-19b-ic-lora-detailer.safetensors" \
"https://huggingface.co/Lightricks/LTX-2-19b-IC-LoRA-Detailer/resolve/main/ltx-2-19b-ic-lora-detailer.safetensors"

# Latent upscaler
download_if_missing \
"$MODEL_DIR/latent_upscale_models/ltx-2-spatial-upscaler-x2-1.0.safetensors" \
"https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-spatial-upscaler-x2-1.0.safetensors"

echo "🎉 모든 노드 + LTX2 19B Distilled 세팅 완료!"
