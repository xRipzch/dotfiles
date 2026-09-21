#!/usr/bin/env bash
# =============================================================================
#  dev-setup.sh — Barebone Arch Linux developer environment setup
#  Usage: bash dev-setup.sh [--dry-run] [--skip-dotfiles] [--skip-packages]
# =============================================================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Flags ─────────────────────────────────────────────────────────────────────
DRY_RUN=false
SKIP_DOTFILES=false
SKIP_PACKAGES=false
LOG_FILE="$HOME/dev-setup-$(date +%Y%m%d-%H%M%S).log"

for arg in "$@"; do
	case $arg in
	--dry-run) DRY_RUN=true ;;
	--skip-dotfiles) SKIP_DOTFILES=true ;;
	--skip-packages) SKIP_PACKAGES=true ;;
	--help)
		echo "Usage: bash dev-setup.sh [--dry-run] [--skip-dotfiles] [--skip-packages]"
		exit 0
		;;
	esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────
log() { echo -e "${BLUE}[INFO]${RESET}  $*" | tee -a "$LOG_FILE"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARN]${RESET}  $*" | tee -a "$LOG_FILE"; }
error() {
	echo -e "${RED}[ERROR]${RESET} $*" | tee -a "$LOG_FILE"
	exit 1
}
section() { echo -e "\n${BOLD}${BLUE}══ $* ══${RESET}" | tee -a "$LOG_FILE"; }

run() {
	if $DRY_RUN; then
		echo -e "${YELLOW}[DRY-RUN]${RESET} $*"
	else
		eval "$@" >>"$LOG_FILE" 2>&1
	fi
}

command_exists() { command -v "$1" &>/dev/null; }

# ── Verify Arch ───────────────────────────────────────────────────────────────
if [ ! -f /etc/arch-release ]; then
	error "This script is for Arch Linux only."
fi

log "Log file: $LOG_FILE"
$DRY_RUN && warn "Running in DRY-RUN mode — no changes will be made."

# =============================================================================
#  SECTION 1: paru (AUR helper)
# =============================================================================
section "paru (AUR helper)"

install_paru() {
	if command_exists paru; then
		warn "paru already installed — skipping."
		return
	fi
	log "Installing paru..."
	run sudo pacman -S --needed --noconfirm base-devel git
	local tmp
	tmp=$(mktemp -d)
	run git clone https://aur.archlinux.org/paru.git "$tmp/paru"
	run pushd "$tmp/paru"
	run makepkg -si --noconfirm
	run popd
	rm -rf "$tmp"
	success "paru installed."
}

install_paru

# =============================================================================
#  SECTION 2: System packages
# =============================================================================
section "System packages"

PACMAN_PACKAGES=(
	# Core utils
	curl wget git zip 7zip fd imagemagick man-db
	# Shell & terminal
	fish starship zoxide eza yazi btop htop fastfetch
	# Editors
	neovim
	# Docker
	docker docker-compose
	# Languages & runtimes
	go python-pip uv npm
)

AUR_PACKAGES=(
	github-cli-git
	lazygit
	lazydocker
	ttf-jetbrains-mono-nerd
)

install_packages() {
	log "Updating system..."
	run sudo pacman -Syu --noconfirm

	log "Installing pacman packages..."
	run sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"
	success "Pacman packages installed."

	log "Installing AUR packages..."
	run paru -S --needed --noconfirm "${AUR_PACKAGES[@]}"
	success "AUR packages installed."
}

if ! $SKIP_PACKAGES; then
	install_packages
else
	warn "Skipping package installation (--skip-packages)."
fi

# =============================================================================
#  SECTION 3: Fish as default shell
# =============================================================================
section "Shell (fish + starship)"

setup_shell() {
	local fish_path
	fish_path=$(command -v fish)

	if ! grep -q "$fish_path" /etc/shells; then
		log "Adding fish to /etc/shells..."
		run echo "$fish_path" | sudo tee -a /etc/shells
	fi

	if [ "$SHELL" != "$fish_path" ]; then
		log "Setting fish as default shell..."
		run chsh -s "$fish_path"
		success "Default shell set to fish."
	else
		warn "fish is already the default shell — skipping."
	fi
}

if command_exists fish; then
	setup_shell
else
	warn "fish not found — skipping shell setup."
fi

# =============================================================================
#  SECTION 4: Docker
# =============================================================================
section "Docker"

