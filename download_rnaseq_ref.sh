#!/usr/bin/env bash
set -euo pipefail

REPO="${BIOINFO_COURSE_REPO:-yf8578/bioinfo-course}"
TAG="${BIOINFO_COURSE_REF_TAG:-v1.0.0}"
PREFIX="bioinfo_course.tar.gz"
WORK_DIR=".download_rnaseq_ref"
REF_PATH="bioinfo_course/03_rnaseq_upstream/ref"
TARGET_REF_DIR="03_rnaseq_upstream/ref"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

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

python3 - "$api_url" "$PREFIX" > "$WORK_DIR/assets.tsv" <<'PY'
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

for name, url in sorted(urls):
    print(f"{name}\t{url}")
PY

if [ ! -s "$WORK_DIR/assets.tsv" ]; then
  echo "No course data assets found in ${REPO} ${TAG}" >&2
  exit 1
fi

if [ -f "${TARGET_REF_DIR}/hg38.fa" ] && \
   [ -f "${TARGET_REF_DIR}/hisat2_index/hg38.1.ht2" ] && \
   [ "$(find "${TARGET_REF_DIR}/hisat2_index" -name 'hg38.*.ht2' | wc -l | tr -d ' ')" = "8" ]; then
  echo "RNA-seq reference files already exist under ${TARGET_REF_DIR}"
  echo "Skip download."
  exit 0
fi

echo "Downloading and extracting RNA-seq reference files in streaming mode."
echo "This avoids creating an extra merged ${PREFIX} file on disk."

awk -F '\t' -v prefix="${PREFIX}.part-" '$1 ~ ("^" prefix) {print $2}' "$WORK_DIR/assets.tsv" > "$WORK_DIR/part_urls.txt"

if [ ! -s "$WORK_DIR/part_urls.txt" ]; then
  echo "No split archive parts found for ${PREFIX}" >&2
  exit 1
fi

while IFS= read -r url; do
  echo "[INFO] Streaming ${url##*/}" >&2
  curl -L --fail --retry 5 --retry-delay 5 "$url"
done < "$WORK_DIR/part_urls.txt" | tar -xzf - -C . --strip-components=1 "$REF_PATH"

echo "RNA-seq reference files are ready under 03_rnaseq_upstream/ref"
echo "No split archive or merged temporary archive was kept on disk."
