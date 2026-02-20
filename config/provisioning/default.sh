########################################
# 0. 환경 변수
########################################

export HF_HUB_ENABLE_HF_TRANSFER=1

# HF_TOKEN은 Vast 환경 변수에 설정되어 있어야 함
# export HF_TOKEN=hf_xxxxx  ← 여기 적지 말 것

########################################
# 1. 기본 경로
########################################

COMFY_DIR="/workspace/ComfyUI"
MODEL_DIR="$COMFY_DIR/models"
CUSTOM_NODE_DIR="$COMFY_DIR/custom_nodes"

mkdir -p \
  $MODEL_DIR/diffusion_models \
  $MODEL_DIR/loras \
  $MODEL_DIR/text_encoders \
  $MODEL_DIR/checkpoints \
  $MODEL_DIR/vae \
  $MODEL_DIR/latent_upscale_models \
  $CUSTOM_NODE_DIR

########################################
# 2. 노드 자동 설치 함수
########################################

install_node () {
  REPO_URL=$1
  FOLDER_NAME=$(basename "$REPO_URL" .git)
  TARGET_DIR="$CUSTOM_NODE_DIR/$FOLDER_NAME"

  if [ -d "$TARGET_DIR" ]; then
    echo "✅ Node already exists: $FOLDER_NAME"
  else
    echo "⬇ Installing node: $FOLDER_NAME"
    git clone "$REPO_URL" "$TARGET_DIR"
  fi
}

########################################
# 3. 다운로드 함수
########################################

download_if_missing () {
  FILE_PATH=$1
  URL=$2
  HEADER=$3

  if [ -f "$FILE_PATH" ]; then
    echo "✅ Already exists: $FILE_PATH"
  else
    echo "⬇ Downloading: $FILE_PATH"
    wget --header="$HEADER" -O "$FILE_PATH" "$URL"
  fi
}

########################################
# 4. 필수 노드 설치
########################################

install_node https://github.com/ltdrdata/ComfyUI-Manager
install_node https://github.com/cubiq/ComfyUI_essentials
install_node https://github.com/kijai/ComfyUI-KJNodes
install_node https://github.com/yolain/ComfyUI-Easy-Use
install_node https://github.com/princepainter/ComfyUI-PainterLTXV2
install_node https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
install_node https://github.com/olduvai-jp/ComfyUI-S3-IO

