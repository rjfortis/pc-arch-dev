#!/bin/bash
set -euo pipefail

# nix profile add nixpkgs#claude-code --impure
nix profile add nixpkgs#codex
