# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

# -----------------------------
# Helper functions
# -----------------------------
path_prepend() {
    [[ -d "$1" ]] && export PATH="$1:$PATH"
}

ld_prepend() {
    [[ -d "$1" ]] && export LD_LIBRARY_PATH="$1:${LD_LIBRARY_PATH:-}"
}

# -----------------------------
# Basic paths
# -----------------------------
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/.TinyTeX/bin/x86_64-linux"
path_prepend "$HOME/.opencode/bin"
path_prepend "/opt/nvim-linux-x86_64/bin"
path_prepend "/opt/nvidia/nsight-systems/2024.6.1/bin"
path_prepend "/usr/local/NVIDIA-Nsight-Compute"

# -----------------------------
# CUDA auto-detection
# -----------------------------
for cuda_dir in /usr/local/cuda /usr/local/cuda-13.3 /usr/local/cuda-13 /usr/local/cuda-12.8 /usr/local/cuda-12; do
    if [[ -d "$cuda_dir" ]]; then
        export CUDA_HOME="$cuda_dir"
        path_prepend "$cuda_dir/bin"
        ld_prepend "$cuda_dir/lib64"
        break
    fi
done

# -----------------------------
# Project-specific environment
# -----------------------------
[[ -d "$HOME/file/tlm/python" ]] && export PYTHONPATH="${PYTHONPATH:-}:$HOME/file/tlm/python"
[[ -d "$HOME/file/superOpt/mirage" ]] && export MIRAGE_HOME="$HOME/file/superOpt/mirage"

export HF_HOME="$HOME/huggingface"
export HF_ENDPOINT="https://hf-mirror.com"

# -----------------------------
# NVM / Node
# -----------------------------
export NVM_DIR="$HOME/.nvm"
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
fi

# -----------------------------
# Bun
# -----------------------------
export BUN_INSTALL="$HOME/.bun"
path_prepend "$BUN_INSTALL/bin"
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# -----------------------------
# Conda
# -----------------------------
if [[ -x "$HOME/miniconda3/bin/conda" ]]; then
    __conda_setup="$("$HOME/miniconda3/bin/conda" shell.zsh hook 2>/dev/null)"
    if [[ $? -eq 0 ]]; then
        eval "$__conda_setup"
    elif [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
        source "$HOME/miniconda3/etc/profile.d/conda.sh"
    else
        path_prepend "$HOME/miniconda3/bin"
    fi
    unset __conda_setup
fi

# -----------------------------
# Oh My Zsh
# -----------------------------
ZSH_THEME="powerlevel10k/powerlevel10k"

[[ -r "$HOME/.config/zsh/vim-mode.zsh" ]] && source "$HOME/.config/zsh/vim-mode.zsh"
[[ -r "$HOME/.config/zsh/autosuggestion.zsh" ]] && source "$HOME/.config/zsh/autosuggestion.zsh"

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    z
    web-search
    tmux
)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
fi

bindkey -v
export KEYTIMEOUT=1

autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

# -----------------------------
# Proxy
# -----------------------------
function proxy() {
    local proxy_host="${PROXY_HOST:-host.docker.internal}"
    local proxy_port="${PROXY_PORT:-10808}"

    export http_proxy="http://${proxy_host}:${proxy_port}"
    export https_proxy="http://${proxy_host}:${proxy_port}"
    export all_proxy="socks5://${proxy_host}:${proxy_port}"

    export HTTP_PROXY="$http_proxy"
    export HTTPS_PROXY="$https_proxy"
    export ALL_PROXY="$all_proxy"

    echo "Proxy enabled: ${proxy_host}:${proxy_port}"
}

function unproxy() {
    unset https_proxy http_proxy all_proxy HTTPS_PROXY HTTP_PROXY ALL_PROXY
    echo "Proxy disabled"
}

# -----------------------------
# Aliases
# -----------------------------
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=always --group-directories-first --icons'
    alias ll='eza -la --icons --octal-permissions --group-directories-first'
    alias l='eza -blGF --header --git --color=always --group-directories-first --icons'
    alias llm='eza -lbGd --header --git --sort=modified --color=always --group-directories-first --icons'
    alias la='eza --long --all --group --group-directories-first'
    alias lx='eza -lbhHigUmuSa@ --time-style=long-iso --git --color-scale --color=always --group-directories-first --icons'
    alias lS='eza -1 --color=always --group-directories-first --icons'
    alias lt='eza --tree --level=2 --color=always --group-directories-first --icons'
    alias l.="eza -a | grep -E '^\.'"
else
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
fi

[[ -x "/usr/local/NVIDIA-Nsight-Compute/ncu" ]] && alias ncu="/usr/local/NVIDIA-Nsight-Compute/ncu"

# -----------------------------
# Claude helpers
# -----------------------------
export CLAUDE_CODE_EFFORT_LEVEL=ultracode

function claude() {
    unset https_proxy http_proxy all_proxy HTTPS_PROXY HTTP_PROXY ALL_PROXY

    local country
    country=$(curl -fsS --connect-timeout 3 https://ipinfo.io/country 2>/dev/null | tr -d '\n\r')

    if [[ "$country" == "CN" || -z "$country" ]]; then
        echo "Current IP is ${country:-unknown}, enabling proxy..."
        proxy

        country=$(curl -fsS --connect-timeout 3 https://ipinfo.io/country 2>/dev/null | tr -d '\n\r')

        if [[ "$country" == "CN" || -z "$country" ]]; then
            echo "Proxy enabled, but current IP is still ${country:-unknown}. Refusing to start claude."
            return 1
        fi
    fi

    echo "Current IP country: $country, starting claude..."
    command claude "$@"
}

function claude_allow() {
    unset https_proxy http_proxy all_proxy HTTPS_PROXY HTTP_PROXY ALL_PROXY

    local country
    country=$(curl -fsS --connect-timeout 3 https://ipinfo.io/country 2>/dev/null | tr -d '\n\r')

    if [[ "$country" == "CN" || -z "$country" ]]; then
        echo "Current IP is ${country:-unknown}, enabling proxy..."
        proxy

        country=$(curl -fsS --connect-timeout 3 https://ipinfo.io/country 2>/dev/null | tr -d '\n\r')

        if [[ "$country" == "CN" || -z "$country" ]]; then
            echo "Proxy enabled, but current IP is still ${country:-unknown}. Refusing to start claude."
            return 1
        fi
    fi

    echo "Current IP country: $country, starting claude..."
    command claude --dangerously-skip-permissions "$@"
}

# -----------------------------
# Atuin
# -----------------------------
if [[ -x "$HOME/.atuin/bin/atuin" ]]; then
    [[ -r "$HOME/.atuin/bin/env" ]] && source "$HOME/.atuin/bin/env"
    eval "$(atuin init zsh)"
elif command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh)"
fi

# -----------------------------
# FZF
# -----------------------------
[[ -r "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"

# -----------------------------
# Secrets
# Do not commit ~/.secrets.zsh to GitHub.
# -----------------------------
[[ -r "$HOME/.secrets.zsh" ]] && source "$HOME/.secrets.zsh"

# -----------------------------
# Powerlevel10k config
# -----------------------------
[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
