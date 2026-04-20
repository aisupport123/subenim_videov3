#!/usr/bin/env bash
set -Eeuo pipefail

source /venv/main/bin/activate

WORKSPACE="${WORKSPACE:-/workspace}"
COMFYUI_DIR="${WORKSPACE}/ComfyUI"
CUSTOM_NODES_DIR="${COMFYUI_DIR}/custom_nodes"
STATE_DIR="${WORKSPACE}/.startup_state"
mkdir -p "$STATE_DIR"

UPDATE_COMFYUI="${UPDATE_COMFYUI:-0}"
UPDATE_NODES="${UPDATE_NODES:-0}"
INSTALL_NODE_REQS="${INSTALL_NODE_REQS:-1}"
INSTALL_BASE_REQS="${INSTALL_BASE_REQS:-1}"
PIP_DISABLE_CACHE="${PIP_DISABLE_CACHE:-0}"

PIP_ARGS=()
if [[ "$PIP_DISABLE_CACHE" == "1" ]]; then
  PIP_ARGS+=(--no-cache-dir)
fi

APT_PACKAGES=()
PIP_PACKAGES=()

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
  "https://github.com/Starnodes2024/ComfyUI_StarNodes"
  "https://github.com/DesertPixelAi/ComfyUI-Desert-Pixel-Nodes"
  "https://github.com/Fannovel16/comfyui_controlnet_aux"
  "https://github.com/GACLove/ComfyUI-VFI"
  "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
  "https://github.com/teskor-hub/comfyui-teskors-utils"
  "https://github.com/PozzettiAndrea/ComfyUI-SAM3"
  "https://github.com/ClownsharkBatwing/ComfyUI-ClownsharK"
  "https://github.com/LeonQ8/ComfyUI-Dynamic-Lora-Scheduler"
  "https://github.com/PGCRT/CRT-Nodes"
  "https://github.com/evanspearman/ComfyMath"
)

CLIP_MODELS=(
  "https://huggingface.co/vilone60/videov3/resolve/main/klip_vision.safetensors"
)

TEXT_ENCODERS=(
  "https://huggingface.co/vilone60/videov3/resolve/main/text_enc.safetensors"
)

VAE_MODELS=(
  "https://huggingface.co/vilone60/videov3/resolve/main/vae.safetensors"
)

DETECTION_MODELS=(
  "https://huggingface.co/vilone60/videov3/resolve/main/vitpose_h_wholebody_data.bin"
  "https://huggingface.co/vilone60/videov3/resolve/main/vitpose_h_wholebody_model.onnx"
  "https://huggingface.co/vilone60/videov3/resolve/main/yolov10m.onnx"
)

CONTROLNET_MODELS=(
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_Uni3C_controlnet_fp16.safetensors"
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
  "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"
)

DIFFUSION_MODELS=(
  "https://huggingface.co/vilone60/videov3/resolve/main/WanModel.safetensors"
)

SAM_MODELS=(
  "https://huggingface.co/vilone60/videov3/resolve/main/sam2.1_hiera_base_plus.safetensors"
)

UNET_MODELS=()

log() {
  echo "[startup] $*"
}

repo_dir_name() {
  local repo="$1"
  local name
  name="$(basename "$repo")"
  name="${name%.git}"
  printf '%s\n' "$name"
}

