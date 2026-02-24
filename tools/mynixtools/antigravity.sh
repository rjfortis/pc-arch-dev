#!/bin/bash
set -euo pipefail

nix profile add nixpkgs#antigravity --impure
