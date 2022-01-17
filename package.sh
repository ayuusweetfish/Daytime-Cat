#!/bin/sh
rm -rf build
mkdir build
cp -r *.lua res build
cd build

for f in `find . -name "*.lua"`; do
  luamin -f $f > tmp
  mv tmp $f
done

zip DaytimeCat -r *.lua res
mv DaytimeCat.zip DaytimeCat.love

love.js --compatibility --title "Daytime Cat" DaytimeCat.love DaytimeCat-web
cp ../index.html DaytimeCat-web/index.html
rm -rf DaytimeCat-web/theme

zip DaytimeCat-web -r DaytimeCat-web

cd ..
