#!/bin/sh

# FFmpeg Utilities named colours montage by Raymond Luckhurst, Scriptit UK, https://scriptit.uk
# GitHub: owner scriptituk; repository ffmpeg-colours https://github.com/scriptituk/ffmpeg-colours
# See https://ffmpeg.org/ffmpeg-utils.html#Color
# Usage ffmpeg-colours.sh [hsv]

nbsp=$'\xC2\xA0'
size=118x73 # Phi

order=name
sort=-k1f
[[ $1 == hsv ]] && order=hsv && sort='-k6n -k7n -k8n'

TMP=tmp-fc
mkdir -p $TMP/$order

if [[ ! -f $TMP/parseutils.c ]]; then
    wget -q -P $TMP https://raw.githubusercontent.com/FFmpeg/FFmpeg/master/libavutil/parseutils.c
fi
gsed -n -e '/color_table\[\]/,/^\};/{//!p}' $TMP/parseutils.c > $TMP/color_table.txt

gawk --non-decimal-data '
function hex2dec(h) {
    sub(/,/, "", h)
    sub(/0x/, "", h)
    return +sprintf("%d", "0x" h)
}
function rgb2hsv(r, g, b, _h, _s, _v, _m, _d) {
    _m = r > g ? r : g; if (_m < b) _m = b; # max
    _h = _s = 0
    _v = int(_m / 255 * 100 + 0.5) # percent
    if (_m) {
        _d = r < g ? r : g; if (_d > b) _d = b; # min
        _d = _m - _d # max - min
        _s = int(_d / _m * 100 + 0.5) # percent
        if (_d) {
            if (r == _m)
                _h = 0 + (g - b) / _d
            else if (g == _m)
                _h = 2 + (b - r) / _d
            else
                _h = 4 + (r - g) / _d
            _h = int(_h * 60 + 0.5) # degrees
            if (_h < 0)
                _h += 360
        }
    }
    return _h "," _s "," _v
}
{
    c = $2 # colour
    gsub(/[",]/, "", c)

    rgb = $4 $5 $6
    gsub(/, *0x/, "", rgb)
    sub(/0x/, "#", rgb)

    r = hex2dec($4)
    g = hex2dec($5)
    b = hex2dec($6)
    hsv = rgb2hsv(r, g, b)
    split(hsv, a, ",")

    print c, rgb, r, g, b, a[1], a[2], a[3]
}
' $TMP/color_table.txt |
while read c rgb r g b h s v; do
    echo $c $rgb $r $g $b $h $s $v
done |
sort $sort |
while read c rgb r g b h s v; do
    i=$((i+1))
    o=$(printf '%03d-%s' $i $c)
    if [[ ! -f $TMP/$order/$o.png ]]; then
        convert -size $size xc:$rgb -font Arial-Bold -pointsize 12 -fill white -undercolor '#0008' -gravity center -annotate 0 "$nbsp$c$nbsp\n$nbsp$rgb$nbsp" PNG8:$TMP/$order/$o.png
    fi
done

montage $TMP/$order/* -tile 5x -geometry +1+1 ffmpeg-colours-$order.png

which -s optipng && optipng -quiet -clobber -o7 -out ffmpeg-colours-$order.png ffmpeg-colours-$order.png

rm -fr $TMP
