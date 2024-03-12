#! /bin/bash
set -e

export GAME_NAME="animu"
export DIST_DIR="dist"
export BUILD_APP_PATH="build/osx/game.app"
export OSX_BUNDLE_NAME="Animu"
export OSX_LOWER_NAME="animu"

OSX_DIST_DIR="${DIST_DIR}/${GAME_NAME}_osx"

./build_love.sh

# Move .love into .app
rm -rf "$OSX_DIST_DIR"
mkdir -p "$OSX_DIST_DIR"
cp -r "$BUILD_APP_PATH" "${OSX_DIST_DIR}/${GAME_NAME}.app"
cp "${DIST_DIR}/${GAME_NAME}.love" \
   "${OSX_DIST_DIR}/${GAME_NAME}.app/Contents/Resources/."

# Update Info.plist
sed -i="" "s/_game_name/${OSX_LOWER_NAME}/g" \
    "${OSX_DIST_DIR}/${GAME_NAME}.app/Contents/Info.plist"

sed -i="" "s/_Game_Name/${OSX_BUNDLE_NAME}/g" \
    "${OSX_DIST_DIR}/${GAME_NAME}.app/Contents/Info.plist"

# Zip it
cd "$DIST_DIR"
tar zcf "${GAME_NAME}_osx.app.tar.gz" "${GAME_NAME}_osx"

echo "OSX package built: ${OSX_DIST_DIR}"
echo "OSX package built: ${OSX_DIST_DIR}.app.tar.gz"
