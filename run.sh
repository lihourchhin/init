#!/usr/bin/env bash
#
# init — fresh Ubuntu server bootstrap
# https://github.com/lihourchhin/init
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/lihourchhin/init/master/run.sh | bash
#
# Optional environment variables (set to 1 to skip a step):
#   SKIP_NGINX=1      skip Nginx + Certbot
#   SKIP_NODE=1       skip Node.js + yarn/pnpm/pm2
#   SKIP_ZSH=1        skip Zsh + Oh My Zsh
#   NODE_MAJOR=22     Node.js major version (default: current LTS)

set -Eeuo pipefail

# ---------- helpers ----------------------------------------------------------

readonly BOLD="\033[1m" GREEN="\033[32m" YELLOW="\033[33m" RED="\033[31m" RESET="\033[0m"

log()  { printf "${BOLD}${GREEN}==>${RESET} ${BOLD}%s${RESET}\n" "$*"; }
warn() { printf "${BOLD}${YELLOW}warning:${RESET} %s\n" "$*" >&2; }
die()  { printf "${BOLD}${RED}error:${RESET} %s\n" "$*" >&2; exit 1; }

trap 'die "failed on line $LINENO: $BASH_COMMAND"' ERR

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    command -v sudo >/dev/null 2>&1 || die "run as root or install sudo first"
    SUDO="sudo"
fi

export DEBIAN_FRONTEND=noninteractive
apt_install() { $SUDO apt-get install -y --no-install-recommends "$@"; }

# ---------- preflight --------------------------------------------------------

log "init — fresh server starter"

[ -r /etc/os-release ] || die "cannot detect OS (/etc/os-release missing)"
# shellcheck disable=SC1091
. /etc/os-release
[ "${ID:-}" = "ubuntu" ] || die "only Ubuntu is supported (detected: ${ID:-unknown})"
log "Detected ${PRETTY_NAME}"

# ---------- system update & base packages ------------------------------------

log "Updating system packages"
$SUDO apt-get update -y
$SUDO apt-get upgrade -y

log "Installing base tools"
apt_install ca-certificates curl wget git gnupg lsb-release unzip \
    build-essential htop neofetch zsh

if command -v snap >/dev/null 2>&1; then
    log "Installing bpytop (snap)"
    $SUDO snap install bpytop || warn "bpytop install failed, continuing"
fi

# ---------- nginx + certbot --------------------------------------------------

if [ "${SKIP_NGINX:-0}" != "1" ]; then
    log "Installing Nginx and Certbot"
    apt_install nginx certbot python3-certbot-nginx
    $SUDO systemctl enable --now nginx
fi

# ---------- node.js ----------------------------------------------------------

if [ "${SKIP_NODE:-0}" != "1" ]; then
    if [ -n "${NODE_MAJOR:-}" ]; then
        node_setup="setup_${NODE_MAJOR}.x"
    else
        node_setup="setup_lts.x"
    fi
    log "Installing Node.js (${node_setup})"
    curl -fsSL "https://deb.nodesource.com/${node_setup}" | $SUDO -E bash -
    apt_install nodejs

    log "Installing yarn, pnpm and pm2"
    $SUDO npm install -g yarn pnpm pm2
fi

# ---------- workspace folders ------------------------------------------------

log "Creating ~/projects, ~/temps, ~/uploads"
mkdir -p "$HOME/projects" "$HOME/temps" "$HOME/uploads"

# ---------- zsh + oh my zsh --------------------------------------------------

if [ "${SKIP_ZSH:-0}" != "1" ]; then
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log "Installing Oh My Zsh"
        RUNZSH=no CHSH=no sh -c \
            "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
            "" --unattended
    fi

    plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    if [ ! -d "$plugin_dir" ]; then
        log "Installing zsh-autosuggestions"
        git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir"
    fi

    if [ -f "$HOME/.zshrc" ] && ! grep -q "zsh-autosuggestions" "$HOME/.zshrc"; then
        sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions)/' "$HOME/.zshrc"
    fi

    current_user="$(id -un)"
    if [ "$(getent passwd "$current_user" | cut -d: -f7)" != "$(command -v zsh)" ]; then
        log "Setting zsh as default shell for ${current_user}"
        $SUDO chsh -s "$(command -v zsh)" "$current_user"
    fi
fi

# ---------- done -------------------------------------------------------------

$SUDO apt-get autoremove -y

log "All done!"
command -v node  >/dev/null 2>&1 && echo "  node   $(node -v)"
command -v nginx >/dev/null 2>&1 && echo "  nginx  $(nginx -v 2>&1 | cut -d/ -f2)"
echo
echo "Log out and back in (or run 'exec zsh') to start using your new shell."
