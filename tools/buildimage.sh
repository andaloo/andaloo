#!/bin/bash

function usage() {
    echo "usage: $0 <filename> <w> <h>"
    echo
    echo "Resize image"
    exit 1
}

test -e "$PROJECT_PATH" || error "This script should't be called directly"

cd "$PROJECT_PATH"
which convert > /dev/null || error "ImageMagick not installed or not in PATH"

function readImageSIZE() {
    f="$1"
    if which md5 > /dev/null; then
        f_cache=`md5 -q -s "$f"`
    else
        f_cache=`echo $f | md5sum | cut -d\  -f1`
    fi
    cache_file="build/tmp/cache/$f_cache"
    if test "$f" -nt "$cache_file"; then
        mkdir -p "build/tmp/cache"
        identify "$f" | head -1 | cut -d\  -f3 > "$cache_file"
    fi

    SIZE=`cat "$cache_file"`
}

function cropResize() {
    src="$1"
    dest="$2"
    typ="$3"
    destfile="$4"
    w=$5
    h=$6
    extra=$7

    destfile="`basename $destfile .png`.$typ"

    # Extract source image size
    readImageSIZE "$src"
    src_w=`echo $SIZE | cut -dx -f1`
    src_h=`echo $SIZE | cut -dx -f2`

    # No output height specified? Compute from source aspect ratio.
    if [ "x$h" = "x" ]; then
        h=$((w * src_h / src_w))
    fi
    size="${w}x${h}"

    # Extract destination image size if exists
    dst_size=""
    if test -e "$dest/img/$destfile"; then
        readImageSIZE "$dest/img/$destfile"
        if [ x$size != x$SIZE ]; then

            # Size is not as expected, we'll rebuild.
            size_changed=YES
        fi
    fi

    # Compute HD width
    hd_w=$((w * 2))
    if [ $hd_w -gt $src_w ]; then
        echo "[WARNING] Resizing $src from $src_w to $hd_w." >> build/logs.txt
    fi

    if test "$src" -nt "$dest/img/$destfile" || [ x$size_changed = xYES ]; then

        # Prepare directories
        mkdir -p "$dest/img"
        mkdir -p "$dest/img-hd"
        mkdir -p "$dest/img-ld"

        convert "$src" -resize $size\! "$dest/img/$destfile" 2>&1 >> build/logs.txt
    fi

    if test "$src" -nt "$dest/img-hd/$destfile" || [ x$size_changed = xYES ]; then
        w2=$((w * 2))
        h2=$((h * 2))
        size="${w2}x${h2}"
        convert "$src" -resize $size\! "$dest/img-hd/$destfile" 2>&1 >> build/logs.txt
    fi

    if test "$src" -nt "$dest/img-ld/$destfile" || [ x$size_changed = xYES ]; then
        w2=$((w / 2))
        h2=$((h / 2))
        size="${w2}x${h2}"
        convert "$src" -resize $size\! "$dest/img-ld/$destfile" 2>&1 >> build/logs.txt
    fi
}

FILE=$1
W=$2
H=$3
TYPE=$4
DEST=build/www

if [ x$W = x ]; then
    echo "wrong arguments: $FILE $W $H"
    usage
fi
if [ x$H = xauto ]; then
    H=""
fi

if [ x$TYPE = xgif ]; then
    cp "assets/$FILE" "$DEST/img/$FILE" 2> /dev/null || cp "app/img/$FILE" "$DEST/img/$FILE"
    exit 0
fi

if [ x$TYPE != xpng ] && [ x$TYPE != xjpg ] && [ x$TYPE != xgif ]; then
    TYPE=png
fi

SRC="assets/$FILE"
if test -e "$SRC"; then
    cropResize "$SRC" "$DEST" "$TYPE" "$FILE" $W $H
else
    SRC="app/img/$FILE"
    if test -e "$SRC"; then
        cropResize "$SRC" "$DEST" "$TYPE" "$FILE" $W $H
    else
        echo "none of assets/$FILE and app/img/$FILE exist"
        usage
    fi
fi
