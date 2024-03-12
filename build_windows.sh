#! /bin/bash
set -e

export GAME_NAME="animu"
export DIST_DIR="dist"
export BUILD_DIR="build/windows"

WIN_DIST_DIR="${DIST_DIR}/${GAME_NAME}_windows"

./build_love.sh

mkdir -p "$DIST_DIR"
mkdir -p "$WIN_DIST_DIR"

# Make .exe
cat "${BUILD_DIR}/love.exe" "${DIST_DIR}/${GAME_NAME}.love" > \
    "${WIN_DIST_DIR}/${GAME_NAME}.exe"
cat "${BUILD_DIR}/lovec.exe" "${DIST_DIR}/${GAME_NAME}.love" > \
    "${WIN_DIST_DIR}/${GAME_NAME}_dbg.exe"

# Copy dlls and license
cp "${BUILD_DIR}"/*.dll "${WIN_DIST_DIR}/."
cp "${BUILD_DIR}"/*.txt "${WIN_DIST_DIR}/."

# Create zip
cd "$DIST_DIR"
zip -q -r "${GAME_NAME}_windows.zip" "${GAME_NAME}_windows"
cd ..

echo "Windows package built: ${WIN_DIST_DIR}/"
echo "Windows package built: ${DIST_DIR}/${GAME_NAME}_windows.zip"
