#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Optional dev tools installer for ranganhar container
# Installs:
#   - Rust / Cargo
#   - eza
#   - nvm + Node.js
#   - bun
#   - atuin
#   - Miniconda
#
# Run as normal user:
#   bash install_optional_dev_tools.sh
#
# Customize:
#   NODE_VERSION=24.15.0 bash install_optional_dev_tools.sh
#   NODE_VERSION=--lts bash install_optional_dev_tools.sh
#
# Skip something:
#   INSTALL_MINICONDA=0 INSTALL_BUN=0 bash install_optional_dev_tools.sh
# ============================================================

INSTALL_RUST="${INSTALL_RUST:-1}"
INSTALL_EZA="${INSTALL_EZA:-1}"
INSTALL_NVM="${INSTALL_NVM:-1}"
INSTALL_NODE="${INSTALL_NODE:-1}"
INSTALL_BUN="${INSTALL_BUN:-1}"
INSTALL_ATUIN="${INSTALL_ATUIN:-1}"
INSTALL_MINICONDA="${INSTALL_MINICONDA:-1}"

NODE_VERSION="${NODE_VERSION:-24.15.0}"
MINICONDA_DIR="${MINICONDA_DIR:-$HOME/miniconda3}"

NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"

export NVM_DIR
export BUN_INSTALL

log() {
  echo
  echo "========== $* =========="
}

warn() {
  echo "[WARN] $*" >&2
}

die() {
  echo "[ERROR] $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

append_once() {
  local line="$1"
  local file="$2"

  touch "$file"

  if ! grep -Fxq "$line" "$file"; then
    echo "$line" >>"$file"
  fi
}

ensure_basic_deps() {
  log "Installing basic dependencies"

  if ! need_cmd sudo && [[ "$(id -u)" -ne 0 ]]; then
    die "sudo not found. Please install sudo or run this script as root."
  fi

  run_sudo apt-get update

  run_sudo apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    xz-utils \
    unzip \
    tar \
    build-essential \
    pkg-config \
    libssl-dev \
    zsh

  run_sudo update-ca-certificates || true
}

install_rust() {
  if [[ "$INSTALL_RUST" != "1" ]]; then
    warn "Skipping Rust."
    return
  fi

  log "Installing Rust / Cargo"

  if [[ -x "$HOME/.cargo/bin/cargo" ]]; then
    echo "[INFO] Rust already installed: $("$HOME/.cargo/bin/cargo" --version)"
    return
  fi

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
    sh -s -- -y --profile default

  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"

  cargo --version
  rustc --version
}

install_eza() {
  if [[ "$INSTALL_EZA" != "1" ]]; then
    warn "Skipping eza."
    return
  fi

  log "Installing eza"

  if need_cmd eza || [[ -x "$HOME/.cargo/bin/eza" ]]; then
    echo "[INFO] eza already installed."
    return
  fi

  if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
  fi

  if ! need_cmd cargo; then
    die "cargo not found. Set INSTALL_RUST=1 or install Rust first."
  fi

  cargo install eza
  "$HOME/.cargo/bin/eza" --version || true
}

install_nvm_and_node() {
  if [[ "$INSTALL_NVM" != "1" ]]; then
    warn "Skipping nvm."
    return
  fi

  log "Installing nvm"

  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
  else
    echo "[INFO] nvm already installed."
  fi

  # shellcheck disable=SC1090
  source "$NVM_DIR/nvm.sh"

  export NVM_NODEJS_ORG_MIRROR="${NVM_NODEJS_ORG_MIRROR:-https://npmmirror.com/mirrors/node}"

  if [[ "$INSTALL_NODE" != "1" ]]; then
    warn "Skipping Node.js."
    return
  fi

  log "Installing Node.js"

  if [[ "$NODE_VERSION" == "--lts" || "$NODE_VERSION" == "lts" ]]; then
    nvm install --lts
    nvm alias default node
  else
    if ! nvm install "$NODE_VERSION"; then
      warn "Failed to install Node.js ${NODE_VERSION}. Falling back to latest LTS."
      nvm install --lts
    fi
    nvm alias default node
  fi

  nvm use default
  node --version
  npm --version
}

install_bun() {
  if [[ "$INSTALL_BUN" != "1" ]]; then
    warn "Skipping bun."
    return
  fi

  log "Installing bun"

  if [[ -x "$BUN_INSTALL/bin/bun" ]]; then
    echo "[INFO] bun already installed: $("$BUN_INSTALL/bin/bun" --version)"
    return
  fi

  curl -fsSL https://bun.sh/install | bash

  export PATH="$BUN_INSTALL/bin:$PATH"
  "$BUN_INSTALL/bin/bun" --version || true
}

install_atuin() {
  if [[ "$INSTALL_ATUIN" != "1" ]]; then
    warn "Skipping atuin."
    return
  fi

  log "Installing atuin"

  if need_cmd atuin || [[ -x "$HOME/.atuin/bin/atuin" ]]; then
    echo "[INFO] atuin already installed."
    return
  fi

  bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)

  if [[ -x "$HOME/.atuin/bin/atuin" ]]; then
    "$HOME/.atuin/bin/atuin" --version
  elif need_cmd atuin; then
    atuin --version
  fi
}

