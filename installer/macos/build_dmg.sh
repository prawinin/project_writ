#!/bin/bash
# Writ — macOS DMG builder.
# Prerequisites (run once):
#   1. Build app bundle:  pyinstaller --noconfirm Writ.spec   (produces dist/Writ.app via BUNDLE)
#   2. Build knowledge base: WRIT_DB_KEY="..." python build_encrypted_db.py
#   3. Place Writ.app and writ_data.dat next to this script's staging dir (done below).
# Then:  bash installer/macos/build_dmg.sh
# Output: dist-installer/Writ-1.0.0-Mac.dmg
#
# NOTE: also run `python3 scripts/setup_reranker.py` before packaging if you
# want the DMG to include the offline neural rerank model (models/minilm).
#
# First-launch behaviour (no admin needed):
#   - We provide `Install Writ.command` in the DMG, which handles copying
#     Writ.app to Applications, downloading the data file via curl.
set -e
cd "$(dirname "$0")/../.."

VERSION="1.0.0"
STAGE="dist-installer/dmg-stage"
DMG="dist-installer/Writ-${VERSION}-Mac.dmg"

[ -d "dist/Writ.app" ] || { echo "ERROR: dist/Writ.app missing — run: pyinstaller --noconfirm Writ.spec"; exit 1; }

rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE" dist-installer

# App bundle
cp -R "dist/Writ.app" "$STAGE/"

cat > "$STAGE/Install Writ.command" <<'EOF'
#!/bin/bash
set -e
echo "Welcome to the Writ Installer for macOS"
echo "======================================="

DATA_DIR="$HOME/Library/Application Support/Writ"
mkdir -p "$DATA_DIR"

if [ ! -f "$DATA_DIR/writ_data.dat" ]; then
    read -p "Download Writ Knowledge Base (~1.6 GB)? [Y/n] " a
    if [[ ! "${a,,}" =~ ^(n|no)$ ]]; then
        echo "Downloading writ_data.dat (~1.6 GB)..."
        curl -L --progress-bar -o "$DATA_DIR/writ_data.dat" "https://github.com/prawinin/writ/releases/download/v1.0.0/writ_data.dat"
        chmod 600 "$DATA_DIR/writ_data.dat"
        echo "Knowledge base installed."
    else
        echo "Skipped knowledge base download. App will not function correctly without it."
    fi
else
    echo "Knowledge base already present at $DATA_DIR/writ_data.dat"
fi

echo "Copying Writ.app to /Applications..."
cp -R "$(dirname "$0")/Writ.app" "/Applications/"
echo "Installation complete! You can now launch Writ from Applications."
echo ""
echo "Note: To use the AI features, make sure Ollama is installed and the model is downloaded."
echo "Run: ollama pull hf.co/prawinin/vidhi"
EOF
chmod +x "$STAGE/Install Writ.command"

cat > "$STAGE/READ ME FIRST.txt" <<'EOF'
Writ — Indian Legal Intelligence (offline)

Double-click "Install Writ.command" to install Writ to your Applications folder, and optionally download the knowledge base.
EOF

hdiutil create -volname "Writ" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
rm -rf "$STAGE"
echo "DMG ready: $DMG"
