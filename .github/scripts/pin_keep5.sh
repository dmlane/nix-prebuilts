#!/usr/bin/env bash
# pin_keep5.sh
#
# Pin a Nix build result to a Cachix cache and keep only the 5 newest pins.
#
# Usage:
#   .github/scripts/pin_keep5.sh <cache-name> <package-name> <store-path-or-symlink>
#
# Example:
#   .github/scripts/pin_keep5.sh dmlane mypkg ./result

set -euo pipefail

CACHE_NAME="$1"
PACKAGE_NAME="$2"
STORE_PATH="$3"

# Resolve symlink to absolute store path (works on macOS & Linux)
if [ -L "$STORE_PATH" ]; then
    if command -v realpath > /dev/null 2>&1; then
        STORE_PATH="$(realpath "$STORE_PATH")"
    else
        # Fallback if realpath isn't available
        STORE_PATH="$(cd "$(dirname "$STORE_PATH")" && pwd)/$(basename "$STORE_PATH")"
    fi
fi

if [ ! -e "$STORE_PATH" ]; then
    echo "Error: store path '$STORE_PATH' does not exist."
    exit 1
fi

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
PIN_NAME="${PACKAGE_NAME}-${TIMESTAMP}"

echo ">>> Pinning $STORE_PATH as $PIN_NAME in cache $CACHE_NAME"
cachix pin "$CACHE_NAME" "$PIN_NAME" "$STORE_PATH"

echo ">>> Trimming to keep only the newest 5 pins for $PACKAGE_NAME"
ALL_PINS=$(cachix pin list "$CACHE_NAME" |
    awk -v pkg="$PACKAGE_NAME" '$1 ~ "^"pkg"-" {print $1}' |
    sort)

KEEP=$(echo "$ALL_PINS" | tail -n 5)

for p in $ALL_PINS; do
    if ! echo "$KEEP" | grep -qx "$p"; then
        echo "Unpinning old pin $p"
        cachix pin remove "$CACHE_NAME" "$p"
    fi
done

echo ">>> Remaining pins for $PACKAGE_NAME:"
cachix pin list "$CACHE_NAME" | grep "^${PACKAGE_NAME}-" || true
echo ">>> Done."
