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

function cropResize() {
    src="$1"
    dest="$2"
    destfile="$3"
    w=$4
    h=$5
    extra=$6

    src_size=`identify "$src" | cut -d\  -f3`
    src_w=`echo $src_size | cut -dx -f1`
    src_h=`echo $src_size | cut -dx -f2`

    if [ "x$h" = "x" ]; then
        h=$((w * src_h / src_w))
    fi
    size="${w}x${h}"

    dst_size=""
    if test -e "$dest/img/$destfile"; then
        dst_size=`identify "$dest/img/$destfile" | cut -d\  -f3`
        if [ x$size != x$dst_size ]; then
            size_changed=YES
        fi
    fi

    hd_w=$((w * 2))
    if [ $hd_w -gt $src_w ]; then
        echo
        echo "[WARNING] Resizing $src from $src_w to $hd_w."
        echo
    fi

    mkdir -p "$dest/img"
    if test "$src" -nt "$dest/img/$destfile" || test ! -e "$dest/img/$destfile" || [ x$size_changed = xYES ]; then
        convert "$src" -resize $size\! "$dest/img/$destfile"
    fi

    w2=$((w * 2))
    h2=$((h * 2))
    size="${w2}x${h2}"
    mkdir -p "$dest/img-hd"
    if test "$src" -nt "$dest/img-hd/$destfile" || test ! -e "$dest/img-hd/$destfile" || [ x$size_changed = xYES ]; then
        convert "$src" -resize $size\! "$dest/img-hd/$destfile"
    fi

    w2=$((w / 2))
    h2=$((h / 2))
    size="${w2}x${h2}"
    mkdir -p "$dest/img-ld"
    if test "$src" -nt "$dest/img-ld/$destfile" || test ! -e "$dest/img-ld/$destfile" || [ x$size_changed = xYES ]; then
        convert "$src" -resize $size\! "$dest/img-ld/$destfile"
    fi
}

FILE=$1
W=$2
H=$3
if [ x$W = x ]; then
    echo "wrong arguments: $FILE $W $H"
    usage
fi

DEST=build/www

SRC="assets/$FILE"
if test -e "$SRC"; then
    cropResize "$SRC" "$DEST" $W $H
else
    SRC="app/img/$FILE"
    if test -e "$SRC"; then
        cropResize "$SRC" "$DEST" "$FILE" $W $H
    else
        echo "none of assets/$FILE and app/img/$FILE exist"
        usage
    fi
fi