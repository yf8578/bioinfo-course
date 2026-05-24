#!/usr/bin/env bash
set -euo pipefail

SOURCE="${1:-/Users/zhangyifan/Downloads/bioinfo_course.tar.gz}"
ASSET_DIR="${2:-release-assets}"

mkdir -p "$ASSET_DIR"

split -b 1900m -d -a 2 "$SOURCE" "$ASSET_DIR/bioinfo_course.tar.gz.part-"

cd "$ASSET_DIR"
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum bioinfo_course.tar.gz.part-* > SHA256SUMS
else
  shasum -a 256 bioinfo_course.tar.gz.part-* > SHA256SUMS
fi

echo "Prepared release assets in $ASSET_DIR"
