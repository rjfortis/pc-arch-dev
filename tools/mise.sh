#!/bin/bash
set -euo pipefail

# Install mise if missing
if ! command -v mise >/dev/null 2>&1; then
  echo "Installing mise..."
  curl -fsSL https://mise.jdx.dev/install.sh | sh
fi
