#!/usr/bin/env bash
# Print basic info for a PDF: page count, encryption status, integrity check.
# Usage: pdf_info.sh <file.pdf>
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <file.pdf>" >&2
    exit 2
fi

f="$1"
if [[ ! -f "$f" ]]; then
    echo "File not found: $f" >&2
    exit 2
fi

echo "File       : $f"
echo "Pages      : $(qpdf --show-npages "$f")"

if qpdf --is-encrypted "$f"; then
    echo "Encrypted  : yes"
else
    echo "Encrypted  : no"
fi

echo "Integrity  :"
qpdf --check "$f" || true
