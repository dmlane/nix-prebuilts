#!/usr/bin/env bash
# Keep only the last 5 Cachix pins for a given package.
# Usage: ./pin_keep5.sh <cache-name> <package-name> <store-path>
#
# Example:
#   ./pin_keep5.sh dmlane mypkg /nix/store/abcd...-mypkg-1.0

set -euo pipefail

CACHE_NAME="$1"
PACKAGE_NAME="$2"
STORE_PATH="$3"

# Create a unique pin name like mypkg-20250914T1730Z
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
PIN_NAME="${PACKAGE_NAME}-${TIMESTAMP}"

echo ">>> Pinning $STORE_PATH as $PIN_NAME in cache $CACHE_NAME"
cachix pin "$CACHE_NAME" "$PIN_NAME" "$STORE_PATH"

echo ">>> Trimming to keep only the newest 5 pins for $PACKAGE_NAME"
# List all pins for this package, sort by name (timestamps ensure lexicographic order)
ALL_PINS=$(cachix pin list "$CACHE_NAME" | awk -v pkg="$PACKAGE_NAME" '$1 ~ "^"pkg"-" {print $1}' | sort)
# Take the last 5 (newest)
KEEP=$(echo "$ALL_PINS" | tail -n 5)

for pin in $ALL_PINS; do
    if ! echo "$KEEP" | grep -qx "$pin"; then
        echo "Unpinning old pin $pin"
        cachix pin remove "$CACHE_NAME" "$pin"
    fi
done

echo ">>> Done. Current pins for $PACKAGE_NAME:"
cachix pin list "$CACHE_NAME" | grep "^${PACKAGE_NAME}-" || true
