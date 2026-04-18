#!/bin/bash

# === [subenim] INIT ===
source /venv/main/bin/activate

WORKSPACE=${WORKSPACE:-/workspace}
COMFYUI_DIR="${WORKSPACE}/ComfyUI"
VENV_PYTHON="/venv/main/bin/python"
VENV_PIP="/venv/main/bin/pip"

export PYTORCH_ALLOC_CONF="expandable_segments:True"
export HF_HUB_ENABLE_HF_TRANSFER=1

HF_REPO_ID="${HF_REPO_ID:-vilone60/videov3}"

# === LOGGING ===
LOG_FILE="${WORKSPACE}/provision.log"
mkdir -p "${WORKSPACE}"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[subenim] === LOG: $LOG_FILE ==="

if [ -z "$HF_TOKEN" ]; then
    echo -e "\033[0;31m[subenim][!] HF_TOKEN не найден!\033[0m"
    echo -e "\033[0;33m[subenim] Передай через -e HF_TOKEN=hf_...\033[0m"
fi

echo "[subenim] === COMFYUI START ==="

# === [subenim] SETUP ===
$VENV_PIP install --no-cache-dir hf_transfer || echo "[subenim] ⚠️ hf_transfer install failed"

echo "[subenim] >>> Оптимизация DWPose..."
$VENV_PIP uninstall -y pynvml || true
$VENV_PIP install --no-cache-dir nvidia-ml-py || echo "[subenim] ⚠️ nvidia-ml-py install failed"
$VENV_PIP install --no-cache-dir onnxruntime-gpu \
    --extra-index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/pypi/simple/ \
    || echo "[subenim] ⚠️ onnxruntime-gpu install failed"

# === [subenim] NODES ===
NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
    "https://github.com/ltdrdata/ComfyUI-Impact-Subpack"
    "https://github.com/kijai/ComfyUI-WanVideoWrapper"
    "https://github.com/kijai/ComfyUI-KJNodes"
    "https://github.com/kijai/ComfyUI-segment-anything-2"
    "https://github.com/kijai/ComfyUI-WanAnimatePreprocess"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
    "https://github.com/chflame163/ComfyUI_LayerStyle"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/yolain/ComfyUI-Easy-Use"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    "https://github.com/jnxmx/ComfyUI_HuggingFace_Downloader"
    "https://github.com/fq393/ComfyUI-ZMG-Nodes"
    "https://github.com/ClownsharkBatwing/RES4LYF"
    "https://github.com/chrisgoringe/cg-use-everywhere"
    "https://github.com/crystian/ComfyUI-Crystools"
    "https://github.com/plugcrypt/CRT-Nodes"
    "https://github.com/evanspearman/ComfyMath"
    "https://github.com/Fannovel16/comfyui_controlnet_aux"
    "https://github.com/Smirnov75/ComfyUI-mxToolkit"
    "https://github.com/TheLustriVA/ComfyUI-Image-Size-Tools"
    "https://github.com/ZhiHui6/zhihui_nodes_comfyui"
    "https://github.com/EllangoK/ComfyUI-post-processing-nodes"
    "https://github.com/teskor-hub/comfyui-teskors-utils"
    "https://github.com/hanjangma41/NEW-UTILSs"
    "https://github.com/WASasquatch/was-node-suite-comfyui"
    "https://github.com/Starnodes2024/ComfyUI_StarNodes"
    "https://github.com/DesertPixelAi/ComfyUI-Desert-Pixel-Nodes"
)

# === [subenim] DOWNLOAD FUNC ===
download_hf() {
    local file_or_url="$1"
    local dir="$2"
    local repo="${3:-$HF_REPO_ID}"

    mkdir -p "$dir"

    local repo_id
    local filename

    if [[ "$file_or_url" =~ huggingface\.co ]]; then
        repo_id=$(echo "$file_or_url" | sed -E 's|https://huggingface.co/([^/]+/[^/]+)/resolve/[^/]+/(.*)|\1|')
        filename=$(echo "$file_or_url" | sed -E 's|https://huggingface.co/([^/]+/[^/]+)/resolve/[^/]+/(.*)|\2|')
    else
        repo_id="$repo"
        filename="$file_or_url"
    fi

    if [ ! -f "$dir/$filename" ]; then
        echo "[subenim] 🚀 Download: $filename"

        local max_retries=3
        local attempt=1
        local success=0

        while [ $attempt -le $max_retries ]; do
            if $VENV_PYTHON -c "
from huggingface_hub import hf_hub_download
hf_hub_download(
    repo_id='$repo_id',
    filename='$filename',
    local_dir='$dir',
    local_dir_use_symlinks=False,
    token='$HF_TOKEN'
)
"; then
                success=1
                break
            else
                echo "[subenim] ⚠️ Retry $attempt/$max_retries: $filename"
                attempt=$((attempt + 1))
                sleep 3
            fi
        done

        if [ $success -eq 0 ]; then
            echo "[subenim] ❌ FAILED: $filename"
        fi
    else
        echo "[subenim] ✅ EXISTS: $filename"
    fi
}

