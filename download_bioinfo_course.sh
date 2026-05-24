#!/usr/bin/env bash
set -euo pipefail

REPO="${BIOINFO_COURSE_REPO:-OWNER/bioinfo-course}"
TAG="${BIOINFO_COURSE_TAG:-v1.0.0}"
OUT="${BIOINFO_COURSE_OUT:-bioinfo_course.tar.gz}"

api_url="https://api.github.com/repos/${REPO}/releases/tags/${TAG}"

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required" >&2
  exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  mapfile -t urls < <(
    python3 - "$api_url" <<'PY'
import json
import sys
import urllib.request

with urllib.request.urlopen(sys.argv[1]) as response:
    data = json.load(response)

for asset in sorted(data.get("assets", []), key=lambda item: item["name"]):
    name = asset["name"]
    if name.startswith("bioinfo_course.tar.gz.part-") or name == "SHA256SUMS":
        print(asset["browser_download_url"])
PY
  )
else
  echo "python3 is required to read GitHub release metadata" >&2
  exit 1
fi

if [ "${#urls[@]}" -eq 0 ]; then
  echo "No release assets found at ${api_url}" >&2
  exit 1
fi

mkdir -p bioinfo_course_download
cd bioinfo_course_download

for url in "${urls[@]}"; do
  file="${url##*/}"
  if [ -s "$file" ]; then
    echo "Using existing $file"
  else
    echo "Downloading $file"
    curl -L --retry 5 --retry-delay 5 -C - -o "$file" "$url"
  fi
done

if [ -f SHA256SUMS ]; then
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c SHA256SUMS
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -c SHA256SUMS
  fi
fi

cat bioinfo_course.tar.gz.part-* > "../${OUT}"
echo "Wrote ${OUT}"
