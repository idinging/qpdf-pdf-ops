#!/usr/bin/env bash
# Detect qpdf and verify it meets the minimum version this skill targets.
# Exit 0 if available and >= MIN_VERSION; non-zero otherwise.
#
# The skill assumes qpdf >= 10.6 because earlier versions miss flags used by
# recipes/scripts here (e.g. --json, --collate, modern --split-pages,
# --replace-input atomicity, --is-encrypted exit-code contract).
set -u

MIN_MAJOR=10
MIN_MINOR=6

print_install_hints() {
    echo "Install hints:" >&2
    echo "  Debian/Ubuntu/WSL : sudo apt-get update && sudo apt-get install -y qpdf" >&2
    echo "  Fedora/RHEL       : sudo dnf install -y qpdf" >&2
    echo "  Arch              : sudo pacman -S qpdf" >&2
    echo "  macOS (Homebrew)  : brew install qpdf" >&2
    echo "  Windows (choco)   : choco install qpdf" >&2
    echo "  Source / docs     : https://qpdf.readthedocs.io" >&2
}

if ! command -v qpdf >/dev/null 2>&1; then
    echo "qpdf is not installed." >&2
    echo "" >&2
    print_install_hints
    exit 1
fi

ver_line="$(qpdf --version | head -n1)"
# Expected form: "qpdf version 11.9.0"
ver="$(printf '%s\n' "$ver_line" | awk '{print $NF}')"
major="${ver%%.*}"
rest="${ver#*.}"
minor="${rest%%.*}"

if ! [[ "$major" =~ ^[0-9]+$ ]] || ! [[ "$minor" =~ ^[0-9]+$ ]]; then
    echo "$ver_line" >&2
    echo "WARNING: could not parse qpdf version ($ver). Continuing anyway." >&2
    exit 0
fi

if (( major < MIN_MAJOR )) || { (( major == MIN_MAJOR )) && (( minor < MIN_MINOR )); }; then
    echo "$ver_line" >&2
    echo "WARNING: this skill targets qpdf >= ${MIN_MAJOR}.${MIN_MINOR}. Some recipes may not work on ${ver}." >&2
    echo "" >&2
    print_install_hints
    exit 0
fi

echo "$ver_line"
exit 0
