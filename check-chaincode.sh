#!/bin/bash

# Check and redeploy chaincode if needed
echo "🔍 Checking chaincode deployment status..."

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

# Function to set globals for ShipOwner peer
setGlobalsForPeer0ShipOwner() {
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID="ShipOwnerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/shipowner.bki.com/users/Admin@shipowner.bki.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
}

# Check if network is running
echo "📡 Checking if network is running..."
if ! docker ps | grep -q "orderer.bki.com"; then
    echo "❌ Network is not running. Starting network..."
    ./network.sh up
    sleep 10
else
    echo "✅ Network is running"
fi

# Check if channel exists
echo "📋 Checking if channel exists..."
if [ ! -f "channel-artifacts/bkichannel.block" ]; then
    echo "❌ Channel block not found. Creating channel..."
    ./network.sh createChannel
else
    echo "✅ Channel exists"
fi

# Check chaincode deployment
echo "🔗 Checking chaincode deployment..."
setGlobalsForPeer0Authority

# Query committed chaincodes
echo "📊 Querying committed chaincodes..."
peer lifecycle chaincode querycommitted --channelID bkichannel --output json > chaincode_status.json 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Chaincode query successful"
    cat chaincode_status.json
else
    echo "❌ Chaincode query failed. Chaincode may not be deployed."
    echo "🚀 Deploying chaincode..."
    ./network.sh deployCC
fi

# Clean up
rm -f chaincode_status.json

echo "✅ Chaincode check completed!" 