#!/usr/bin/env bash
# Download aria2-next release binaries for packaging.
# Usage: ./tool/fetch_engine.sh [version]
# Example: ./tool/fetch_engine.sh v2.5.1
set -euo pipefail

VERSION="${1:-v2.5.1}"
REPO="AnInsomniacy/aria2-next"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/tool/dist/engine/${VERSION}"
BASE="https://github.com/${REPO}/releases/download/${VERSION}"

mkdir -p "${OUT}"

assets=(
  "aria2-next-${VERSION#v}-linux-x86_64"
  "aria2-next-${VERSION#v}-linux-aarch64"
  "aria2-next-${VERSION#v}-windows-x86_64.exe"
  "aria2-next-${VERSION#v}-android-arm64"
  "aria2-next-${VERSION#v}-checksums.sha256"
)

# Release asset names use full version without forcing strip; try tag-based names from README.
# Fallback pattern from upstream README:
#   aria2-next-<version>-linux-x86_64
VER_NUM="${VERSION#v}"
assets=(
  "aria2-next-${VER_NUM}-linux-x86_64"
  "aria2-next-${VER_NUM}-linux-aarch64"
  "aria2-next-${VER_NUM}-windows-x86_64.exe"
  "aria2-next-${VER_NUM}-android-arm64"
  "aria2-next-${VER_NUM}-checksums.sha256"
)

echo "Fetching aria2-next ${VERSION} → ${OUT}"
for name in "${assets[@]}"; do
  url="${BASE}/${name}"
  dest="${OUT}/${name}"
  if [[ -f "${dest}" ]]; then
    echo "skip (exists): ${name}"
    continue
  fi
  echo "GET ${url}"
  curl -fL --retry 3 -o "${dest}" "${url}"
done

echo "Done. Files in ${OUT}"
ls -la "${OUT}"
