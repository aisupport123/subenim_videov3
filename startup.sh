#!/bin/bash
set -e
source /venv/main/bin/activate

WORKSPACE=${WORKSPACE:-/workspace}
COMFYUI_DIR="${WORKSPACE}/ComfyUI"

echo "===  subenim запускает VIDEO GENERATOR V1 ==="

APT_PACKAGES=()           # если нужно — добавь sudo apt install ...
PIP_PACKAGES=()           # глобальные pip пакеты, если сверх requirements

NODES=(
    "https://github.com/kijai/ComfyUI-WanVideoWrapper"
    "https://github.com/chflame163/ComfyUI_LayerStyle"
    "https://github.com/yolain/ComfyUI-Easy-Use"
    "https://github.com/kijai/ComfyUI-KJNodes"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    "https://github.com/kijai/ComfyUI-segment-anything-2"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/fq393/ComfyUI-ZMG-Nodes"
    "https://github.com/kijai/ComfyUI-WanAnimatePreprocess"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/jnxmx/ComfyUI_HuggingFace_Downloader"
    "https://github.com/teskor-hub/NEW-UTILS.git"
    "https://github.com/aisupport123/subenim_nodes.git"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/Starnodes2024/ComfyUI_StarNodes"
    "https://github.com/DesertPixelAi/ComfyUI-Desert-Pixel-Nodes"
    "https://github.com/Fannovel16/comfyui_controlnet_aux"
    "https://github.com/GACLove/ComfyUI-VFI"
    "https://github.com/kijai/ComfyUI-WanVideoWrapper"
    "https://github.com/kijai/ComfyUI-WanAnimatePreprocess"
    "https://github.com/kijai/ComfyUI-KJNodes"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
    "https://github.com/teskor-hub/comfyui-teskors-utils"
    "https://github.com/PozzettiAndrea/ComfyUI-SAM3"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    "https://github.com/ClownsharkBatwing/ComfyUI-ClownsharK"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/LeonQ8/ComfyUI-Dynamic-Lora-Scheduler"
    "https://github.com/PGCRT/CRT-Nodes"
)

# ЗАГРУЗКА ФАЙЛОВ НУЖНЫХ
CLIP_MODELS=(
    "https://huggingface.co/vilone60/videov3/resolve/main/klip_vision.safetensors"
)

CLIPS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"
)

TEXT_ENCODERS=(
    "https://huggingface.co/vilone60/videov3/resolve/main/text_enc.safetensors"
)

UNET_MODELS=(
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
)

VAE_MODELS=(
    "https://huggingface.co/vilone60/videov3/resolve/main/vae.safetensors"
)

DETECTION_MODELS=(
    "https://huggingface.co/vilone60/videov3/resolve/main/Wan21_Uni3C_controlnet_fp16.safetensors"
    "https://huggingface.co/vilone60/videov3/resolve/main/vitpose_h_wholebody_data.bin"
    "https://huggingface.co/vilone60/videov3/resolve/main/vitpose_h_wholebody_model.onnx"
    "https://huggingface.co/vilone60/videov3/resolve/main/yolov10m.onnx"
)

LORAS=(
    "https://huggingface.co/vilone60/videov3/resolve/main/WanFun.reworked.safetensors"
    "https://huggingface.co/vilone60/videov3/resolve/main/light.safetensors"
    "https://huggingface.co/vilone60/videov3/resolve/main/WanPusa.safetensors"
    "https://huggingface.co/vilone60/videov3/resolve/main/wan.reworked.safetensors"
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors"
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_AccVid_I2V_480P_14B_lora_rank32_fp16.safetensors"
)

CLIP_VISION=(
    "https://huggingface.co/vilone60/videov3/resolve/main/klip_vision.safetensors"
)

DEFFUSION=(
    "https://huggingface.co/vilone60/videov3/resolve/main/WanModel.safetensors"
)

SAM=(
    "https://huggingface.co/vilone60/videov3/resolve/main/sam2.1_hiera_base_plus.safetensors"
)

### ─────────────────────────────────────────────
### DO NOT EDIT BELOW UNLESS YOU KNOW WHAT YOU ARE DOING
### ─────────────────────────────────────────────

