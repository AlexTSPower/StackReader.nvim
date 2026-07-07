#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/.local/share/nvim/stackreader/bin"
mkdir -p "${INSTALL_DIR}"

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "${OS}" in
  darwin) OS="darwin" ;;
  linux)  OS="linux"  ;;
  *) echo "Unsupported OS: ${OS}" >&2; exit 1 ;;
esac

# Detect arch
ARCH=$(uname -m)
case "${ARCH}" in
  x86_64)        ARCH="amd64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *) echo "Unsupported arch: ${ARCH}" >&2; exit 1 ;;
esac

# Fetch latest release tag from GitHub API
API_URL="https://api.github.com/repos/AlexTSPower/StackReader/releases/latest"
TAG=$(curl -fsSL "${API_URL}" | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

if [ -z "${TAG}" ]; then
  echo "Failed to fetch latest release tag from GitHub" >&2
  exit 1
fi

VERSION="${TAG#v}"
TARBALL="stackreader_${VERSION}_${OS}_${ARCH}.tar.gz"
URL="https://github.com/AlexTSPower/StackReader/releases/download/${TAG}/${TARBALL}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "${TMPDIR}"' EXIT

echo "Downloading ${TARBALL}..."
curl -fsSL -o "${TMPDIR}/${TARBALL}" "${URL}"

echo "Extracting..."
tar -xzf "${TMPDIR}/${TARBALL}" -C "${TMPDIR}"

cp "${TMPDIR}/stackreader" "${INSTALL_DIR}/stackreader"
chmod +x "${INSTALL_DIR}/stackreader"

echo "StackReader ${TAG} installed to ${INSTALL_DIR}/stackreader"