# === [subenim] MAIN ===
function provisioning_start() {
    echo "[subenim] === SETUP START ==="

    provisioning_clone_comfyui
    provisioning_install_base_reqs
    provisioning_get_nodes

    echo "[subenim] >>> SOURCE: $HF_REPO_ID"

    # === MODELS ===
    download_hf "Wan21_Uni3C_controlnet_fp16.safetensors" "$COMFYUI_DIR/models/controlnet"
    download_hf "WanModel.safetensors"                    "$COMFYUI_DIR/models/diffusion_models"
    download_hf "vae.safetensors"                         "$COMFYUI_DIR/models/vae"
    download_hf "klip_vision.safetensors"                 "$COMFYUI_DIR/models/clip_vision"
    download_hf "text_enc.safetensors"                    "$COMFYUI_DIR/models/text_encoders"

    # === LORAS ===
    download_hf "WanFun.reworked.safetensors"             "$COMFYUI_DIR/models/loras"
    download_hf "light.safetensors"                       "$COMFYUI_DIR/models/loras"
    download_hf "wan.reworked.safetensors"                "$COMFYUI_DIR/models/loras"
    download_hf "WanPusa.safetensors"                     "$COMFYUI_DIR/models/loras"

    # === AUX ===
    download_hf "sam2.1_hiera_base_plus.safetensors"      "$COMFYUI_DIR/models/sam2"
    download_hf "vitpose_h_wholebody_model.onnx"          "$COMFYUI_DIR/models/detection"
    download_hf "vitpose_h_wholebody_data.bin"            "$COMFYUI_DIR/models/detection"
    download_hf "yolov10m.onnx"                           "$COMFYUI_DIR/models/detection"

    echo "[subenim] === DONE ==="
}

# === [subenim] CORE ===
function provisioning_clone_comfyui() {
    if [[ ! -d "${COMFYUI_DIR}" ]]; then
        echo "[subenim] Cloning ComfyUI..."
        git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}" \
            || { echo "[subenim] ❌ FAILED: clone ComfyUI"; exit 1; }
    else
        echo "[subenim] ✅ ComfyUI already exists, pulling latest..."
        git -C "${COMFYUI_DIR}" pull || echo "[subenim] ⚠️ git pull failed, continuing with existing"
    fi
}

function provisioning_install_base_reqs() {
    cd "${COMFYUI_DIR}"
    echo "[subenim] Installing ComfyUI requirements..."
    $VENV_PIP install --no-cache-dir -r requirements.txt \
        || { echo "[subenim] ❌ FAILED: base requirements"; exit 1; }
}

function provisioning_get_nodes() {
    mkdir -p "${COMFYUI_DIR}/custom_nodes"
    cd "${COMFYUI_DIR}/custom_nodes"

    local failed_nodes=()

    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        if [[ ! -d "$dir" ]]; then
            echo "[subenim] >>> Cloning node: $dir"
            if git clone "$repo" "$dir" --recursive --depth=1; then
                echo "[subenim] ✅ Cloned: $dir"
            else
                echo "[subenim] ❌ FAILED clone: $repo"
                failed_nodes+=("$repo")
                continue
            fi
        else
            echo "[subenim] ✅ EXISTS: $dir — pulling updates..."
            git -C "$dir" pull || echo "[subenim] ⚠️ git pull failed for $dir"
        fi

        # Install node dependencies if present
        if [[ -f "$dir/requirements.txt" ]]; then
            echo "[subenim] 📦 Installing deps: $dir"
            $VENV_PIP install --no-cache-dir -r "$dir/requirements.txt" \
                || echo "[subenim] ⚠️ Some deps failed for: $dir"
        fi

        # Run install.py if present
        if [[ -f "$dir/install.py" ]]; then
            echo "[subenim] 🔧 Running install.py: $dir"
            $VENV_PYTHON "$dir/install.py" \
                || echo "[subenim] ⚠️ install.py failed for: $dir"
        fi
    done

    if [ ${#failed_nodes[@]} -gt 0 ]; then
        echo "[subenim] ⚠️ Failed nodes:"
        for n in "${failed_nodes[@]}"; do
            echo "  - $n"
        done
    fi
}

provisioning_start

echo "[subenim] === LAUNCH READY ==="

MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${MAGENTA}"
echo "███████╗██╗   ██╗██████╗ ███████╗███╗   ██╗██╗███╗   ███╗"
echo "██╔════╝██║   ██║██╔══██╗██╔════╝████╗  ██║██║████╗ ████║"
echo "███████╗██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║██╔████╔██║"
echo "╚════██║██║   ██║██╔══██╗██╔══╝  ██║╚██╗██║██║██║╚██╔╝██║"
echo "███████║╚██████╔╝██████╔╝███████╗██║ ╚████║██║██║ ╚═╝ ██║"
echo "╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝╚═╝     ╚═╝"
echo -e "${NC}"
echo -e "${CYAN}[subenim] >> SYSTEM BOOT <<${NC}"
