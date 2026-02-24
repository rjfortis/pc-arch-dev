#!/bin/bash
set -euo pipefail

nix profile add nixpkgs#obsidian --impure
