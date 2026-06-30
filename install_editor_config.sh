#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="${REPO_DIR:-$PWD}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.editor-config-backup-$(date +%Y%m%d-%H%M%S)}"
SYNC_LAZY="${SYNC_LAZY:-1}"

echo "[INFO] repo dir   : ${REPO_DIR}"
echo "[INFO] backup dir : ${BACKUP_DIR}"

backup_if_exists() {
    local target="$1"

    if [[ -e "$target" || -L "$target" ]]; then
        mkdir -p "$BACKUP_DIR"
        echo "[INFO] backup $target -> $BACKUP_DIR/"
        mv "$target" "$BACKUP_DIR/"
    fi
}

copy_if_exists() {
    local src="$1"
    local dst="$2"

    if [[ -e "$src" ]]; then
        echo "[INFO] copy $src -> $dst"
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
    else
        echo "[WARN] missing $src, skip"
    fi
}

# Backup old editor configs
backup_if_exists "$HOME/.config/nvim"
backup_if_exists "$HOME/.vim"
backup_if_exists "$HOME/.vimrc"
backup_if_exists "$HOME/.gvimrc"
backup_if_exists "$HOME/.ideavimrc"

# Install new configs
copy_if_exists "${REPO_DIR}/nvim" "$HOME/.config/nvim"
copy_if_exists "${REPO_DIR}/vim" "$HOME/.vim"
copy_if_exists "${REPO_DIR}/vimrc" "$HOME/.vimrc"
copy_if_exists "${REPO_DIR}/gvimrc" "$HOME/.gvimrc"
copy_if_exists "${REPO_DIR}/ideavimrc" "$HOME/.ideavimrc"

# Debian/Ubuntu fd-find compatibility
mkdir -p "$HOME/.local/bin"
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

# Sync LazyVim plugins
if [[ "${SYNC_LAZY}" == "1" ]]; then
    if command -v nvim >/dev/null 2>&1; then
        echo "[INFO] syncing LazyVim plugins..."
        nvim --headless "+Lazy! sync" +qa || true
    elif [[ -x "/opt/nvim-linux-x86_64/bin/nvim" ]]; then
        echo "[INFO] syncing LazyVim plugins with /opt nvim..."
        /opt/nvim-linux-x86_64/bin/nvim --headless "+Lazy! sync" +qa || true
    else
        echo "[WARN] nvim not found, skip Lazy sync"
    fi
fi

echo
echo "[DONE] editor config installed"
echo
echo "Check:"
echo "  ls -la ~/.config/nvim"
echo "  ls -la ~/.vim ~/.vimrc"
echo
echo "Run:"
echo "  nvim"
echo "  vim"
