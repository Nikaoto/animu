#! /bin/bash
rm -rf build_tmp
mkdir -p dist build_tmp
name="animu"

# Make .love
cd src
zip -r ../"${name}.zip" .
cd ..
mv "${name}.zip" "${name}.love"

# Make .exe
cat build/love.exe "${name}.love" > "build_tmp/${name}.exe"
cat build/lovec.exe "${name}.love" > "build_tmp/${name}_dbg.exe"

# Copy dlls and license
cp build/*.dll build_tmp/.
cp build/*.txt build_tmp/.

# Package it up
zip -r dist/"${name}_windows.zip" build_tmp/

# Cleanup
rm "${name}.love"
