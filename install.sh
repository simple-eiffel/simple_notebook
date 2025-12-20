#\!/bin/bash
# Eiffel Notebook Linux Installer
# Version 1.0.0-alpha.20

set -e

VERSION="1.0.0-alpha.20"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="eiffel_notebook"

echo "Eiffel Notebook Installer - Linux"
echo "Version: $VERSION"
echo ""

# Check if running as root for system install
if [ "$(id -u)" -ne 0 ]; then
    echo "Note: Running without root. Will install to ~/bin instead."
    INSTALL_DIR="$HOME/bin"
    mkdir -p "$INSTALL_DIR"
fi

# Check for EiffelStudio
echo "Checking for EiffelStudio..."
if command -v ec &> /dev/null; then
    echo "  Found: $(which ec)"
elif [ -n "$ISE_EIFFEL" ] && [ -f "$ISE_EIFFEL/studio/spec/linux-x86-64/bin/ec" ]; then
    echo "  Found via ISE_EIFFEL: $ISE_EIFFEL"
elif [ -f "/usr/bin/ec" ]; then
    echo "  Found: /usr/bin/ec (PPA install)"
else
    echo ""
    echo "ERROR: EiffelStudio not found\!"
    echo ""
    echo "Install EiffelStudio first:"
    echo ""
    echo "  Option 1: Ubuntu PPA (recommended)"
    echo "    sudo add-apt-repository ppa:eiffelstudio-team/ppa"
    echo "    sudo apt update"
    echo "    sudo apt install eiffelstudio"
    echo ""
    echo "  Option 2: Manual install from eiffel.com"
    echo "    Download from: https://www.eiffel.com/eiffelstudio/download/"
    echo "    Extract to /opt/eiffelstudio"
    echo "    Set ISE_EIFFEL=/opt/eiffelstudio"
    echo "    Set ISE_PLATFORM=linux-x86-64"
    echo ""
    exit 1
fi

echo ""
echo "EiffelStudio check passed."
echo "Eiffel Notebook requires building from source for now."
echo ""
echo "Build instructions:"
echo "  git clone https://github.com/simple-eiffel/simple_notebook"
echo "  cd simple_notebook"
echo "  ./build.sh"
echo ""
