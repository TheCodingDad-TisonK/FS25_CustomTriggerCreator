#!/usr/bin/env bash
# build.sh - Build and optionally deploy FS25_CustomTriggerCreator
# Usage:
#   bash build.sh            - build zip only
#   bash build.sh --deploy   - build zip and copy to mods folder

set -e

MOD_NAME="FS25_CustomTriggerCreator"
DEPLOY_DIR="C:/Users/tison/Documents/My Games/FarmingSimulator2025/mods"
OUT_ZIP="${MOD_NAME}.zip"

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

zip -r "${OUT_ZIP}" "${EXISTING[@]}"
echo "==> Built: ${OUT_ZIP} ($(du -sh "${OUT_ZIP}" | cut -f1))"

if [[ "$1" == "--deploy" ]]; then
    echo "==> Deploying to ${DEPLOY_DIR}..."
    cp "${OUT_ZIP}" "${DEPLOY_DIR}/${OUT_ZIP}"
    echo "==> Deployed."
fi
