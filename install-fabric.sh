#!/bin/bash

# A more robust script to install Hyperledger Fabric binaries

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[FABRIC]${NC} $1"
}

# --- Configuration ---
FABRIC_VERSION="2.5.4"
FABRIC_CA_VERSION="1.5.5"
TARGET_DIR="bin"

# --- Logic ---
print_header "Installing Hyperledger Fabric binaries..."
print_status "Fabric version: ${FABRIC_VERSION}"
print_status "Fabric CA version: ${FABRIC_CA_VERSION}"

# 1. Detect OS and Architecture
OS_ARCH=$(uname -m)
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')

if [ "$OS_ARCH" = "x86_64" ]; then
    ARCH="amd64"
elif [ "$OS_ARCH" = "aarch64" ]; then
    ARCH="arm64"
else
    print_error "Unsupported architecture: ${OS_ARCH}. Only x86_64 and aarch64 are supported."
    exit 1
fi

print_status "Detected Platform: ${PLATFORM}"
print_status "Detected Architecture: ${ARCH}"

# 2. Construct Download URL
DOWNLOAD_URL="https://github.com/hyperledger/fabric/releases/download/v${FABRIC_VERSION}/hyperledger-fabric-${PLATFORM}-${ARCH}-${FABRIC_VERSION}.tar.gz"
CA_DOWNLOAD_URL="https://github.com/hyperledger/fabric-ca/releases/download/v${FABRIC_CA_VERSION}/hyperledger-fabric-ca-${PLATFORM}-${ARCH}-${FABRIC_CA_VERSION}.tar.gz"

print_status "Fabric Download URL: ${DOWNLOAD_URL}"
print_status "Fabric CA Download URL: ${CA_DOWNLOAD_URL}"

# 3. Download and Extract
TEMP_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEMP_DIR"' EXIT

# Download and extract Fabric binaries
print_status "Downloading Fabric binaries..."
curl -L --silent "${DOWNLOAD_URL}" | tar xz -C "${TEMP_DIR}"

# Download and extract Fabric CA binaries
print_status "Downloading Fabric CA binaries..."
curl -L --silent "${CA_DOWNLOAD_URL}" | tar xz -C "${TEMP_DIR}"

# 4. Move binaries to the target directory
mkdir -p "${TARGET_DIR}"
mv "${TEMP_DIR}/bin"/* "${TARGET_DIR}/"
print_status "Binaries moved to ${PWD}/${TARGET_DIR}"

# 5. Verify Installation
print_status "Verifying installation..."
ERRORS=0
for bin in peer orderer configtxgen fabric-ca-client; do
    if [ -f "${TARGET_DIR}/${bin}" ]; then
        print_status "✅ ${bin} found."
    else
        print_error "❌ ${bin} not found."
        ((ERRORS++))
    fi
done

if [ $ERRORS -ne 0 ]; then
    print_error "Installation failed. Please check the logs."
    exit 1
fi

# 6. Set Environment Variables
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}

print_status "Environment variables set for this session:"
print_status "  PATH includes: ${PWD}/bin"
print_status "  FABRIC_CFG_PATH: ${PWD}"

echo ""
print_header "🎉 Installation completed successfully!"
echo ""
print_status "Next steps:"
print_status "1. Add to your shell profile (e.g., ~/.bashrc or ~/.zshrc):"
print_status "   echo 'export PATH=\${HOME}/ship-certify-hl/bin:\$PATH' >> ~/.bashrc"
print_status "   echo 'export FABRIC_CFG_PATH=\${HOME}/ship-certify-hl' >> ~/.bashrc"
print_status "   (Replace ship-certify-hl with your project directory if different)"
print_status "2. Source your profile or restart your shell."
print_status "3. Start the network: ./network.sh up"