function provisioning_start() {
    echo ""
    echo "##############################################"
    echo "# FUCK THIS WORLD                            #"
    echo "# subenim_v4 2026-2027                       #"
    echo "# BY @againstdrigs                           #"
    echo "##############################################"
    echo ""

    provisioning_get_apt_packages
    provisioning_clone_comfyui
    provisioning_install_base_reqs
    provisioning_get_nodes
    provisioning_get_pip_packages

    provisioning_get_files "${COMFYUI_DIR}/models/clip"               "${CLIP_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/clip_vision"        "${CLIP_VISION[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/text_encoders"      "${TEXT_ENCODERS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/vae"                "${VAE_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/unet"               "${UNET_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/detection"          "${DETECTION_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/loras"              "${LORAS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/diffusion_models"   "${DEFFUSION[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/sams"               "${SAM[@]}"

    echo ""
    echo "subenim настроил → Starting ComfyUI..."
    echo ""
}

function provisioning_clone_comfyui() {
    if [[ ! -d "${COMFYUI_DIR}" ]]; then
        echo "subenim клонирует ComfyUI..."
        git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}"
    fi
    cd "${COMFYUI_DIR}"
}

function provisioning_install_base_reqs() {
    if [[ -f requirements.txt ]]; then
        echo "subenim установливает base requirements..."
        pip install --no-cache-dir -r requirements.txt
    fi
}

function provisioning_get_apt_packages() {
    if [[ ${#APT_PACKAGES[@]} -gt 0 ]]; then
        echo "subenim устанавливает apt packages..."
        sudo apt update && sudo apt install -y "${APT_PACKAGES[@]}"
    fi
}

function provisioning_get_pip_packages() {
    if [[ ${#PIP_PACKAGES[@]} -gt 0 ]]; then
        echo "subenim устанавливает extra pip packages..."
        pip install --no-cache-dir "${PIP_PACKAGES[@]}"
    fi
}

function provisioning_get_nodes() {
    mkdir -p "${COMFYUI_DIR}/custom_nodes"
    cd "${COMFYUI_DIR}/custom_nodes"

    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="./${dir}"

        if [[ -d "$path" ]]; then
            echo "Updating node: $dir"
            (cd "$path" && git pull --ff-only 2>/dev/null || { git fetch && git reset --hard origin/main; })
        else
            echo "Cloning node: $dir"
            git clone "$repo" "$path" --recursive || echo " [!] Clone failed: $repo"
        fi

        requirements="${path}/requirements.txt"
        if [[ -f "$requirements" ]]; then
            echo "Installing deps for $dir..."
            pip install --no-cache-dir -r "$requirements" || echo " [!] pip requirements failed for $dir"
        fi
    done
}

function provisioning_get_files() {
    if [[ $# -lt 2 ]]; then return; fi
    local dir="$1"
    shift
    local files=("$@")

    mkdir -p "$dir"
    echo "Скачивание ${#files[@]} file(s) → $dir..."

    for url in "${files[@]}"; do
        echo "→ $url"
        local filename
        filename="$(basename "${url%%\?*}")"

        if [[ -f "$dir/$filename" ]]; then
            echo " [✓] Уже существует: $filename"
            echo ""
            continue
        fi

        if [[ -n "$HF_TOKEN" && "$url" =~ huggingface\.co ]]; then
            wget --header="Authorization: Bearer $HF_TOKEN" \
                -nc --content-disposition --show-progress -e dotbytes=4M \
                -P "$dir" "$url"
        elif [[ -n "$CIVITAI_TOKEN" && "$url" =~ civitai\.com ]]; then
            wget --header="Authorization: Bearer $CIVITAI_TOKEN" \
                -nc --content-disposition --show-progress -e dotbytes=4M \
                -P "$dir" "$url"
        else
            wget -nc --content-disposition --show-progress -e dotbytes=4M \
                -P "$dir" "$url"
        fi

        if [[ ! -f "$dir/$filename" ]]; then
            echo " [!] Download failed or file missing: $filename"
            exit 1
        fi

        echo ""
    done
}

# Запуск provisioning если не отключен
if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi

# Запуск ComfyUI
echo "=== subenim запускает ComfyUI ==="
cd "${COMFYUI_DIR}"
python main.py --listen 0.0.0.0 --port 8188

echo -e "${MAGENTA}"
echo "███████╗██╗   ██╗██████╗ ███████╗███╗   ██╗██╗███╗   ███╗"
echo "██╔════╝██║   ██║██╔══██╗██╔════╝████╗  ██║██║████╗ ████║"
echo "███████╗██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║██╔████╔██║"
echo "╚════██║██║   ██║██╔══██╗██╔══╝  ██║╚██╗██║██║██║╚██╔╝██║"
echo "███████║╚██████╔╝██████╔╝███████╗██║ ╚████║██║██║ ╚═╝ ██║"
echo "╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝╚═╝     ╚═╝"
echo -e "${NC}"
echo -e "${CYAN}[subenim] >> SYSTEM BOOT <<${NC}"
