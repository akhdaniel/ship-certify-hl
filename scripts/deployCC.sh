#!/bin/bash

CHANNEL_NAME="$1"
CHAINCODE_NAME="$2" 
CHAINCODE_PATH="$3"
CHAINCODE_VERSION="$4"
CHAINCODE_LANGUAGE="$5"

echo "Deploying chaincode ${CHAINCODE_NAME} on channel ${CHANNEL_NAME}"

# Set path and move to main directory
cd ..
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

# Package chaincode
echo "Packaging chaincode..."
peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz \
    --path ${CHAINCODE_PATH} \
    --lang ${CHAINCODE_LANGUAGE} \
    --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION}

if [ $? -ne 0 ]; then
    echo "Failed to package chaincode"
    exit 1
fi

echo "✅ Chaincode packaged successfully"

# Install chaincode on Authority peer
echo "Installing chaincode on Authority peer..."
setGlobalsForPeer0Authority
peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz

if [ $? -ne 0 ]; then
    echo "Failed to install chaincode on Authority peer"
    exit 1
fi

# Install chaincode on ShipOwner peer
echo "Installing chaincode on ShipOwner peer..."
setGlobalsForPeer0ShipOwner
peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz

if [ $? -ne 0 ]; then
    echo "Failed to install chaincode on ShipOwner peer"
    exit 1
fi

echo "✅ Chaincode installed on both peers"

# Query package ID
echo "Querying chaincode package ID..."
setGlobalsForPeer0Authority
peer lifecycle chaincode queryinstalled >&log.txt
PACKAGE_ID=$(sed -n "/${CHAINCODE_NAME}_${CHAINCODE_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
echo "Package ID: $PACKAGE_ID"

# Approve chaincode for Authority
echo "Approving chaincode for Authority..."
setGlobalsForPeer0Authority
peer lifecycle chaincode approveformyorg -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.bki.com \
    --tls --cafile "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/ca.crt" \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version ${CHAINCODE_VERSION} \
    --package-id ${PACKAGE_ID} \
    --sequence 1

if [ $? -ne 0 ]; then
    echo "Failed to approve chaincode for Authority"
    exit 1
fi

# Approve chaincode for ShipOwner
echo "Approving chaincode for ShipOwner..."
setGlobalsForPeer0ShipOwner
peer lifecycle chaincode approveformyorg -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.bki.com \
    --tls --cafile "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/ca.crt" \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version ${CHAINCODE_VERSION} \
    --package-id ${PACKAGE_ID} \
    --sequence 1

if [ $? -ne 0 ]; then
    echo "Failed to approve chaincode for ShipOwner"
    exit 1
fi

echo "✅ Chaincode approved by both organizations"

# Check commit readiness
echo "Checking commit readiness..."
setGlobalsForPeer0Authority
peer lifecycle chaincode checkcommitreadiness \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version ${CHAINCODE_VERSION} \
    --sequence 1 \
    --output json

# Commit chaincode
echo "Committing chaincode..."
setGlobalsForPeer0Authority
peer lifecycle chaincode commit -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.bki.com \
    --tls --cafile "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/ca.crt" \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/ca.crt" \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/tls/ca.crt" \
    --version ${CHAINCODE_VERSION} \
    --sequence 1

if [ $? -ne 0 ]; then
    echo "Failed to commit chaincode"
    exit 1
fi

echo "✅ Chaincode committed successfully"

# Query committed chaincodes
echo "Querying committed chaincodes..."
peer lifecycle chaincode querycommitted --channelID ${CHANNEL_NAME}

echo "🎉 Chaincode deployment completed successfully!"
