#! /bin/bash
# Builds .love file
set -e

GAME_NAME=${GAME_NAME:-animu}
DIST_DIR=${DIST_DIR:-dist}
echo "Building LOVE package: ${DIST_DIR}/${GAME_NAME}.love"

mkdir -p "$DIST_DIR"
rm -rf "${DIST_DIR}/${GAME_NAME}.love"

cd src
zip -q -r "../${DIST_DIR}/${GAME_NAME}.love" .
cd ..

echo "LOVE package built: ${DIST_DIR}/${GAME_NAME}.love"
