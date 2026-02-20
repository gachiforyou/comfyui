########################################
# 0. 환경 변수
########################################

export HF_HUB_ENABLE_HF_TRANSFER=1

# HF_TOKEN은 Vast 환경변수에 이미 입력되어 있어야 함
# export HF_TOKEN=hf_xxxxx  ← 여기에 직접 적지 말 것

########################################
# 1. 기본 경로 설정
########################################

BASE="/workspace/ComfyUI/models"
MODEL_DIR="$BASE"

mkdir -p \
  $MODEL_DIR/diffusion_models \
  $MODEL_DIR/loras \
  $MODEL_DIR/text_encoders \
  $MODEL_DIR/checkpoints \
  $MODEL_DIR/vae \
  $MODEL_DIR/latent_upscale_models

########################################
# 2. 다운로드 함수
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
# 3. LTX2 19B Distilled 모델 세트
########################################

# 🔹 Diffusion Model
download_if_missing \
"$MODEL_DIR/diffusion_models/ltx-2-19b-distilled_transformer_only_bf16.safetensors" \
"https://huggingface.co/Kijai/LTXV2_comfy/resolve/main/diffusion_models/ltx-2-19b-distilled_transformer_only_bf16.safetensors" \
"Authorization: Bearer $HF_TOKEN"

# 🔹 Text Encoder (Gemma 3 12B)
download_if_missing \
"$MODEL_DIR/text_encoders/gemma_3_12B_it.safetensors" \
"https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it.safetensors" \
"Authorization: Bearer $HF_TOKEN"

# 🔹 Embedding Connector
download_if_missing \
"$MODEL_DIR/checkpoints/ltx-2-19b-embeddings_connector_distill_bf16.safetensors" \
"https://huggingface.co/Kijai/LTXV2_comfy/resolve/main/text_encoders/ltx-2-19b-embeddings_connector_distill_bf16.safetensors" \
"Authorization: Bearer $HF_TOKEN"

# 🔹 VAE (Video)
download_if_missing \
"$MODEL_DIR/vae/LTX2_video_vae_bf16.safetensors" \
"https://huggingface.co/Kijai/LTXV2_comfy/resolve/main/VAE/LTX2_video_vae_bf16.safetensors" \
"Authorization: Bearer $HF_TOKEN"

# 🔹 VAE (Audio)
download_if_missing \
"$MODEL_DIR/vae/LTX2_audio_vae_bf16.safetensors" \
"https://huggingface.co/Kijai/LTXV2_comfy/resolve/main/VAE/LTX2_audio_vae_bf16.safetensors" \
"Authorization: Bearer $HF_TOKEN"

# 🔹 LoRA (IC Detailer)
download_if_missing \
"$MODEL_DIR/loras/ltx-2-19b-ic-lora-detailer.safetensors" \
"https://huggingface.co/Lightricks/LTX-2-19b-IC-LoRA-Detailer/resolve/main/ltx-2-19b-ic-lora-detailer.safetensors" \
"Authorization: Bearer $HF_TOKEN"

# 🔹 Latent Upscaler
download_if_missing \
"$MODEL_DIR/latent_upscale_models/ltx-2-spatial-upscaler-x2-1.0.safetensors" \
"https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-spatial-upscaler-x2-1.0.safetensors" \
"Authorization: Bearer $HF_TOKEN"

echo "🎉 LTX2 19B Distilled 모델 세트 다운로드 완료!"
