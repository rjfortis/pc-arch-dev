#!/bin/bash
set -euo pipefail

# Install direnv if missing

if ! command -v direnv &> /dev/null; then
  curl -sfL https://direnv.net/install.sh | bash
  echo "direnv installed"
fi
