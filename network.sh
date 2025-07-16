#!/bin/bash

export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

function createAuthority {
    echo "Enrolling the CA admin"
    mkdir -p organizations/peerOrganizations/authority.bki.com/

    export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/authority.bki.com/

    set -x
    fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-authority --tls.certfiles "${PWD}/organizations/fabric-ca/authority/tls-cert.pem"
    { set +x; } 2>/dev/null

    echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-authority.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-authority.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-authority.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-authority.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/authority.bki.com/msp/config.yaml"

    echo "Registering peer0"
    set -x
    fabric-ca-client register --caname ca-authority --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/authority/tls-cert.pem"
    { set +x; } 2>/dev/null

    echo "Registering user"
    set -x
    fabric-ca-client register --caname ca-authority --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/authority/tls-cert.pem"
    { set +x; } 2>/dev/null

    echo "Registering the org admin"
    set -x
    fabric-ca-client register --caname ca-authority --id.name authorityadmin --id.secret authorityadminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/authority/tls-cert.pem"
    { set +x; } 2>/dev/null

    echo "Generating the peer0 msp"
    set -x
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-authority -M "${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/msp" --csr.hosts peer0.authority.bki.com --tls.certfiles "${PWD}/organizations/fabric-ca/authority/tls-cert.pem"
    { set +x; } 2>/dev/null

    cp "${PWD}/organizations/peerOrganizations/authority.bki.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/msp/config.yaml"

    echo "Generating the peer0-tls certificates"
    set -x
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-authority -M "${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls" --enrollment.profile tls --csr.hosts peer0.authority.bki.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/authority/tls-cert.pem"
    { set +x; } 2>/dev/null

    cp "${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/ca.crt"
    cp "${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/server.crt"
    cp "${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/server.key"

    mkdir -p "${PWD}/organizations/peerOrganizations/authority.bki.com/msp/tlscacerts"
    cp "${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/authority.bki.com/msp/tlscacerts/ca.crt"

    mkdir -p "${PWD}/organizations/peerOrganizations/authority.bki.com/tlsca"
    cp "${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/authority.bki.com/tlsca/tlsca.authority.bki.com-cert.pem"

    mkdir -p "${PWD}/organizations/peerOrganizations/authority.bki.com/ca"
    cp "${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/msp/cacerts/"* "${PWD}/organizations/peerOrganizations/authority.bki.com/ca/ca.authority.bki.com-cert.pem"

    echo "Generating the user msp"
    set -x
    fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca-authority -M "${PWD}/organizations/peerOrganizations/authority.bki.com/users/User1@authority.bki.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/authority/tls-cert.pem"
    { set +x; } 2>/dev/null

    cp "${PWD}/organizations/peerOrganizations/authority.bki.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/authority.bki.com/users/User1@authority.bki.com/msp/config.yaml"

    echo "Generating the org admin msp"
    set -x
    fabric-ca-client enroll -u https://authorityadmin:authorityadminpw@localhost:7054 --caname ca-authority -M "${PWD}/organizations/peerOrganizations/authority.bki.com/users/Admin@authority.bki.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/authority/tls-cert.pem"
    { set +x; } 2>/dev/null

    cp "${PWD}/organizations/peerOrganizations/authority.bki.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/authority.bki.com/users/Admin@authority.bki.com/msp/config.yaml"
}

