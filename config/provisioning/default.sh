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
# 5. 최소 안정 노드 세트 (LTX2용)
########################################

install_node https://github.com/ltdrdata/ComfyUI-Manager
install_node https://github.com/kijai/ComfyUI-KJNodes
install_node https://github.com/princepainter/ComfyUI-PainterLTXV2
install_node https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite

install_requirements

########################################
# 6. 추가 필수 패키지 안정화
########################################

pip install --upgrade torch torchvision torchaudio
pip install --upgrade transformers accelerate safetensors
pip install boto3 imageio-ffmpeg

########################################
# 7. 다운로드 함수
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


