#!/usr/bin/env bash
# Print basic info for a PDF: file size, page count, encryption, integrity.
#
# Usage: pdf_info.sh <file.pdf> [--verbose]
#
# Default output is a compact summary. Pass --verbose to also dump the full
# qpdf --check output (structural details, useful when integrity is not OK).
set -uo pipefail

verbose=0
file=""
for arg in "$@"; do
    case "$arg" in
        --verbose|-v) verbose=1 ;;
        -h|--help)
            echo "Usage: $0 <file.pdf> [--verbose]" >&2
            exit 0
            ;;
        *)
            if [[ -z "$file" ]]; then
                file="$arg"
            else
                echo "Unexpected argument: $arg" >&2
                exit 2
            fi
            ;;
    esac
done

if [[ -z "$file" ]]; then
    echo "Usage: $0 <file.pdf> [--verbose]" >&2
    exit 2
fi
if [[ ! -f "$file" ]]; then
    echo "File not found: $file" >&2
    exit 2
fi

size_human() {
    local bytes="$1"
    if   (( bytes >= 1073741824 )); then printf '%.1f GiB' "$(echo "$bytes/1073741824" | bc -l)"
    elif (( bytes >= 1048576 ));    then printf '%.1f MiB' "$(echo "$bytes/1048576"    | bc -l)"
    elif (( bytes >= 1024 ));       then printf '%.1f KiB' "$(echo "$bytes/1024"       | bc -l)"
    else printf '%d B' "$bytes"
    fi
}

bytes=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)

echo "File       : $file"
echo "Size       : $(size_human "$bytes") (${bytes} bytes)"

# Encryption: qpdf --is-encrypted exits 0 if encrypted, 2 if not, !=0 on error
if qpdf --is-encrypted "$file" 2>/dev/null; then
    encrypted=1
    echo "Encrypted  : yes (operations require --password=...)"
else
    rc=$?
    if [[ "$rc" -eq 2 ]]; then
        encrypted=0
        echo "Encrypted  : no"
    else
        encrypted=0
        echo "Encrypted  : unknown (qpdf --is-encrypted exit $rc)"
    fi
fi

# Page count (skip if encrypted; --show-npages would prompt for password)
if [[ "$encrypted" -eq 0 ]]; then
    pages=$(qpdf --show-npages "$file" 2>/dev/null || echo "?")
    echo "Pages      : $pages"
else
    echo "Pages      : (locked — pass --password to qpdf)"
fi

# PDF version, from the header bytes (cheap, works on encrypted files)
header=$(head -c 16 "$file" 2>/dev/null | tr -d '\000-\010\013-\037' | head -c 16)
if [[ "$header" =~ %PDF-([0-9]+\.[0-9]+) ]]; then
    echo "PDF ver    : ${BASH_REMATCH[1]}"
fi

# Integrity (--check). Summarise to one line by default.
if [[ "$encrypted" -eq 0 ]]; then
    check_out=$(qpdf --check "$file" 2>&1)
    check_rc=$?
    if [[ "$check_rc" -eq 0 ]]; then
        echo "Integrity  : OK"
    elif [[ "$check_rc" -eq 3 ]]; then
        echo "Integrity  : OK with warnings (run with --verbose for details)"
    else
        echo "Integrity  : ERRORS (run with --verbose for details)"
    fi
    if [[ "$verbose" -eq 1 ]]; then
        echo "--- qpdf --check ---"
        printf '%s\n' "$check_out"
    fi
else
    echo "Integrity  : (locked — pass --password to qpdf --check)"
fi
