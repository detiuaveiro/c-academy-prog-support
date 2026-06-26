#!/usr/bin/env bash
#
# C-Academy VM setup — run INSIDE the Ubuntu VM.
#
#   curl -fsSL https://raw.githubusercontent.com/<org>/<repo>/main/setup.sh | bash
#
# Installs curl, Python, Java, Haskell, Rust, C/binutils, MIPS tooling, git,
# vim, VS Code and the
# Python/Java/Haskell/Rust extensions.
# Idempotent: safe to re-run. Does NOT pin package versions — the LTS archive
# already locks the 3.14 / JDK series for you.

set -euo pipefail

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

# --- sanity checks ----------------------------------------------------------
[ "$(id -u)" -ne 0 ] || die "Run as a normal user (the script calls sudo itself), not as root."
command -v apt-get >/dev/null 2>&1 || die "This script targets Ubuntu/Debian (apt-get not found)."

if command -v lsb_release >/dev/null 2>&1; then
  log "Detected: $(lsb_release -ds)"
fi

# --- apt packages -----------------------------------------------------------
log "Updating package lists"
sudo apt-get update -y

log "Installing Python toolchain"
sudo apt-get install -y python3 python3-venv python3-pip

log "Installing Java toolchain"
sudo apt-get install -y default-jdk maven

log "Installing Haskell toolchain"
sudo apt-get install -y ghc cabal-install

log "Installing Rust toolchain"
sudo apt-get install -y rustc cargo

log "Installing C and low-level tooling"
sudo apt-get install -y build-essential binutils make

log "Installing MIPS simulator"
sudo apt-get install -y spim

log "Installing git, vim and curl"
sudo apt-get install -y git vim curl

# --- Java certificate fix (only if Maven/JDK TLS is broken) -----------------
fix_java_certs() {
  warn "Repairing ca-certificates-java"
  sudo dpkg --purge --force-depends ca-certificates-java || true
  sudo apt-get install -y ca-certificates-java
}

# --- JAVA_HOME (system-wide via /etc/environment) ---------------------------
# Derive JAVA_HOME from the actual JDK install rather than hardcoding a version,
# so it stays correct whatever version default-jdk resolves to.
log "Setting JAVA_HOME in /etc/environment"
JAVA_HOME_PATH=""
if command -v java >/dev/null 2>&1; then
  JAVA_HOME_PATH="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
fi
if [ -z "$JAVA_HOME_PATH" ] || [ ! -d "$JAVA_HOME_PATH" ]; then
  warn "Could not detect JAVA_HOME automatically — skipping. Check 'ls /usr/lib/jvm/'."
  JAVA_HOME_PATH=""
fi
if [ -n "$JAVA_HOME_PATH" ]; then
  log "JAVA_HOME=$JAVA_HOME_PATH"
  # Idempotent: drop any existing JAVA_HOME line, then append the current one.
  sudo sed -i '/^JAVA_HOME=/d' /etc/environment
  echo "JAVA_HOME=\"$JAVA_HOME_PATH\"" | sudo tee -a /etc/environment >/dev/null
  # Make it available in the current shell too (takes effect in new logins otherwise).
  export JAVA_HOME="$JAVA_HOME_PATH"
fi

# --- VS Code ----------------------------------------------------------------
# Install from Microsoft's official apt repository. This is the official route
# and works on every architecture (amd64, arm64, armhf) — unlike the `code`
# snap, which is amd64-only and fails on arm64 (e.g. Apple Silicon hosts) with
# "not available on stable for this architecture".
if command -v code >/dev/null 2>&1; then
  log "VS Code already installed"
else
  log "Installing VS Code (Microsoft apt repository)"
  sudo apt-get install -y wget gpg apt-transport-https
  KEYRING="/etc/apt/keyrings/packages.microsoft.gpg"
  TMP_KEY="$(mktemp)"
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$TMP_KEY"
  sudo install -D -o root -g root -m 644 "$TMP_KEY" "$KEYRING"
  rm -f "$TMP_KEY"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y code
fi

# --- VS Code extensions -----------------------------------------------------
if command -v code >/dev/null 2>&1; then
  log "Installing VS Code extensions"
  code --install-extension ms-python.python --force
  code --install-extension vscjava.vscode-java-pack --force
  code --install-extension haskell.haskell --force
  code --install-extension rust-lang.rust-analyzer --force
fi

# --- verify -----------------------------------------------------------------
log "Versions installed:"
python3 --version || true
pip3 --version    || true
java -version 2>&1 | head -1 || true
javac -version      || true
javadoc -version 2>&1 | head -1 || true
mvn -version 2>&1 | head -1  || true
ghc --version       || true
ghci --version      || true
runghc --version    || true
cabal --version 2>&1 | head -1 || true
rustc --version    || true
cargo --version    || true
gcc --version 2>&1 | head -1 || true
make --version 2>&1 | head -1 || true
objdump --version 2>&1 | head -1 || true
spim -version 2>&1 | head -2 || true
git --version     || true

# quick venv smoke test
TMP_VENV="$(mktemp -d)/testenv"
if python3 -m venv "$TMP_VENV" >/dev/null 2>&1; then
  log "python venv works"
  rm -rf "$TMP_VENV"
else
  warn "python venv failed — check python3-venv"
fi

# Remove the downloaded script after a successful run, but keep repository
# copies intact for maintainers running it from a checkout.
cleanup_self() {
  local script_path="${BASH_SOURCE[0]:-$0}"
  local script_dir

  [ "$(basename "$script_path")" = "setup.sh" ] || return 0
  [ -f "$script_path" ] || return 0

  script_dir="$(cd "$(dirname "$script_path")" && pwd -P)" || return 0
  if command -v git >/dev/null 2>&1 \
    && git -C "$script_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    warn "Leaving setup.sh in place because it is inside a git worktree."
    return 0
  fi

  log "Removing downloaded setup.sh"
  rm -f -- "$script_path"
}

cleanup_self

log "Done."
