#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Separate --lang flag from curl command arguments
LANG_FLAG=""
CURL_ARGS=()

for arg in "$@"; do
    if [[ "$arg" == --lang=* ]]; then
        LANG_FLAG="$arg"
    else
        CURL_ARGS+=("$arg")
    fi
done

if [ ${#CURL_ARGS[@]} -gt 0 ]; then
    # Curl command passed as argument(s)
    if [ -n "$LANG_FLAG" ]; then
        python3 "$SCRIPT_DIR/convert.py" "$LANG_FLAG" "${CURL_ARGS[@]}"
    else
        python3 "$SCRIPT_DIR/convert.py" "${CURL_ARGS[@]}"
    fi
else
    # Read from stdin
    if [ -n "$LANG_FLAG" ]; then
        python3 "$SCRIPT_DIR/convert.py" "$LANG_FLAG"
    else
        python3 "$SCRIPT_DIR/convert.py"
    fi
fi
