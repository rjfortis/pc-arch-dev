#!/usr/bin/env bash

# --------------------------------------------------------
# Strict mode (without -e to preserve controlled failures)
# --------------------------------------------------------
set -uo pipefail

# --------------------------------------------------------
# Prevent running as root
# --------------------------------------------------------
if [ "$EUID" -eq 0 ]; then
    echo "Error: Do not run this script as root."
    exit 1
fi

# --------------------------------------------------------
# Resolve paths
# --------------------------------------------------------
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOOLS_FOLDER="$BASE_DIR/tools"

echo "=== Starting Tool Installation from: $TOOLS_FOLDER ==="

# --------------------------------------------------------
# Validate tools directory
# --------------------------------------------------------
if [ ! -d "$TOOLS_FOLDER" ]; then
    echo "❌ Error: Directory $TOOLS_FOLDER not found."
    exit 1
fi

# --------------------------------------------------------
# Execute each tool script
# --------------------------------------------------------
for script in "$TOOLS_FOLDER"/*.sh; do
    # Avoid errors if folder is empty
    [ -e "$script" ] || continue

    script_name="$(basename "$script")"

    echo "--> Executing tool: $script_name"

    # Run script while preserving failure isolation
    if bash "$script"; then
        echo "✅ $script_name finished successfully."
    else
        echo "❌ $script_name failed. Moving to next script..."
    fi

    echo "------------------------------------------"
done

echo "=== All tools in /tools have been processed! ==="
