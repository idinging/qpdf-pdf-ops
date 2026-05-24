#!/usr/bin/env bash
# Merge (concatenate) multiple PDFs into one.
#
# Usage:
#   merge_pdfs.sh [--keep-metadata-from FIRST] <output.pdf> <in1.pdf> <in2.pdf> [...]
#
# By default the merge starts from --empty so the output carries no
# document-level metadata (outlines, tags) from any input. Pass
# --keep-metadata-from FIRST to instead take metadata from the first input
# (its pages are still merged in the same position).
#
# Examples:
#   merge_pdfs.sh out.pdf a.pdf b.pdf c.pdf
#   merge_pdfs.sh --keep-metadata-from FIRST out.pdf cover.pdf body.pdf
#
# To merge specific page ranges, call qpdf directly:
#   qpdf --empty --pages a.pdf 1-5 b.pdf z-1 -- out.pdf

set -euo pipefail

keep_metadata=0
if [[ "${1:-}" == "--keep-metadata-from" ]]; then
    if [[ "${2:-}" != "FIRST" ]]; then
        echo "Only --keep-metadata-from FIRST is supported." >&2
        exit 2
    fi
    keep_metadata=1
    shift 2
fi

if [[ $# -lt 3 ]]; then
    cat >&2 <<EOF
Usage: $0 [--keep-metadata-from FIRST] <output.pdf> <in1.pdf> <in2.pdf> [...]

  --keep-metadata-from FIRST   inherit document metadata from in1.pdf
  output.pdf                   destination
  inN.pdf                      one or more input PDFs, in merge order
EOF
    exit 2
fi

output="$1"
shift
inputs=( "$@" )

for f in "${inputs[@]}"; do
    if [[ ! -f "$f" ]]; then
        echo "Input not found: $f" >&2; exit 2
    fi
done
for f in "${inputs[@]}"; do
    if [[ "$f" -ef "$output" ]]; then
        echo "Refusing to overwrite input in place: $f" >&2; exit 2
    fi
done

out_dir=$(dirname -- "$output")
if [[ -n "$out_dir" && ! -d "$out_dir" ]]; then
    mkdir -p -- "$out_dir"
fi

if [[ "$keep_metadata" -eq 1 ]]; then
    first="${inputs[0]}"
    rest=( "${inputs[@]:1}" )
    # primary is "$first"; --pages . expands its full range, then rest follow
    qpdf "$first" --pages . "${rest[@]}" -- "$output"
else
    qpdf --empty --pages "${inputs[@]}" -- "$output"
fi

total=$(qpdf --show-npages "$output")
echo "Wrote $output (${total} pages from ${#inputs[@]} files)"
