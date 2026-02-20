#!/bin/bash
set -e

echo "========================================"
echo "   ComfyUI + LTX2 FULL AUTO MASTER SETUP"
echo "========================================"

########################################
# 기본 경로 설정
########################################

VENV_PYTHON="/venv/main/bin/python"
VENV_PIP="/venv/main/bin/pip"

WORKSPACE="/workspace"
COMFY="$WORKSPACE/ComfyUI"
MODEL_DIR="$COMFY/models"
CUSTOM="$COMFY/custom_nodes"

########################################
# 공용 함수
########################################

install_node() {
    REPO_URL=$1
    NAME=$(basename "$REPO_URL")
    if [ ! -d "$CUSTOM/$NAME" ]; then
        echo "Installing node: $NAME"
        git clone "$REPO_URL" "$CUSTOM/$NAME"
    else
        echo "Node already exists: $NAME"
    fi
}

download_if_missing() {
    FILE_PATH=$1
    URL=$2
    if [ ! -f "$FILE_PATH" ]; then
        echo "Downloading $(basename $FILE_PATH)"
        mkdir -p "$(dirname "$FILE_PATH")"
        wget -O "$FILE_PATH" "$URL"
    else
        echo "Already exists: $(basename $FILE_PATH)"
    fi
}

########################################
# 1. Python 환경 고정
########################################

echo "Fixing Python environment..."

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
# 2. 커스텀 노드 설치
########################################

mkdir -p "$CUSTOM"
cd "$CUSTOM"

install_node https://github.com/ltdrdata/ComfyUI-Manager
install_node https://github.com/cubiq/ComfyUI_essentials
install_node https://github.com/kijai/ComfyUI-KJNodes
install_node https://github.com/yolain/ComfyUI-Easy-Use
install_node https://github.com/princepainter/ComfyUI-PainterLTXV2
install_node https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
install_node https://github.com/olduvai-jp/ComfyUI-S3-IO

########################################
# 3. 노드 requirements 자동 설치
########################################

for dir in */ ; do
    if [ -f "$dir/requirements.txt" ]; then
        echo "Installing requirements for $dir"
        $VENV_PIP install -r "$dir/requirements.txt" --no-cache-dir || true
    fi
done



########################################
# 5. ComfyUI 실행
########################################

echo "========================================"
echo "  🎉 LTX2 19B Distilled 완전 안정 세팅 완료!"
echo "========================================"

cd "$COMFY"
$VENV_PYTHON main.py --listen 0.0.0.0 --port 8188
