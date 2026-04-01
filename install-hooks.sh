#!/usr/bin/env bash
# Install tracked git hooks into .git/hooks/.
# Run once after cloning: bash install-hooks.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

for hook in "$REPO_ROOT/hooks/"*; do
    name="$(basename "$hook")"
    dest="$REPO_ROOT/.git/hooks/$name"
    cp "$hook" "$dest"
    chmod +x "$dest" 2>/dev/null || true
    echo "Installed: .git/hooks/$name"
done

echo "Done."
