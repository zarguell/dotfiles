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

# --- Optional: persist Rust/cargo data across container rebuilds ---
# GitHub notes /workspaces is persisted and suggests symlinking to it for data you want to survive rebuilds. 
PERSIST_ROOT="/workspaces/.persist"
mkdir -p "$PERSIST_ROOT"

# If you want this behavior, keep it on. If not, set to 0.
PERSIST_RUST=1

if [ "$PERSIST_RUST" -eq 1 ]; then
  mkdir -p "$PERSIST_ROOT/cargo" "$PERSIST_ROOT/rustup" "$PERSIST_ROOT/cargo-target"

  # Move existing dirs into persisted storage once, then symlink.
  if [ -d "$HOME/.cargo" ] && [ ! -L "$HOME/.cargo" ]; then
    rm -rf "$PERSIST_ROOT/cargo"
    mv "$HOME/.cargo" "$PERSIST_ROOT/cargo"
  fi
  if [ -d "$HOME/.rustup" ] && [ ! -L "$HOME/.rustup" ]; then
    rm -rf "$PERSIST_ROOT/rustup"
    mv "$HOME/.rustup" "$PERSIST_ROOT/rustup"
  fi

  ln -sfn "$PERSIST_ROOT/cargo"  "$HOME/.cargo"
  ln -sfn "$PERSIST_ROOT/rustup" "$HOME/.rustup"

  # Helps cargo reuse build artifacts between installs/builds.
  export CARGO_TARGET_DIR="$PERSIST_ROOT/cargo-target"
fi

# --- Ensure rustup is the primary Rust (idempotent) ---

# Remove Ubuntu-managed rustc/cargo if present to avoid rustup PATH conflicts. 
dpkg -s rustc >/dev/null 2>&1 && sudo apt-get remove -y rustc || true
dpkg -s cargo >/dev/null 2>&1 && sudo apt-get remove -y cargo || true
sudo apt-get autoremove -y || true

# Install rustup only if missing
if [ ! -x "$HOME/.cargo/bin/rustup" ]; then
  export RUSTUP_INIT_SKIP_PATH_CHECK=yes
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Make rustup-managed cargo/rustc available in this script run
# shellcheck disable=SC1090
source "$HOME/.cargo/env"

# Ensure ~/.cargo/bin is first so the "proper" rustup toolchain is used. 
export PATH="$HOME/.cargo/bin:$PATH"

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

DOTFILES_DIR="/workspaces/.codespaces/.persistedshare/dotfiles"

if [ -f "$DOTFILES_DIR/.zshrc" ]; then
  # Backup existing file once if it's a real file (not a symlink)
  if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ] && [ ! -f "$HOME/.zshrc.bak" ]; then
    mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
  fi

  ln -sfn "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
fi

if [ -f "$DOTFILES_DIR/.p10k.zsh" ]; then
  ln -sfn "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
fi