provisioning_get_apt_packages() {
  if [[ ${#APT_PACKAGES[@]} -eq 0 ]]; then
    return
  fi
  log "Installing apt packages..."
  sudo apt-get update
  sudo apt-get install -y "${APT_PACKAGES[@]}"
}

provisioning_clone_comfyui() {
  if [[ ! -d "$COMFYUI_DIR/.git" ]]; then
    log "Cloning ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
  elif [[ "$UPDATE_COMFYUI" == "1" ]]; then
    log "Updating ComfyUI..."
    git -C "$COMFYUI_DIR" pull --ff-only || true
  else
    log "ComfyUI already exists, skip update"
  fi
}

provisioning_install_base_reqs() {
  [[ "$INSTALL_BASE_REQS" == "1" ]] || return

  local req_file="$COMFYUI_DIR/requirements.txt"
  local stamp_file="$STATE_DIR/comfyui_requirements.sha256"
  [[ -f "$req_file" ]] || return

  local current_hash
  current_hash="$(sha256sum "$req_file" | awk '{print $1}')"
  local saved_hash=""
  [[ -f "$stamp_file" ]] && saved_hash="$(cat "$stamp_file")"

  if [[ "$current_hash" == "$saved_hash" ]]; then
    log "Base requirements unchanged, skip"
    return
  fi

  log "Installing base requirements..."
  pip install "${PIP_ARGS[@]}" -r "$req_file"
  printf '%s\n' "$current_hash" > "$stamp_file"
}

provisioning_get_pip_packages() {
  if [[ ${#PIP_PACKAGES[@]} -eq 0 ]]; then
    return
  fi
  log "Installing extra pip packages..."
  pip install "${PIP_ARGS[@]}" "${PIP_PACKAGES[@]}"
}

provisioning_get_nodes() {
  mkdir -p "$CUSTOM_NODES_DIR"

  local -A seen=()
  local repo dir path requirements current_commit stamp_file stamped_commit

  for repo in "${NODES[@]}"; do
    [[ -n "${seen[$repo]+x}" ]] && continue
    seen[$repo]=1

    dir="$(repo_dir_name "$repo")"
    path="$CUSTOM_NODES_DIR/$dir"

    if [[ ! -d "$path/.git" ]]; then
      log "Cloning node: $dir"
      git clone --recursive "$repo" "$path" || {
        log "Clone failed: $repo"
        continue
      }
    elif [[ "$UPDATE_NODES" == "1" ]]; then
      log "Updating node: $dir"
      (
        cd "$path"
        git pull --ff-only --recurse-submodules || {
          git fetch --all --tags
          branch="$(git rev-parse --abbrev-ref HEAD)"
          git reset --hard "origin/$branch"
          git submodule update --init --recursive
        }
      )
    else
      log "Node exists, skip update: $dir"
    fi

    [[ "$INSTALL_NODE_REQS" == "1" ]] || continue

    requirements="$path/requirements.txt"
    [[ -f "$requirements" ]] || continue

    current_commit="$(git -C "$path" rev-parse HEAD 2>/dev/null || echo no-git)"
    stamp_file="$path/.requirements_installed_for_commit"
    stamped_commit=""
    [[ -f "$stamp_file" ]] && stamped_commit="$(cat "$stamp_file")"

    if [[ "$current_commit" == "$stamped_commit" ]]; then
      log "Node requirements already installed for $dir @ $current_commit"
      continue
    fi

    log "Installing deps for $dir..."
    if pip install "${PIP_ARGS[@]}" -r "$requirements"; then
      printf '%s\n' "$current_commit" > "$stamp_file"
    else
      log "pip requirements failed for $dir"
    fi
  done
}

provisioning_get_files() {
  if [[ $# -lt 2 ]]; then
    return
  fi

  local dir="$1"
  shift
  local files=("$@")
  local url filename tmp_path final_path

  mkdir -p "$dir"
  log "Checking ${#files[@]} file(s) in $dir"

  for url in "${files[@]}"; do
    filename="$(basename "${url%%\?*}")"
    final_path="$dir/$filename"
    tmp_path="$final_path.part"

    if [[ -f "$final_path" && -s "$final_path" ]]; then
      log "Exists: $filename"
      continue
    fi

    log "Downloading: $filename"

    if [[ -n "${HF_TOKEN:-}" && "$url" =~ huggingface\.co ]]; then
      wget --header="Authorization: Bearer $HF_TOKEN" \
        -O "$tmp_path" --content-disposition --show-progress -e dotbytes=4M "$url"
    elif [[ -n "${CIVITAI_TOKEN:-}" && "$url" =~ civitai\.com ]]; then
      wget --header="Authorization: Bearer $CIVITAI_TOKEN" \
        -O "$tmp_path" --content-disposition --show-progress -e dotbytes=4M "$url"
    else
      wget -O "$tmp_path" --content-disposition --show-progress -e dotbytes=4M "$url"
    fi

    if [[ ! -f "$tmp_path" || ! -s "$tmp_path" ]]; then
      log "Download failed or empty file: $filename"
      rm -f "$tmp_path"
      exit 1
    fi

    mv "$tmp_path" "$final_path"
  done
}

provisioning_start() {
  echo
  echo "##############################################"
  echo "# subenim VIDEO V3 startup                   #"
  echo "##############################################"
  echo

  provisioning_get_apt_packages
  provisioning_clone_comfyui
  provisioning_install_base_reqs
  provisioning_get_nodes
  provisioning_get_pip_packages

  provisioning_get_files "$COMFYUI_DIR/models/clip" "${CLIP_MODELS[@]}"
  provisioning_get_files "$COMFYUI_DIR/models/clip_vision" "${CLIP_VISION[@]}"
  provisioning_get_files "$COMFYUI_DIR/models/text_encoders" "${TEXT_ENCODERS[@]}"
  provisioning_get_files "$COMFYUI_DIR/models/vae" "${VAE_MODELS[@]}"
  provisioning_get_files "$COMFYUI_DIR/models/unet" "${UNET_MODELS[@]}"
  provisioning_get_files "$COMFYUI_DIR/models/detection" "${DETECTION_MODELS[@]}"
  provisioning_get_files "$COMFYUI_DIR/models/loras" "${LORAS[@]}"
  provisioning_get_files "$COMFYUI_DIR/models/diffusion_models" "${DIFFUSION_MODELS[@]}"
  provisioning_get_files "$COMFYUI_DIR/models/sams" "${SAM_MODELS[@]}"
  provisioning_get_files "$COMFYUI_DIR/models/controlnet" "${CONTROLNET_MODELS[@]}"

  echo
  log "Provisioning completed. Starting ComfyUI..."
  echo
}

if [[ ! -f /.noprovisioning ]]; then
  provisioning_start
fi

echo -e "${MAGENTA}"
echo "███████╗██╗   ██╗██████╗ ███████╗███╗   ██╗██╗███╗   ███╗"
echo "██╔════╝██║   ██║██╔══██╗██╔════╝████╗  ██║██║████╗ ████║"
echo "███████╗██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║██╔████╔██║"
echo "╚════██║██║   ██║██╔══██╗██╔══╝  ██║╚██╗██║██║██║╚██╔╝██║"
echo "███████║╚██████╔╝██████╔╝███████╗██║ ╚████║██║██║ ╚═╝ ██║"
echo "╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝╚═╝     ╚═╝"
echo -e "${NC}"
echo -e "${CYAN}[subenim] >> SYSTEM BOOT <<${NC}"

echo "=== subenim запускает ComfyUI ==="
cd "$COMFYUI_DIR"
exec python main.py --listen 0.0.0.0 --port 8188
