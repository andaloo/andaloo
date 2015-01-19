#!/bin/bash

which convert > /dev/null || error "ImageMagick not installed or not in PATH"

function cropResize() {
    src="$1"
    dest="$2"
    w="$3"
    h="$4"
    extra="$5"
    extra_before="$6"
    size="${w}x${h}"
    echo -n . # "Resize $src -> $dest $size    $extra"
    convert "$src" $extra_before -resize $size^ -gravity Center -crop $size+0+0 +repage $extra "$dest"
}

ICON_PATH="$IOS_PROJECT_PATH/platforms/ios/$PROJECT_NAME/Resources/icons"
SPLASH_PATH="$IOS_PROJECT_PATH/platforms/ios/$PROJECT_NAME/Resources/splash"

DEFAULT="$PROJECT_PATH/assets/Default.png"
ICON="$PROJECT_PATH/assets/Icon.png"

extraiphone=
if [ "x$SCREEN_MODE" = "xLANDSCAPE" ]; then
    extraiphone="-rotate 270"
fi

cropResize "$DEFAULT" "$SPLASH_PATH/Default-568h@2x~iphone.png" 639 1136 " " "$extraiphone"
cropResize "$DEFAULT" "$SPLASH_PATH/Default-Landscape@2x~ipad.png" 2048 1536
cropResize "$DEFAULT" "$SPLASH_PATH/Default-Landscape~ipad.png" 1024 768
cropResize "$DEFAULT" "$SPLASH_PATH/Default-Portrait@2x~ipad.png" 1536 2016
cropResize "$DEFAULT" "$SPLASH_PATH/Default-Portrait~ipad.png" 768 1024
cropResize "$DEFAULT" "$SPLASH_PATH/Default@2x~iphone.png" 640 960 " " "$extraiphone"
cropResize "$DEFAULT" "$SPLASH_PATH/Default~iphone.png" 320 480 " " "$extraiphone"
cropResize "$DEFAULT" "$SPLASH_PATH/Default-667h.png" 750 1334 " " "$extraiphone"
cropResize "$DEFAULT" "$SPLASH_PATH/Default-736h.png" 1242 2208 " " "$extraiphone"
cropResize "$DEFAULT" "$SPLASH_PATH/Default-Landscape-736h.png" 2208 1242

cropResize "$ICON" "$ICON_PATH/icon-40.png" 40 40 -flatten
cropResize "$ICON" "$ICON_PATH/icon-40@2x.png" 80 80 -flatten
cropResize "$ICON" "$ICON_PATH/icon-50.png" 50 50 -flatten
cropResize "$ICON" "$ICON_PATH/icon-50@2x.png" 100 100 -flatten
cropResize "$ICON" "$ICON_PATH/icon-60.png" 60 60 -flatten
cropResize "$ICON" "$ICON_PATH/icon-60@2x.png" 120 120 -flatten
cropResize "$ICON" "$ICON_PATH/icon-60@3x.png" 180 180 -flatten
cropResize "$ICON" "$ICON_PATH/icon-72.png" 72 72 -flatten
cropResize "$ICON" "$ICON_PATH/icon-72@2x.png" 144 144 -flatten
cropResize "$ICON" "$ICON_PATH/icon-76.png" 76 76 -flatten
cropResize "$ICON" "$ICON_PATH/icon-76@2x.png" 152 152 -flatten
cropResize "$ICON" "$ICON_PATH/icon.png" 57 57 -flatten
cropResize "$ICON" "$ICON_PATH/icon@2x.png" 114 114 -flatten
cropResize "$ICON" "$ICON_PATH/icon-small.png" 29 29 -flatten
cropResize "$ICON" "$ICON_PATH/icon-small@2x.png" 58 58 -flatten

