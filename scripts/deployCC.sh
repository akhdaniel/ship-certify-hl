#!/bin/bash

CHANNEL_NAME="$1"
CHAINCODE_NAME="$2" 
CHAINCODE_PATH="$3"
CHAINCODE_VERSION="$4"
CHAINCODE_LANGUAGE="$5"
CHAINCODE_SEQUENCE="$6"

echo "Deploying chaincode ${CHAINCODE_NAME} on channel ${CHANNEL_NAME}"

# Set path
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
    --label ${CHAINCODE_NAME}-${CHAINCODE_VERSION}

if [ $? -ne 0 ]; then
    echo "Failed to package chaincode"
    exit 1
fi

echo "✅ Chaincode packaged successfully"

# Install chaincode on Authority peer
echo "Installing chaincode on Authority peer..."
setGlobalsForPeer0Authority
peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz || true

# Install chaincode on ShipOwner peer
echo "Installing chaincode on ShipOwner peer..."
setGlobalsForPeer0ShipOwner
peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz || true

echo "✅ Chaincode installed on both peers"

# Query package ID
echo "Querying chaincode package ID..."
setGlobalsForPeer0Authority
PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | grep -o "Package ID: ${CHAINCODE_NAME}-${CHAINCODE_VERSION}:[a-f0-9]*" | cut -d ' ' -f 3)
echo "Package ID: $PACKAGE_ID"

# Approve chaincode for Authority
echo "Approving chaincode for Authority..."
setGlobalsForPeer0Authority
retry_count=0
max_retries=10
until peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.bki.com --tls --cafile "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/ca.crt" --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --package-id ${PACKAGE_ID} --sequence ${CHAINCODE_SEQUENCE} --signature-policy "OR('AuthorityMSP.member', 'ShipOwnerMSP.member')"; do
  retry_count=$((retry_count+1))
  if [ $retry_count -gt $max_retries ]; then
    echo "Failed to approve chaincode for Authority after $max_retries attempts, exiting."
    exit 1
  fi
  echo "Waiting for orderer to be ready... (attempt $retry_count)"
  sleep 5
done

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
    --sequence ${CHAINCODE_SEQUENCE} \
    --signature-policy "OR('AuthorityMSP.member', 'ShipOwnerMSP.member')"

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
    --sequence ${CHAINCODE_SEQUENCE} \
    --output json \
    --signature-policy "OR('AuthorityMSP.member', 'ShipOwnerMSP.member')"

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
    --sequence ${CHAINCODE_SEQUENCE} \
    --signature-policy "OR('AuthorityMSP.member', 'ShipOwnerMSP.member')" \
    --signature-policy "OR('AuthorityMSP.member', 'ShipOwnerMSP.member')"

if [ $? -ne 0 ]; then
    echo "Failed to commit chaincode"
    exit 1
fi

echo "✅ Chaincode committed successfully"

# Query committed chaincodes
echo "Querying committed chaincodes..."
peer lifecycle chaincode querycommitted --channelID ${CHANNEL_NAME}

echo "🎉 Chaincode deployment completed successfully!"
