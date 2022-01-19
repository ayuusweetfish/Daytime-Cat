#!/bin/sh
# BOON=~/dev/boon/target/debug/boon RCEDIT=~/Downloads/rcedit-x64.exe LOVE_ANDROID=~/dev/love-android-11.4 ANDROID_HOME=~/Library/Android/sdk JAVA_HOME=/usr/local/Cellar/openjdk/16.0.1 sh assets/build_release.sh

# Package .love
rm -rf build
mkdir -p build/game
cp -r *.lua res build/game
cd build

for f in `find . -name "*.lua"`; do
  luamin -f $f > tmp
  mv tmp $f
done

# Windows and macOS

# Generate icon
SQUARE_ICON="convert ../res/cat2.png"
${SQUARE_ICON} -scale 256x256 cat.ico

mkdir cat.iconset
${SQUARE_ICON} -scale 16x16     cat.iconset/icon_16x16.png
${SQUARE_ICON} -scale 32x32     cat.iconset/icon_16x16@2x.png
${SQUARE_ICON} -scale 32x32     cat.iconset/icon_32x32.png
${SQUARE_ICON} -scale 64x64     cat.iconset/icon_32x32@2x.png
${SQUARE_ICON} -scale 64x64     cat.iconset/icon_64x64.png
${SQUARE_ICON} -scale 128x128   cat.iconset/icon_64x64@2x.png
${SQUARE_ICON} -scale 128x128   cat.iconset/icon_128x128.png
${SQUARE_ICON} -scale 256x256   cat.iconset/icon_128x128@2x.png
${SQUARE_ICON} -scale 256x256   cat.iconset/icon_256x256.png
${SQUARE_ICON} -scale 512x512   cat.iconset/icon_256x256@2x.png
${SQUARE_ICON} -scale 512x512   cat.iconset/icon_512x512.png
${SQUARE_ICON} -scale 1024x1024 cat.iconset/icon_512x512@2x.png
iconutil -c icns cat.iconset -o cat.icns

# Generate
cp ../package_assets/Boon.toml .
${BOON} build game --target all

cd game/boon
# Replace icons
# win32
unzip DaytimeCat-win32.zip -d DaytimeCat-win32
rm DaytimeCat-win32.zip
wine ${RCEDIT} DaytimeCat-win32/DaytimeCat.exe --set-icon ../../cat.ico
# win64
unzip DaytimeCat-win64.zip -d DaytimeCat-win64
rm DaytimeCat-win64.zip
wine ${RCEDIT} DaytimeCat-win64/DaytimeCat.exe --set-icon ../../cat.ico
# macos
cp ../../cat.icns DaytimeCat.app/Contents/Resources/OS\ X\ AppIcon.icns
rm -rf DaytimeCat.app/Contents/Resources/_CodeSignature
rm DaytimeCat.app/Contents/Resources/Assets.car
rm DaytimeCat.app/Contents/Resources/GameIcon.icns
perl -0777 -pi -e 's/\s<key>CFBundleIconName<\/key>\n\s+<string>OS X AppIcon<\/string>\n//g' DaytimeCat.app/Contents/Info.plist

zip ../../DaytimeCat-win32.zip -r DaytimeCat-win32 -9
zip ../../DaytimeCat-win64.zip -r DaytimeCat-win64 -9
zip ../../DaytimeCat.app.zip -r DaytimeCat.app -9
mv DaytimeCat.love ../..
cd ../..

rm -rf cat.ico cat.iconset cat.icns Boon.toml game

# Android
${SQUARE_ICON} -scale 42x42   ${LOVE_ANDROID}/app/src/main/res/drawable-mdpi/love.png
${SQUARE_ICON} -scale 72x72   ${LOVE_ANDROID}/app/src/main/res/drawable-hdpi/love.png
${SQUARE_ICON} -scale 96x96   ${LOVE_ANDROID}/app/src/main/res/drawable-xhdpi/love.png
${SQUARE_ICON} -scale 144x144 ${LOVE_ANDROID}/app/src/main/res/drawable-xxhdpi/love.png
${SQUARE_ICON} -scale 192x192 ${LOVE_ANDROID}/app/src/main/res/drawable-xxxhdpi/love.png
cp DaytimeCat.love ${LOVE_ANDROID}/app/src/embed/assets/game.love
# Unsigned APK
(cd ${LOVE_ANDROID} && ./gradlew assembleEmbedNoRecordRelease)
cp ${LOVE_ANDROID}/app/build/outputs/apk/embedNoRecord/release/app-embed-noRecord-release-unsigned.apk DaytimeCat.apk
# Sign
# ~/Library/Android/sdk/build-tools/31.0.0/apksigner sign --ks ~/.android/debug.keystore DaytimeCat.apk

# Web
love.js --compatibility --title "Daytime Cat" DaytimeCat.love DaytimeCat-web
cp ../package_assets/index.html DaytimeCat-web/index.html
rm -rf DaytimeCat-web/theme

zip DaytimeCat-web -r DaytimeCat-web
rm -rf DaytimeCat-web

cd ..
