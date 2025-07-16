#!/bin/bash

# Install Hyperledger Fabric binaries with compatible versions
# This script downloads and installs the correct versions of Fabric tools

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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[FABRIC]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root is not recommended"
fi

print_header "Installing Hyperledger Fabric binaries..."

# Set versions - these are tested and compatible versions
FABRIC_VERSION="2.5.4"
FABRIC_CA_VERSION="1.5.5"

print_status "Fabric version: ${FABRIC_VERSION}"
print_status "Fabric CA version: ${FABRIC_CA_VERSION}"

# Check if curl is available
if ! command -v curl &> /dev/null; then
    print_error "curl is required but not installed"
    exit 1
fi

# Download and install Fabric binaries
print_status "Downloading Hyperledger Fabric binaries..."

# Use the official bootstrap script with specific versions
curl -sSL https://bit.ly/2ysbOFE | bash -s -- ${FABRIC_VERSION} ${FABRIC_CA_VERSION}

if [ $? -eq 0 ]; then
    print_status "✅ Fabric binaries installed successfully"
    
    # Set environment variables
    export PATH=${PWD}/bin:$PATH
    export FABRIC_CFG_PATH=${PWD}
    
    print_status "Environment variables set:"
    print_status "  PATH includes: ${PWD}/bin"
    print_status "  FABRIC_CFG_PATH: ${PWD}"
    
    # Verify installation
    print_status "Verifying installation..."
    
    if [ -f "bin/peer" ]; then
        PEER_VERSION=$(./bin/peer version | grep Version | cut -d' ' -f2)
        print_status "✅ Peer version: ${PEER_VERSION}"
    else
        print_error "❌ Peer binary not found"
    fi
    
    if [ -f "bin/orderer" ]; then
        ORDERER_VERSION=$(./bin/orderer version | grep Version | cut -d' ' -f2)
        print_status "✅ Orderer version: ${ORDERER_VERSION}"
    else
        print_error "❌ Orderer binary not found"
    fi
    
    if [ -f "bin/fabric-ca-client" ]; then
        CA_VERSION=$(./bin/fabric-ca-client version | grep Version | cut -d' ' -f2)
        print_status "✅ Fabric CA Client version: ${CA_VERSION}"
    else
        print_error "❌ Fabric CA Client binary not found"
    fi
    
    if [ -f "bin/configtxgen" ]; then
        print_status "✅ ConfigTxGen binary found"
    else
        print_error "❌ ConfigTxGen binary not found"
    fi
    
    echo ""
    print_header "🎉 Installation completed successfully!"
    echo ""
    print_status "Next steps:"
    print_status "1. Add to your shell profile:"
    print_status "   echo 'export PATH=\${PWD}/bin:\$PATH' >> ~/.bashrc"
    print_status "   echo 'export FABRIC_CFG_PATH=\${PWD}' >> ~/.bashrc"
    print_status "2. Or run in current session:"
    print_status "   export PATH=\${PWD}/bin:\$PATH"
    print_status "   export FABRIC_CFG_PATH=\${PWD}"
    print_status "3. Start the network:"
    print_status "   ./deploy.sh"
    
else
    print_error "❌ Failed to install Fabric binaries"
    print_error "Please check your internet connection and try again"
    exit 1
fi