setup_docker() {
	if ! command_exists docker; then
		warn "docker not found — skipping."
		return
	fi

	run sudo systemctl enable --now docker

	if ! groups "$USER" | grep -q docker; then
		log "Adding $USER to docker group..."
		run sudo usermod -aG docker "$USER"
		warn "Log out and back in for docker group to take effect."
	else
		warn "$USER already in docker group — skipping."
	fi

	success "Docker configured."
}

setup_docker

# =============================================================================
#  SECTION 5: Git configuration
# =============================================================================
section "Git configuration"

setup_git() {
	if [ -z "$(git config --global user.name 2>/dev/null)" ]; then
		read -rp "  Git username: " git_name
		run git config --global user.name "'$git_name'"
	fi
	if [ -z "$(git config --global user.email 2>/dev/null)" ]; then
		read -rp "  Git email: " git_email
		run git config --global user.email "'$git_email'"
	fi

	run git config --global core.editor "nvim"
	run git config --global init.defaultBranch "main"
	run git config --global pull.rebase false
	success "Git configured."
}

setup_git

# =============================================================================
#  SECTION 6: SSH key
# =============================================================================
section "SSH key"

setup_ssh() {
	local key="$HOME/.ssh/id_ed25519"
	if [ -f "$key" ]; then
		warn "SSH key already exists at $key — skipping."
		return
	fi

	read -rp "  Email for SSH key: " ssh_email
	log "Generating SSH key..."
	run ssh-keygen -t ed25519 -C "'$ssh_email'" -f "$key" -N "''"
	run eval "$(ssh-agent -s)"
	run ssh-add "$key"

	success "SSH key generated."
	echo -e "\n${BOLD}Your public key (add to GitHub → Settings → SSH keys):${RESET}"
	if ! $DRY_RUN; then
		cat "${key}.pub"
	fi
}

setup_ssh

# =============================================================================
#  SECTION 7: Dotfiles
# =============================================================================
section "Dotfiles"

# ─── EDIT THIS: point to your dotfiles repo ──────────────────────────────────
DOTFILES_REPO="https://github.com/YOUR_USERNAME/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

declare -A DOTFILE_MAP=(
	["fish"]="$HOME/.config/fish"
	["starship.toml"]="$HOME/.config/starship.toml"
	["nvim"]="$HOME/.config/nvim"
	[".gitconfig"]="$HOME/.gitconfig"
)

symlink_dotfiles() {
	if [ ! -d "$DOTFILES_DIR" ]; then
		log "Cloning dotfiles from $DOTFILES_REPO..."
		run git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
	else
		log "Dotfiles repo already exists — pulling latest..."
		run git -C "$DOTFILES_DIR" pull --ff-only
	fi

	for src_rel in "${!DOTFILE_MAP[@]}"; do
		local src="$DOTFILES_DIR/$src_rel"
		local dest="${DOTFILE_MAP[$src_rel]}"

		if [ ! -e "$src" ]; then
			warn "Source not found: $src — skipping."
			continue
		fi

		if [ -e "$dest" ] && [ ! -L "$dest" ]; then
			warn "Backing up existing $dest → ${dest}.bak"
			run mv "$dest" "${dest}.bak"
		fi

		run mkdir -p "$(dirname "$dest")"
		run ln -sf "$src" "$dest"
		success "Linked $src → $dest"
	done
}

if ! $SKIP_DOTFILES; then
	if [[ "$DOTFILES_REPO" == *"YOUR_USERNAME"* ]]; then
		warn "DOTFILES_REPO not configured — skipping dotfiles."
		warn "Edit the script and set your repo URL, then re-run."
	else
		symlink_dotfiles
	fi
else
	warn "Skipping dotfiles (--skip-dotfiles)."
fi

# =============================================================================
#  Done
# =============================================================================
echo -e "\n${BOLD}${GREEN}╔══════════════════════════════════════╗"
echo -e "║   Setup complete! Restart your shell  ║"
echo -e "╚══════════════════════════════════════╝${RESET}"
echo -e "Log saved to: ${BOLD}$LOG_FILE${RESET}\n"

echo -e "${BOLD}Next steps:${RESET}"
echo "  1. Add your SSH public key to GitHub"
echo "  2. Set DOTFILES_REPO in the script and re-run to link dotfiles"
echo "  3. Log out and back in (docker group + new shell)"
$DRY_RUN && echo -e "\n${YELLOW}Remember: this was a dry run — run without --dry-run to apply changes.${RESET}"