install_miniconda() {
  if [[ "$INSTALL_MINICONDA" != "1" ]]; then
    warn "Skipping Miniconda."
    return
  fi

  log "Installing Miniconda"

  if [[ -x "$MINICONDA_DIR/bin/conda" ]]; then
    echo "[INFO] Miniconda already installed: $("$MINICONDA_DIR/bin/conda" --version)"
    return
  fi

  local installer="/tmp/Miniconda3-latest-Linux-x86_64.sh"

  wget -O "$installer" https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

  bash "$installer" -b -p "$MINICONDA_DIR"

  "$MINICONDA_DIR/bin/conda" init zsh

  "$MINICONDA_DIR/bin/conda" config --set auto_activate_base false

  "$MINICONDA_DIR/bin/conda" --version
}

patch_zshrc_paths() {
  log "Patching ~/.zshrc helper lines"

  local zshrc="$HOME/.zshrc"

  append_once '' "$zshrc"
  append_once '# Added by install_optional_dev_tools.sh' "$zshrc"
  append_once '[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"' "$zshrc"
  append_once 'export NVM_DIR="$HOME/.nvm"' "$zshrc"
  append_once 'export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node' "$zshrc"
  append_once '[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"' "$zshrc"
  append_once 'export BUN_INSTALL="$HOME/.bun"' "$zshrc"
  append_once '[[ -d "$BUN_INSTALL/bin" ]] && export PATH="$BUN_INSTALL/bin:$PATH"' "$zshrc"
  append_once '[[ -r "$HOME/.atuin/bin/env" ]] && source "$HOME/.atuin/bin/env"' "$zshrc"
}

main() {
  echo "[INFO] user: $(whoami)"
  echo "[INFO] home: $HOME"
  echo "[INFO] node version target: $NODE_VERSION"
  echo "[INFO] miniconda dir: $MINICONDA_DIR"

  ensure_basic_deps
  install_rust
  install_eza
  install_nvm_and_node
  install_bun
  install_atuin
  install_miniconda
  patch_zshrc_paths

  log "Done"

  echo "Installed summary:"
  command -v zsh >/dev/null 2>&1 && zsh --version || true
  [[ -x "$HOME/.cargo/bin/cargo" ]] && "$HOME/.cargo/bin/cargo" --version || true
  [[ -x "$HOME/.cargo/bin/eza" ]] && "$HOME/.cargo/bin/eza" --version || true

  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck disable=SC1090
    source "$NVM_DIR/nvm.sh"
    node --version || true
    npm --version || true
  fi

  [[ -x "$BUN_INSTALL/bin/bun" ]] && "$BUN_INSTALL/bin/bun" --version || true
  [[ -x "$HOME/.atuin/bin/atuin" ]] && "$HOME/.atuin/bin/atuin" --version || true
  [[ -x "$MINICONDA_DIR/bin/conda" ]] && "$MINICONDA_DIR/bin/conda" --version || true

  echo
  echo "Next step:"
  echo "  exec zsh"
}

main "$@"
