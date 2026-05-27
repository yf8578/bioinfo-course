#!/usr/bin/env bash
set -euo pipefail

REPO="${BIOINFO_COURSE_REPO:-yf8578/bioinfo-course}"
TAG="${BIOINFO_COURSE_REF_TAG:-v1.0.0}"
PREFIX="bioinfo_course.tar.gz"
WORK_DIR=".download_rnaseq_ref"
REF_PATH="bioinfo_course/03_rnaseq_upstream/ref"

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required" >&2
  exit 1
fi

mkdir -p "$WORK_DIR"

api_url="https://api.github.com/repos/${REPO}/releases/tags/${TAG}"

python3 - "$api_url" "$PREFIX" > "$WORK_DIR/urls.txt" <<'PY'
import json
import sys
import urllib.request

api_url, prefix = sys.argv[1], sys.argv[2]
with urllib.request.urlopen(api_url) as response:
    data = json.load(response)

urls = []
for asset in data.get("assets", []):
    name = asset["name"]
    if name.startswith(prefix + ".part-") or name == "SHA256SUMS":
        urls.append((name, asset["browser_download_url"]))

for _, url in sorted(urls):
    print(url)
PY

if [ ! -s "$WORK_DIR/urls.txt" ]; then
  echo "No course data assets found in ${REPO} ${TAG}" >&2
  exit 1
fi

while IFS= read -r url; do
  file="${url##*/}"
  if [ -s "$WORK_DIR/$file" ]; then
    echo "Using existing $file"
  else
    echo "Downloading $file"
    curl -L --retry 5 --retry-delay 5 -C - -o "$WORK_DIR/$file" "$url"
  fi
done < "$WORK_DIR/urls.txt"

if [ -f "$WORK_DIR/SHA256SUMS" ]; then
  (
    cd "$WORK_DIR"
    grep "${PREFIX}" SHA256SUMS > SHA256SUMS.ref
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum -c SHA256SUMS.ref
    else
      shasum -a 256 -c SHA256SUMS.ref
    fi
  )
fi

cat "$WORK_DIR/${PREFIX}.part-"* > "$WORK_DIR/$PREFIX"
tar -xzf "$WORK_DIR/$PREFIX" -C . --strip-components=1 "$REF_PATH"

rm -rf "$WORK_DIR"

echo "RNA-seq reference files are ready under 03_rnaseq_upstream/ref"
echo "Downloaded parts and temporary archive have been removed."
