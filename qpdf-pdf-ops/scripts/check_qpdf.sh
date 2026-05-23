#!/usr/bin/env bash
# Detect qpdf and print install hint when missing.
# Exit 0 if available; non-zero if missing.
set -u

if command -v qpdf >/dev/null 2>&1; then
    qpdf --version | head -n1
    exit 0
fi

echo "qpdf is not installed." >&2
echo "" >&2
echo "Install hints:" >&2
echo "  Debian/Ubuntu/WSL : sudo apt-get update && sudo apt-get install -y qpdf" >&2
echo "  Fedora/RHEL       : sudo dnf install -y qpdf" >&2
echo "  Arch              : sudo pacman -S qpdf" >&2
echo "  macOS (Homebrew)  : brew install qpdf" >&2
echo "  Windows (choco)   : choco install qpdf" >&2
echo "  Source / docs     : https://qpdf.readthedocs.io" >&2
exit 1
