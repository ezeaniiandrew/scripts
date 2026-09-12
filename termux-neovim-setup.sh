#!/data/data/com.termux/files/usr/bin/bash

set -e

RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'

info() {
  echo -e "${CYAN}$1${RESET}"
}

action() {
  echo -e "${BLUE}$1${RESET}"
}

success() {
  echo -e "${GREEN}$1${RESET}"
}

warning() {
  echo -e "${YELLOW}$1${RESET}"
}

error() {
  echo -e "${RED}$1${RESET}"
}

abort() {
  echo
  error "Installation aborted."
  error "$1"
  exit 1
}

ask_permission() {
  local answer

  while true; do
    read -r -p "$1 [y/N]: " answer </dev/tty

    case "$answer" in
    [Yy] | [Yy][Ee][Ss])
      return 0
      ;;
    [Nn] | [Nn][Oo] | "")
      return 1
      ;;
    *)
      warning "Please answer yes or no."
      ;;
    esac
  done
}

PACKAGES=(
  "nodejs"
  "git"
  "neovim-nightly"
  "lua-language-server"
  "clang"
)

COMMANDS=(
  "node"
  "git"
  "nvim"
  "lua-language-server"
  "clang"
)

get_version() {
  case "$1" in
  nodejs)
    node --version
    ;;
  git)
    git --version
    ;;
  neovim-nightly)
    nvim --version | head -n 1
    ;;
  lua-language-server)
    lua-language-server --version | head -n 1
    ;;
  clang)
    clang --version | head -n 1
    ;;
  esac
}

echo
info "=============================================="
info " Checking for updates before installation"
info "=============================================="
echo

action "Updating package information..."
echo

pkg update

echo
action "Checking if any installed packages can be upgraded..."
echo

UPGRADE_CHECK=$(apt-get --just-print upgrade 2>&1)

if echo "$UPGRADE_CHECK" | grep -qE '^Inst '; then
  echo
  warning "Updates are available."
  echo
  action "Upgrading installed packages..."
  echo

  pkg upgrade </dev/tty

  echo
  success "Package upgrades completed."
else
  echo
  success "No package upgrades are available."
fi

echo
info "=============================================="
info " Checking required dependencies"
info "=============================================="
echo

MISSING_PACKAGES=()

for i in "${!PACKAGES[@]}"; do
  package="${PACKAGES[$i]}"
  command="${COMMANDS[$i]}"

  if command -v "$command" >/dev/null 2>&1; then
    success "[FOUND] $package"
    echo "        $(get_version "$package")"
  else
    warning "[MISSING] $package"
    MISSING_PACKAGES+=("$package")
  fi
done

if [ "${#MISSING_PACKAGES[@]}" -gt 0 ]; then
  echo
  warning "The following required dependencies are missing:"
  echo

  for package in "${MISSING_PACKAGES[@]}"; do
    echo "  - $package"
  done

  echo
  info "These dependencies are required for the Neovim"
  info "configuration to work correctly."
  echo

  if ! ask_permission "Would you like to install the missing dependencies?"; then
    abort "The required dependencies were not installed."
  fi

  echo

  for package in "${MISSING_PACKAGES[@]}"; do
    action "Installing $package..."

    if pkg install "$package" </dev/tty; then
      success "$package installed successfully."
    else
      echo
      error "Failed to install $package."
      abort "The installation could not continue."
    fi

    echo
  done

  action "Verifying the newly installed dependencies..."
  echo

  for package in "${MISSING_PACKAGES[@]}"; do

    for i in "${!PACKAGES[@]}"; do
      if [ "${PACKAGES[$i]}" = "$package" ]; then
        command="${COMMANDS[$i]}"
        break
      fi
    done

    if ! command -v "$command" >/dev/null 2>&1; then
      abort "Failed to verify $package after installation."
    fi

    success "[INSTALLED] $package"
    echo "            $(get_version "$package")"
  done
fi

echo
info "=============================================="
info " Installing Neovim configuration"
info "=============================================="
echo

NVIM_CONFIG_DIR="$HOME/.config/nvim"
REPO_URL="https://github.com/ezeaniiandrew/neovim-config.git"

if [ -e "$NVIM_CONFIG_DIR" ]; then
  warning "An existing Neovim configuration was found at:"
  echo
  echo "    $NVIM_CONFIG_DIR"
  echo
  warning "If you choose to overwrite it, the existing directory"
  warning "will be permanently deleted."
  echo
  error "WARNING: This deletion is irreversible through this"
  error "script. Any files in the existing configuration that"
  error "are not backed up will be lost permanently."
  echo

  if ! ask_permission "Do you want to overwrite the existing Neovim configuration?"; then
    abort "The existing Neovim configuration was left untouched."
  fi

  echo
  action "Removing existing Neovim configuration..."
  echo

  rm -rf "$NVIM_CONFIG_DIR"

  success "Existing Neovim configuration removed."
fi

echo
action "Cloning Neovim configuration..."
echo

git clone "$REPO_URL" "$NVIM_CONFIG_DIR"

echo
success "Neovim configuration cloned successfully."

echo
success "=============================================="
success " Installation completed successfully!"
success "=============================================="
echo
success "Your Neovim configuration has been installed."
echo
info "Run:"
echo
echo "    nvim"
echo
info "to start the editor."
echo
warning "IMPORTANT:"
echo "On the first launch, Neovim will install the necessary"
echo "plugins and extensions for the configuration."
echo
warning "Please wait for the installation to finish before"
warning "doing anything in Neovim."
echo
success "Enjoy your new Neovim setup!"
echo

if ask_permission "Would you like to star the repository on GitHub?"; then
  action "Opening the repository in your browser..."
  termux-open-url "https://github.com/ezeaniiandrew/neovim-config"
else
  info "Thanks for using the setup script!"
fi

echo
