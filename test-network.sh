#!/bin/bash

echo "🧪 Testing BKI Ship Certification Network..."

# Set environment variables
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}

# Function to set globals for Authority peer
setGlobalsForPeer0Authority() {
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID="AuthorityMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/authority.bki.com/users/Admin@authority.bki.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

echo "1. Checking Docker containers..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(orderer|peer|ca)"

echo ""
echo "2. Checking channel info..."
setGlobalsForPeer0Authority
peer channel getinfo -c bkichannel

echo ""
echo "3. Checking chaincode deployment..."
peer lifecycle chaincode querycommitted --channelID bkichannel --name shipCertify

echo ""
echo "4. Testing chaincode query..."
peer chaincode query -C bkichannel -n shipCertify -c '{"function":"queryAllVessels","Args":[]}'

echo ""
echo "✅ Network test completed!" 