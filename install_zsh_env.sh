#!/usr/bin/env bash
set -Eeuo pipefail

USER_HOME="${HOME}"
CONFIG_REPO_DIR="${CONFIG_REPO_DIR:-$PWD}"

echo "[INFO] user: $(whoami)"
echo "[INFO] home: ${USER_HOME}"
echo "[INFO] config repo: ${CONFIG_REPO_DIR}"

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  zsh \
  git \
  curl \
  wget \
  vim \
  tmux \
  fzf \
  locales \
  unzip \
  zip \
  tar \
  xz-utils \
  gnupg \
  lsb-release \
  iproute2 \
  iputils-ping \
  dnsutils \
  net-tools \
  procps \
  less \
  jq \
  htop \
  build-essential \
  python3 \
  python3-pip \
  python3-venv \
  python3-dev \
  clang \
  libclang-dev \
  llvm-dev \
  pkg-config \
  build-essential

sudo locale-gen en_US.UTF-8 || true

# Oh My Zsh
if [[ ! -d "${USER_HOME}/.oh-my-zsh" ]]; then
  echo "[INFO] Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "[INFO] Oh My Zsh already exists."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-${USER_HOME}/.oh-my-zsh/custom}"

# Powerlevel10k
if [[ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "${ZSH_CUSTOM}/themes/powerlevel10k"
fi

# zsh-autosuggestions
if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
    "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
fi

# zsh-syntax-highlighting
if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
fi

# Copy config files
if [[ -f "${CONFIG_REPO_DIR}/zshrc" ]]; then
  cp "${CONFIG_REPO_DIR}/zshrc" "${USER_HOME}/.zshrc"
fi

if [[ -f "${CONFIG_REPO_DIR}/p10k.zsh" ]]; then
  cp "${CONFIG_REPO_DIR}/p10k.zsh" "${USER_HOME}/.p10k.zsh"
fi

if [[ -d "${CONFIG_REPO_DIR}/config/zsh" ]]; then
  mkdir -p "${USER_HOME}/.config"
  cp -a "${CONFIG_REPO_DIR}/config/zsh" "${USER_HOME}/.config/"
fi

# Change default shell
if command -v zsh >/dev/null 2>&1; then
  sudo chsh -s "$(command -v zsh)" "$(whoami)" || true
fi

echo "[DONE] zsh environment installed."
echo "Run:"
echo "  exec zsh"
