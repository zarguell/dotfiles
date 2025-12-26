#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update -y

# Base + quality-of-life (lean)
sudo apt-get install -y \
  zsh git curl ca-certificates \
  fzf ripgrep jq \
  python3 python3-pip \
  nodejs npm \
  build-essential pkg-config libssl-dev

# Try apt first for "modern" tools (OK if some aren't available)
sudo apt-get install -y \
  bat fd-find git-delta \
  eza zoxide procs dust duf || true

# --- Ensure rustup is the primary Rust (idempotent) ---

# If Ubuntu rustc/cargo are present, remove them so rustup doesn't complain about /usr/bin.
# (This is the cleanest way to avoid the warning/error you saw.) 
if command -v rustc >/dev/null 2>&1 || command -v cargo >/dev/null 2>&1; then
  # Only remove the Ubuntu-managed ones if they are actually installed via dpkg.
  dpkg -s rustc >/dev/null 2>&1 && sudo apt-get remove -y rustc || true
  dpkg -s cargo >/dev/null 2>&1 && sudo apt-get remove -y cargo || true
  sudo apt-get autoremove -y || true
fi

# Install rustup only if missing (idempotent)
if ! command -v rustup >/dev/null 2>&1; then
  # If you ever *do* end up with another rust in PATH, this env var bypasses the check. 
  export RUSTUP_INIT_SKIP_PATH_CHECK=yes
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Make rustup-managed cargo/rustc available in this script run
# shellcheck disable=SC1090
source "$HOME/.cargo/env"

# Ensure toolchain exists + is selected (safe to re-run)
rustup toolchain install stable
rustup default stable

install_if_missing() {
  local cmd="$1"
  local crate="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    cargo install --locked "$crate"
  fi
}

# Cargo fallback only if still missing after apt
install_if_missing eza eza
install_if_missing zoxide zoxide
install_if_missing procs procs
install_if_missing dust du-dust
install_if_missing duf duf
install_if_missing delta git-delta

# fd: on Ubuntu it's often "fdfind" via apt; only install "fd" if neither exists.
if ! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1; then
  cargo install --locked fd-find
fi

# Powerlevel10k (minimal install: clone + source)
if [ ! -d "$HOME/.local/share/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.local/share/powerlevel10k"
fi

# Make zsh the default shell (Codespaces docs recommend using chsh in your install script)
sudo chsh "$(id -un)" --shell "/usr/bin/zsh" || true
