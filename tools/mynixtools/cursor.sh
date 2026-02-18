#!/bin/bash
set -euo pipefail

nix profile add nixpkgs#code-cursor --impure
