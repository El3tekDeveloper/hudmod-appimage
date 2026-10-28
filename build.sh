#!/usr/bin/env bash
# Rebuild the HudMod AppImage from a GitHub release.
#   ./build.sh                 -> alpha.2
#   ./build.sh alpha.3 1.0.0-alpha.3
set -euo pipefail

TAG="${1:-alpha.2}"
VERSION="${2:-1.0.0-$TAG}"
SRC="$(cd "$(dirname "$0")" && pwd)"
WORK="${WORK:-$SRC/_build}"
B="$WORK/HudMod.AppDir"
URL="https://github.com/OmarBalita/HudMod-Public/releases/download/$TAG/linux64.zip"
ICON_URL="https://raw.githubusercontent.com/OmarBalita/HudMod-Public/main/Asset/Icons/App/logo2-mid.png"

rm -rf "$WORK" && mkdir -p "$WORK/zip" "$B"/usr/{lib/hudmod,bin,share/hudmod,share/mime/packages,share/applications}
curl -fL -o "$WORK/linux64.zip" "$URL"
curl -fL -o "$WORK/logo.png" "$ICON_URL"
unzip -q "$WORK/linux64.zip" -d "$WORK/zip"
cp -a "$WORK/zip/." "$B/usr/lib/hudmod/"
rm -rf "$B/usr/lib/hudmod/global"       # empty dirs; HudMod keeps data in ~/.local/share/HudMod Video Editor/
chmod +x "$B/usr/lib/hudmod/HudMod.x86_64"

install -m755 "$SRC/AppRun"           "$B/AppRun"
install -m755 "$SRC/hudmod-integrate" "$B/usr/bin/hudmod-integrate"
sed -i "s/^VERSION=.*/VERSION=\"$VERSION\"/" "$B/usr/bin/hudmod-integrate"
sed "s/^X-AppImage-Version=.*/X-AppImage-Version=$VERSION/" "$SRC/hudmod.desktop" > "$B/hudmod.desktop"
cp "$B/hudmod.desktop" "$B/usr/share/applications/hudmod.desktop"
install -m644 "$SRC/hudmod.desktop.in"  "$B/usr/share/hudmod/"
install -m644 "$SRC/hudmod-project.xml" "$B/usr/share/mime/packages/"

resize() {  # resize <in> <size> <out>
    if command -v magick >/dev/null; then magick "$1" -resize "${2}x${2}" "$3"
    elif command -v convert >/dev/null; then convert "$1" -resize "${2}x${2}" "$3"
    else ffmpeg -loglevel error -y -i "$1" -vf "scale=${2}:${2}:force_original_aspect_ratio=decrease:flags=lanczos" "$3"
    fi
}
for s in 16 32 48 64 128 256; do
    mkdir -p "$B/usr/share/icons/hicolor/${s}x${s}/apps"
    resize "$WORK/logo.png" "$s" "$B/usr/share/icons/hicolor/${s}x${s}/apps/hudmod.png"
done
cp "$B/usr/share/icons/hicolor/256x256/apps/hudmod.png" "$B/hudmod.png"
ln -sf hudmod.png "$B/.DirIcon"

APPIMAGETOOL="${APPIMAGETOOL:-appimagetool}"
if ! command -v "$APPIMAGETOOL" >/dev/null; then
    curl -fL -o "$WORK/appimagetool" https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x "$WORK/appimagetool"; APPIMAGETOOL="$WORK/appimagetool"
fi
ARCH=x86_64 "$APPIMAGETOOL" --comp zstd "$B" "$SRC/HudMod-$TAG-x86_64.AppImage"
echo "Built $SRC/HudMod-$TAG-x86_64.AppImage"
