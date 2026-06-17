#!/usr/bin/env bash
#
# C-Academy VM setup — run INSIDE the Ubuntu VM.
#
#   curl -fsSL https://raw.githubusercontent.com/<org>/<repo>/main/setup.sh | bash
#
# Installs Python, Java, git, vim, VS Code and the Python/Java extensions.
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

log "Installing git and vim"
sudo apt-get install -y git vim

# --- Java certificate fix (only if Maven/JDK TLS is broken) -----------------
fix_java_certs() {
  warn "Repairing ca-certificates-java"
  sudo dpkg --purge --force-depends ca-certificates-java || true
  sudo apt-get install -y ca-certificates-java
}

# --- VS Code ----------------------------------------------------------------
if ! command -v code >/dev/null 2>&1; then
  log "Installing VS Code (snap)"
  sudo snap install code --classic
else
  log "VS Code already installed"
fi

# --- VS Code extensions -----------------------------------------------------
if command -v code >/dev/null 2>&1; then
  log "Installing VS Code extensions"
  code --install-extension ms-python.python --force
  code --install-extension vscjava.vscode-java-pack --force
fi

# --- verify -----------------------------------------------------------------
log "Versions installed:"
python3 --version || true
pip3 --version    || true
java -version 2>&1 | head -1 || true
mvn -version 2>&1 | head -1  || true
git --version     || true

# quick venv smoke test
TMP_VENV="$(mktemp -d)/testenv"
if python3 -m venv "$TMP_VENV" >/dev/null 2>&1; then
  log "python venv works"
  rm -rf "$TMP_VENV"
else
  warn "python venv failed — check python3-venv"
fi

log "Done."