function createShipOwner {
    echo "Enrolling the CA admin"
    mkdir -p organizations/peerOrganizations/shipowner.bki.com/

    export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/shipowner.bki.com/

    set -x
    fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-shipowner --tls.certfiles "${PWD}/organizations/fabric-ca/shipowner/tls-cert.pem"
    { set +x; } 2>/dev/null

    echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-shipowner.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-shipowner.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-shipowner.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-shipowner.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/shipowner.bki.com/msp/config.yaml"

    echo "Registering peer0"
    set -x
    fabric-ca-client register --caname ca-shipowner --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/shipowner/tls-cert.pem"
    { set +x; } 2>/dev/null

    echo "Registering user"
    set -x
    fabric-ca-client register --caname ca-shipowner --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/shipowner/tls-cert.pem"
    { set +x; } 2>/dev/null

    echo "Registering the org admin"
    set -x
    fabric-ca-client register --caname ca-shipowner --id.name shipowneradmin --id.secret shipowneradminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/shipowner/tls-cert.pem"
    { set +x; } 2>/dev/null

    echo "Generating the peer0 msp"
    set -x
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-shipowner -M "${PWD}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/msp" --csr.hosts peer0.shipowner.bki.com --tls.certfiles "${PWD}/organizations/fabric-ca/shipowner/tls-cert.pem"
    { set +x; } 2>/dev/null

    cp "${PWD}/organizations/peerOrganizations/shipowner.bki.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/msp/config.yaml"

    echo "Generating the peer0-tls certificates"
    set -x
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-shipowner -M "${PWD}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/tls" --enrollment.profile tls --csr.hosts peer0.shipowner.bki.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/shipowner/tls-cert.pem"
    { set +x; } 2>/dev/null

    cp "${PWD}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/tls/ca.crt"
    cp "${PWD}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/tls/server.crt"
    cp "${PWD}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/tls/server.key"

    mkdir -p "${PWD}/organizations/peerOrganizations/shipowner.bki.com/msp/tlscacerts"
    cp "${PWD}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/shipowner.bki.com/msp/tlscacerts/ca.crt"

    mkdir -p "${PWD}/organizations/peerOrganizations/shipowner.bki.com/tlsca"
    cp "${PWD}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/shipowner.bki.com/tlsca/tlsca.shipowner.bki.com-cert.pem"

    mkdir -p "${PWD}/organizations/peerOrganizations/shipowner.bki.com/ca"
    cp "${PWD}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/msp/cacerts/"* "${PWD}/organizations/peerOrganizations/shipowner.bki.com/ca/ca.shipowner.bki.com-cert.pem"

    echo "Generating the user msp"
    set -x
    fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca-shipowner -M "${PWD}/organizations/peerOrganizations/shipowner.bki.com/users/User1@shipowner.bki.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/shipowner/tls-cert.pem"
    { set +x; } 2>/dev/null

    cp "${PWD}/organizations/peerOrganizations/shipowner.bki.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/shipowner.bki.com/users/User1@shipowner.bki.com/msp/config.yaml"

    echo "Generating the org admin msp"
    set -x
    fabric-ca-client enroll -u https://shipowneradmin:shipowneradminpw@localhost:8054 --caname ca-shipowner -M "${PWD}/organizations/peerOrganizations/shipowner.bki.com/users/Admin@shipowner.bki.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/shipowner/tls-cert.pem"
    { set +x; } 2>/dev/null

    cp "${PWD}/organizations/peerOrganizations/shipowner.bki.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/shipowner.bki.com/users/Admin@shipowner.bki.com/msp/config.yaml"
}

function createOrderer {
    echo "Enrolling the CA admin"
    mkdir -p organizations/ordererOrganizations/bki.com

    export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/bki.com

    set -x
    fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
    { set +x; } 2>/dev/null

    echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/ordererOrganizations/bki.com/msp/config.yaml"

    echo "Registering orderer"
    set -x
    fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
    { set +x; } 2>/dev/null

    echo "Registering the orderer admin"
    set -x
    fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
    { set +x; } 2>/dev/null

    echo "Generating the orderer msp"
    set -x
    fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/msp" --csr.hosts orderer.bki.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
    { set +x; } 2>/dev/null

    cp "${PWD}/organizations/ordererOrganizations/bki.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/msp/config.yaml"

    echo "Generating the orderer-tls certificates"
    set -x
    fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls" --enrollment.profile tls --csr.hosts orderer.bki.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
    { set +x; } 2>/dev/null

    cp "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/ca.crt"
    cp "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/signcerts/"* "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/server.crt"
    cp "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/keystore/"* "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/server.key"

    mkdir -p "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/msp/tlscacerts"
    cp "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/msp/tlscacerts/tlsca.bki.com-cert.pem"

    mkdir -p "${PWD}/organizations/ordererOrganizations/bki.com/msp/tlscacerts"
    cp "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/bki.com/msp/tlscacerts/tlsca.bki.com-cert.pem"

    echo "Generating the admin msp"
    set -x
    fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/bki.com/users/Admin@bki.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
    { set +x; } 2>/dev/null

    cp "${PWD}/organizations/ordererOrganizations/bki.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/bki.com/users/Admin@bki.com/msp/config.yaml"
}

function networkUp() {
    checkPrereqs
    if [ ! -d "organizations/peerOrganizations" ]; then
        createOrgs
    fi
    COMPOSE_FILES="-f docker-compose.yaml"
    IMAGE_TAG=${IMAGETAG} docker-compose ${COMPOSE_FILES} up -d 2>&1
    docker ps -a
    if [ $? -ne 0 ]; then
        fatalln "Unable to start network"
    fi
}

function createChannel() {
    export FABRIC_CFG_PATH=$PWD/../config/
    configtxgen -profile BKIChannel -outputCreateChannelTx ./channel-artifacts/bkichannel.tx -channelID bkichannel
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID="AuthorityMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/authority.bki.com/users/Admin@authority.bki.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
    peer channel create -o localhost:7050 -c bkichannel --ordererTLSHostnameOverride orderer.bki.com -f ./channel-artifacts/bkichannel.tx --outputBlock ./channel-artifacts/bkichannel.block --tls --cafile "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/msp/tlscacerts/tlsca.bki.com-cert.pem"
}

function deployCC() {
    ./scripts/deployCC.sh bkichannel shipCertify ../chaincode-javascript 1 javascript
}

MODE=$1
shift

if [ "${MODE}" == "up" ]; then
    networkUp
elif [ "${MODE}" == "createChannel" ]; then
    createChannel
elif [ "${MODE}" == "deployCC" ]; then
    deployCC
elif [ "${MODE}" == "down" ]; then
    networkDown
else
    printHelp
    exit 1
fi