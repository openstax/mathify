#!/usr/bin/env bash

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

clean_sha() {
    file="$1"
    sha256sum "$file" | awk -v name="$(basename "$file")" '$0=$1" "name'
}

snapshot() {
    i="$1"
    o="$2"
    shift 2
    node "$HERE/typeset/start.js" -i "$i" -o "$o" "$@"
    clean_sha "$o" >> "$HERE/hashes.txt"
}

echo -n > "$HERE/hashes.txt"
snapshot "$HERE/typeset/tests/seed/test.baked.xhtml" "$HERE/typeset/tests/svg.output.xhtml" -f svg
snapshot "$HERE/typeset/tests/seed/test-latex.xhtml" "$HERE/typeset/tests/mathml.output.xhtml" -f mathml
