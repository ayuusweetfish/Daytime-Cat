#!/bin/sh
zip DaytimeCat -r *.lua res
mv DaytimeCat.zip DaytimeCat.love

rm -rf DaytimeCat-web
love.js --compatibility --title "Daytime Cat" DaytimeCat.love DaytimeCat-web
cp index.html DaytimeCat-web/index.html
rm -rf DaytimeCat-web/theme

rm DaytimeCat-web.zip
zip DaytimeCat-web -r DaytimeCat-web
