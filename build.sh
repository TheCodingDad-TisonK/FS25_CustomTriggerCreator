#!/usr/bin/env bash
# build.sh - Build and optionally deploy FS25_CustomTriggerCreator
# Usage:
#   bash build.sh            - build zip only
#   bash build.sh --deploy   - build zip and copy to mods folder

set -e

MOD_NAME="FS25_CustomTriggerCreator"
DEPLOY_DIR="C:/Users/tison/Documents/My Games/FarmingSimulator2025/mods"
OUT_ZIP="${MOD_NAME}.zip"
PYTHON="C:/Users/tison/AppData/Local/Programs/Python/Python313/python.exe"

INCLUDE=(
    main.lua
    modDesc.xml
    icon.dds
    src/
    gui/
    translations/
    xml/
)

echo "==> Building ${OUT_ZIP}..."
rm -f "${OUT_ZIP}"

# Only include paths that exist
EXISTING=()
for item in "${INCLUDE[@]}"; do
    if [ -e "$item" ]; then
        EXISTING+=("$item")
    fi
done

# Use native zip if available; fall back to Python zipfile (forward-slash paths)
if command -v zip &>/dev/null; then
    zip -r "${OUT_ZIP}" "${EXISTING[@]}"
else
    echo "    (zip not found — using Python zipfile fallback)"
    "${PYTHON}" - "${OUT_ZIP}" "${EXISTING[@]}" <<'PYEOF'
import sys, os, zipfile

out  = sys.argv[1]
args = sys.argv[2:]

def add(zf, path):
    if os.path.isfile(path):
        zf.write(path, path.replace("\\", "/"))
    elif os.path.isdir(path):
        for root, dirs, files in os.walk(path):
            for f in files:
                fp = os.path.join(root, f)
                zf.write(fp, fp.replace("\\", "/"))

with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
    for arg in args:
        add(zf, arg)
PYEOF
fi

echo "==> Built: ${OUT_ZIP} ($(du -sh "${OUT_ZIP}" | cut -f1))"

if [[ "$1" == "--deploy" ]]; then
    echo "==> Deploying to ${DEPLOY_DIR}..."
    cp "${OUT_ZIP}" "${DEPLOY_DIR}/${OUT_ZIP}"
    echo "==> Deployed."
fi
