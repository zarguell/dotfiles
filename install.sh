#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="/workspaces/.codespaces/.persistedshare/dotfiles"
PERSIST_ROOT="/workspaces/.persist"

PERSIST_RUST="${PERSIST_RUST:-1}"

# New: prefer downloading prebuilt tools from GitHub Releases in Codespaces
DOTFILES_USE_BIN_CACHE="${DOTFILES_USE_BIN_CACHE:-1}"
TOOLS_RELEASE_TAG="${TOOLS_RELEASE_TAG:-tools-linux-x86_64}"
TOOLS_ASSET_NAME="${TOOLS_ASSET_NAME:-dotfiles-tools-linux-x86_64.tar.gz}"
TOOLS_SHA_NAME="${TOOLS_SHA_NAME:-dotfiles-tools-linux-x86_64.sha256}"
TOOLS_REPO="${TOOLS_REPO:-zarguell/dotfiles}"

log() { printf '%s\n' "$*"; }

apt_install() { sudo apt-get install -y "$@"; }
apt_install_optional() { sudo apt-get install -y "$@" || true; }

dpkg_remove_if_installed() {
  local pkg="$1"
  if dpkg -s "$pkg" >/dev/null 2>&1; then
    sudo apt-get remove -y "$pkg" || true
  fi
}

ensure_dir() { mkdir -p "$1"; }

persist_dir_into_workspaces() {
  local src="$1"
  local dst="$2"
  ensure_dir "$(dirname "$dst")"

  if [ -d "$src" ] && [ ! -L "$src" ]; then
    rm -rf "$dst"
    mv "$src" "$dst"
  fi

  ensure_dir "$dst"
  ln -sfn "$dst" "$src"
}

cargo_install_if_missing() {
  local cmd="$1"
  local crate="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    cargo install --locked "$crate"
  fi
}

git_clone_if_missing() {
  local url="$1"
  local dest="$2"
  if [ ! -d "$dest" ]; then
    git clone --depth=1 "$url" "$dest"
  fi
}

symlink_with_backup() {
  local src="$1"
  local tgt="$2"

  [ -e "$src" ] || return 0

  if [ -e "$tgt" ] && [ ! -L "$tgt" ] && [ ! -e "${tgt}.bak" ]; then
    mv "$tgt" "${tgt}.bak"
  fi

  ln -sfn "$src" "$tgt"
}

ensure_rustup_no_download() {
  dpkg_remove_if_installed rustc
  dpkg_remove_if_installed cargo
  sudo apt-get autoremove -y || true

  if [ ! -x "$HOME/.cargo/bin/rustup" ]; then
    export RUSTUP_INIT_SKIP_PATH_CHECK=yes
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  fi

  # shellcheck disable=SC1090
  source "$HOME/.cargo/env"
  export PATH="$HOME/.cargo/bin:$PATH"

  # Only install stable if not present (avoid downloads on repeat runs)
  if ! rustup toolchain list | grep -q '^stable'; then
    rustup toolchain install stable
  fi

  # Only set default if stable exists
  if rustup toolchain list | grep -q '^stable'; then
    rustup default stable >/dev/null 2>&1 || true
  fi
}

install_prebuilt_tools_if_enabled() {
  # Downloads a tarball that contains ./bin/<tools> and extracts it into ~/.local
  # so binaries end up in ~/.local/bin.
  [ "$DOTFILES_USE_BIN_CACHE" -eq 1 ] || return 0

  local base="https://github.com/${TOOLS_REPO}/releases/download/${TOOLS_RELEASE_TAG}"
  local tar_url="${base}/${TOOLS_ASSET_NAME}"
  local sha_url="${base}/${TOOLS_SHA_NAME}"

  # Prefer persisted bin dir if you want it across rebuilds, else ~/.local/bin.
  local bin_root="$HOME/.local"
  local bin_dir="$bin_root/bin"
  ensure_dir "$bin_dir"

  # Minimal deps: curl + tar + sha256sum (coreutils). curl/tar are generally present; ensure curl is installed earlier.
  log "Attempting prebuilt tools cache from release ${TOOLS_RELEASE_TAG}..."
  if curl -fsSL "$tar_url" -o /tmp/"$TOOLS_ASSET_NAME"; then
    # Optional integrity check if sha file exists
    if curl -fsSL "$sha_url" -o /tmp/"$TOOLS_SHA_NAME"; then
      (cd /tmp && sha256sum -c "$TOOLS_SHA_NAME") || {
        log "Checksum failed for prebuilt tools; ignoring cache."
        rm -f /tmp/"$TOOLS_ASSET_NAME" /tmp/"$TOOLS_SHA_NAME"
        return 0
      }
    fi

    tar -xzf /tmp/"$TOOLS_ASSET_NAME" -C "$bin_root"
    rm -f /tmp/"$TOOLS_ASSET_NAME" /tmp/"$TOOLS_SHA_NAME"

    export PATH="$bin_dir:$PATH"
    log "Prebuilt tools installed into $bin_dir."
  else
    log "No prebuilt tools asset found (or download failed); will compile via cargo as fallback."
  fi
}

main() {
  sudo apt-get update -y

  log "Installing base packages..."
  apt_install \
    zsh git curl ca-certificates \
    fzf ripgrep jq \
    python3 python3-pip \
    nodejs npm \
    build-essential pkg-config libssl-dev \
    tar coreutils

  log "Installing modern tools (apt, best-effort)..."
  apt_install_optional \
    bat fd-find git-delta \
    eza zoxide procs dust duf

  ensure_dir "$PERSIST_ROOT"

  if [ "$PERSIST_RUST" -eq 1 ]; then
    log "Persisting Rust caches under $PERSIST_ROOT..."
    persist_dir_into_workspaces "$HOME/.cargo"  "$PERSIST_ROOT/cargo"
    persist_dir_into_workspaces "$HOME/.rustup" "$PERSIST_ROOT/rustup"
    ensure_dir "$PERSIST_ROOT/cargo-target"
    export CARGO_TARGET_DIR="$PERSIST_ROOT/cargo-target"
  fi

  # New: try release asset first so Codespaces doesn't compile everything.
  install_prebuilt_tools_if_enabled

  log "Ensuring rustup + stable (no auto-download on rerun)..."
  ensure_rustup_no_download

  log "Installing Rust CLIs (cargo fallback only if missing)..."
  cargo_install_if_missing eza eza
  cargo_install_if_missing zoxide zoxide
  cargo_install_if_missing procs procs
  cargo_install_if_missing dust du-dust
  cargo_install_if_missing duf duf
  cargo_install_if_missing delta git-delta

  # fd: Ubuntu may provide "fdfind" instead of "fd"
  if ! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1; then
    cargo install --locked fd-find
  fi

  log "Installing Powerlevel10k..."
  git_clone_if_missing \
    https://github.com/romkatv/powerlevel10k.git \
    "$HOME/.local/share/powerlevel10k"

  log "Setting default shell to zsh..."
  sudo chsh "$(id -un)" --shell "/usr/bin/zsh" || true

  log "Linking dotfiles into \$HOME..."
  symlink_with_backup "$DOTFILES_DIR/.zshrc"    "$HOME/.zshrc"
  symlink_with_backup "$DOTFILES_DIR/.bashrc"   "$HOME/.bashrc"
  symlink_with_backup "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"

  if [ -d "$DOTFILES_DIR/.config/shell" ]; then
    ensure_dir "$HOME/.config"
    ln -sfn "$DOTFILES_DIR/.config/shell" "$HOME/.config/shell"
  fi

  log "Done."
}

main "$@"
