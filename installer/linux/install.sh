#!/bin/bash
# Writ — Linux installer (works on Debian/Ubuntu/Fedora/Arch, no root required by default).
#
# Usage:
#   bash installer/linux/install.sh [--prefix ~/.local] [--data-dir ~/.local/share/writ]
#
# What it does (and asks before each step):
#   1. Copies the PyInstaller bundle (dist/Writ/*) to <prefix>/lib/writ + symlink <prefix>/bin/writ
#   2. Downloads writ_data.dat (~1.6 GB) to <data-dir> (default ~/.local/share/writ)
#      Set WRIT_DATA_PATH to override the location at runtime.
#   3. Installs a .desktop launcher.
set -e
cd "$(dirname "$0")/../.."

PREFIX="${HOME}/.local"
DATA_DIR=""
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --prefix=*) PREFIX="${arg#*=}" ;;
    --data-dir=*) DATA_DIR="${arg#*=}" ;;
    --yes) ASSUME_YES=1 ;;
  esac
done
DATA_DIR="${DATA_DIR:-${PREFIX}/share/writ}"

ask() {  # ask "prompt" -> 0=yes
  if [ "$ASSUME_YES" = "1" ]; then return 0; fi
  read -rp "$1 [Y/n] " a; [[ "${a,,}" =~ ^(n|no)$ ]] && return 1 || return 0
}

[ -d "dist/Writ" ] || { echo "ERROR: dist/Writ missing — run build_exe.sh first"; exit 1; }

echo "Install Writ to ${PREFIX} with data in ${DATA_DIR}?"
ask "Continue?" || exit 0

mkdir -p "${PREFIX}/lib" "${PREFIX}/bin" "${DATA_DIR}"
cp -r "dist/Writ" "${PREFIX}/lib/writ"
ln -sf "${PREFIX}/lib/writ/Writ" "${PREFIX}/bin/writ"

if [ -f "${DATA_DIR}/writ_data.dat" ]; then
  echo "Knowledge base already present at ${DATA_DIR}/writ_data.dat — keeping it."
else
  if ask "Download Writ Knowledge Base (~1.6 GB) to ${DATA_DIR}?"; then
    echo "Downloading writ_data.dat (~1.6 GB) to ${DATA_DIR}..."
    curl -L --progress-bar -o "${DATA_DIR}/writ_data.dat" "https://github.com/prawinin/project_writ/releases/download/v1.0.0/writ_data.dat"
    chmod 600 "${DATA_DIR}/writ_data.dat"
    echo "Knowledge base installed."
  else
    echo "Skipping knowledge base download. Note: App will not function correctly without it."
  fi
fi

mkdir -p "${HOME}/.local/share/applications"
cat > "${HOME}/.local/share/applications/writ.desktop" <<EOF
[Desktop Entry]
Name=Writ
Comment=Indian Legal Intelligence (offline)
Exec=${PREFIX}/bin/writ
Icon=${PREFIX}/lib/writ/assets/icon.png
Terminal=false
Type=Application
Categories=Office;
EOF

echo ""
echo "Note: To use the AI features, make sure Ollama is installed and the model is downloaded."
echo "Run: ollama pull hf.co/prawinin/vidhi"

echo "Done. Launch with: ${PREFIX}/bin/writ  (ensure ${PREFIX}/bin is on PATH)"
