#!/usr/bin/env bash
set -euo pipefail

IMG="${IMG:-ffmpeg-whip:builder}"
OUT_DIR="${OUT_DIR:-dist}"
BIN_DIR="$OUT_DIR/bin"
LIB_DIR="$OUT_DIR/lib"

rm -rf "$OUT_DIR"
mkdir -p "$BIN_DIR" "$LIB_DIR"

CID="ffmpeg-bundle-$$-$(date +%s)"
docker run -d --name "$CID" "$IMG" sh -lc "sleep infinity" >/dev/null
cleanup() {
  docker rm -f "$CID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker cp "$CID":/out/ffmpeg "$BIN_DIR/ffmpeg"
chmod +x "$BIN_DIR/ffmpeg"

LIBS="$(docker exec "$CID" sh -lc "ldd /out/ffmpeg | grep -Eo '/[^ ]+' | sort -u || true")"
if [ -n "$LIBS" ]; then
  printf '%s\n' "$LIBS" | while IFS= read -r lib; do
    [ -z "$lib" ] && continue
    [ -f "$LIB_DIR/$(basename "$lib")" ] || docker cp "$CID":"$lib" "$LIB_DIR/"
  done
fi

if command -v patchelf >/dev/null 2>&1; then
  patchelf --set-rpath '$ORIGIN/../lib' "$BIN_DIR/ffmpeg" 2>/dev/null || true
fi

ARCH="$(docker image inspect "$IMG" -f '{{.Architecture}}' 2>/dev/null || echo unknown)"
TAR_NAME="ffmpeg-whip-linux-$ARCH.tar.gz"
tar -C "$OUT_DIR" -czf "$TAR_NAME" .
echo "Built: $(pwd)/$TAR_NAME"


