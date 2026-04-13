#!/bin/bash
set -e

echo "🚀 Provisioning ANIMATOR V2.1 (VIDEO) started..."

apt-get update && apt-get install -y git wget aria2 python3-pip unzip

PIP="/venv/main/bin/pip"
COMFY="/workspace/ComfyUI"
MODELS="$COMFY/models"
NODES="$COMFY/custom_nodes"
WORKFLOWS="$COMFY/user/default/workflows"

echo "📦 Using pip: $PIP"

# ====================== CUSTOM NODES ======================
echo "📥 Cloning custom nodes..."
cd "$NODES"

git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git || true
git clone https://github.com/kijai/ComfyUI-WanAnimatePreprocess.git || true
git clone https://github.com/kijai/ComfyUI-KJNodes.git || true
git clone https://github.com/rgthree/rgthree-comfy.git || true
git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git || true
git clone https://github.com/teskor-hub/comfyui-teskors-utils.git || true
git clone https://github.com/PozzettiAndrea/ComfyUI-SAM3.git || true
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git || true
git clone https://github.com/ClownsharkBatwing/ComfyUI-ClownsharK.git || true
git clone https://github.com/cubiq/ComfyUI_essentials.git || true
git clone https://github.com/LeonQ8/ComfyUI-Dynamic-Lora-Scheduler.git || true
git clone https://github.com/PGCRT/CRT-Nodes.git || true

echo "📦 Installing node requirements..."
$PIP install --upgrade --force-reinstall opencv-python opencv-python-headless

for dir in */; do
  if [ -f "$dir/requirements.txt" ]; then
    echo "→ Installing requirements for $dir"
    $PIP install -r "$dir/requirements.txt" || true
  fi
done

# ====================== WORKFLOWS ======================
echo "📂 Copying workflows..."
mkdir -p "$WORKFLOWS"

cp /workspace/provisioning/animator_v2_1_0.json \
  "$WORKFLOWS/animator_v2_1_0.json" \
  2>/dev/null || echo "⚠️ animator_v2_1_0.json not found"

cp /workspace/provisioning/animator_v2_1_0_mask_mode.json \
  "$WORKFLOWS/animator_v2_1_0_mask_mode.json" \
  2>/dev/null || echo "⚠️ animator_v2_1_0_mask_mode.json not found"

# ====================== MODEL DIRS ======================
echo "📁 Creating model directories..."
mkdir -p \
  "$MODELS/diffusion_models" \
  "$MODELS/vae" \
  "$MODELS/clip_vision" \
  "$MODELS/clip" \
  "$MODELS/loras" \
  "$MODELS/detection" \
  "$MODELS/controlnet"

cd "$MODELS"

# ====================== CORE MODELS ======================
echo "📥 1. MAIN MODEL = Wan 2.2 Animate 14B (IMPORTANT FIX)"
aria2c -x 16 -s 16 --continue=true --dir="$MODELS/diffusion_models" \
  --out=WanModel.safetensors \
  "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors"

echo "📥 2. VAE"
aria2c -x 16 -s 16 --continue=true --dir="$MODELS/vae" \
  --out=mo_vae.safetensors \
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors"

echo "📥 3. CLIP Vision"
aria2c -x 16 -s 16 --continue=true --dir="$MODELS/clip_vision" \
  --out=klip_vision.safetensors \
  "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"

echo "📥 4. Text Encoder"
aria2c -x 16 -s 16 --continue=true --dir="$MODELS/clip" \
  --out=text_enc.safetensors \
  "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

# ====================== LORAS ======================
echo "📥 5. LoRA light"
aria2c -x 16 -s 16 --continue=true --dir="$MODELS/loras" \
  --out=light.safetensors \
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors" || true

echo "📥 6. LoRA wan_reworked"
aria2c -x 16 -s 16 --continue=true --dir="$MODELS/loras" \
  --out=wan_reworked.safetensors \
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_AccVid_I2V_480P_14B_lora_rank32_fp16.safetensors" || true

echo "📥 7. LoRA WanPusa"
aria2c -x 16 -s 16 --continue=true --dir="$MODELS/loras" \
  --out=WanPusa.safetensors \
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/loras/WanPusa.safetensors" || true

echo "📥 8. LoRA WanFun.reworked"
aria2c -x 16 -s 16 --continue=true --dir="$MODELS/loras" \
  --out=WanFun.reworked.safetensors \
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/loras/WanFun.reworked.safetensors" || true

echo "🔗 Creating symlink: wan.reworked.safetensors"
ln -sf "$MODELS/loras/wan_reworked.safetensors" \
       "$MODELS/loras/wan.reworked.safetensors" || true

# ====================== DETECTION ======================
echo "📥 9. Detection: yolov10m.onnx"
aria2c -x 16 -s 16 --continue=true --dir="$MODELS/detection" \
  --out=yolov10m.onnx \
  "https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/process_checkpoint/det/yolov10m.onnx"

echo "📥 10. Detection: vitpose_h_wholebody_model.onnx"
aria2c -x 16 -s 16 --continue=true --dir="$MODELS/detection" \
  --out=vitpose_h_wholebody_model.onnx \
  "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_model.onnx"

echo "📥 11. Detection: vitpose_h_wholebody_data.bin"
aria2c -x 16 -s 16 --continue=true --dir="$MODELS/detection" \
  --out=vitpose_h_wholebody_data.bin \
  "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_data.bin"

# ====================== CONTROLNET ======================
echo "📥 12. ControlNet"
aria2c -x 16 -s 16 --continue=true --dir="$MODELS/controlnet" \
  --out=Wan21_Uni3C_controlnet_fp16.safetensors \
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_Uni3C_controlnet_fp16.safetensors" || true

echo ""
echo "✅ ANIMATOR V2.1 setup finished"
echo "Main fix: Wan 2.2 Animate model is now used as WanModel.safetensors"
echo "If optional LoRAs fail, keep those slots on NONE."
echo "🔥 Ready."