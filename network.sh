#!/bin/bash

# BKI Ship Certification Network Management Script
# Usage: ./network.sh [up|down|createChannel|deployCC|clean]

export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}

# Set default values
CHANNEL_NAME="bkichannel"
CHAINCODE_NAME="shipCertify"
CHAINCODE_PATH="./chaincode-javascript"
CHAINCODE_VERSION="1"
CHAINCODE_SEQUENCE="3"
CHAINCODE_LANGUAGE="node"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
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
    echo -e "${BLUE}[NETWORK]${NC} $1"
}

# Error handling
fatalln() {
    print_error "$1"
    exit 1
}

# Check prerequisites
checkPrereqs() {
    print_status "Checking prerequisites..."
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        fatalln "Docker is not running or not accessible"
    fi
    
    # Check if binaries exist
    if [ ! -f "bin/peer" ]; then
        fatalln "Fabric binaries not found. Run './install-fabric.sh' first"
    fi
    
    print_status "Prerequisites check passed ✅"
}

# Print help
printHelp() {
    echo "Usage: "
    echo "  network.sh <Mode> [Flags]"
    echo "    Modes:"
    echo "      generateCerts - Generate crypto materials for organizations"
    echo "      up - Bring up the network with docker compose up"
    echo "      down - Clear the network with docker compose down"
    echo "      createChannel - Create and join a sample channel"
    echo "      deployCC - Deploy the chaincode"
    echo "      clean - Clean up all containers and volumes"
    echo ""
    echo "    Flags:"
    echo "    -ca <use CAs> -  Create Organization crypto material using CAs"
    echo "    -c <channel name> - Channel name to use (defaults to \"bkichannel\")"
    echo "    -s <dbtype> - Peer state database to deploy: goleveldb (default) or couchdb"
    echo "    -r <max retry> - CLI times out after this amount of time (defaults to 5)"
    echo "    -d <delay> - delay duration before retry (defaults to 3)"
    echo "    -l <language> - the programming language of the chaincode to deploy: javascript (default), typescript, go, java"
    echo "    -v <version>  - chaincode version. 1.0 (default), v2, version3.x, etc"
    echo "    -i <imagetag> - the tag to be used to launch the network (defaults to \"latest\")"
    echo "    -verbose - verbose mode"
    echo "  network.sh -h (print this message)"
    echo ""
    echo "Examples:"
    echo "  network.sh generateCerts"
    echo "  network.sh up"
    echo "  network.sh up -ca"
    echo "  network.sh up -c mychannel -s couchdb"
    echo "  network.sh createChannel"
    echo "  network.sh deployCC -l javascript"
    echo "  network.sh down"
}

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

# Network management functions
function networkUp() {
    print_header "Starting BKI Ship Certification Network..."
    checkPrereqs
    
    # Create crypto materials if they don't exist
    if [ ! -d "organizations/peerOrganizations" ]; then
        print_warning "Crypto materials not found, creating them..."
        createOrgs
    fi
    
    # Start the network
    COMPOSE_FILES="-f docker-compose.yaml"
    print_status "Starting containers..."
    IMAGE_TAG=${IMAGETAG} docker compose ${COMPOSE_FILES} up -d 2>&1
    
    if [ $? -ne 0 ]; then
        fatalln "Unable to start network"
    fi
    
    print_status "Waiting for containers to be ready..."
    sleep 10
    
    # Show running containers
    print_status "Network containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    print_status "✅ Network started successfully!"
}

function networkDown() {
    print_header "Stopping BKI Ship Certification Network..."
    
    docker compose down --volumes --remove-orphans
    
    if [ $? -eq 0 ]; then
        print_status "✅ Network stopped successfully!"
    else
        print_error "Failed to stop network"
    fi
}

function generateCerts() {
    print_header "Generating crypto materials for BKI Ship Certification Network..."
    
    # Check if cryptogen binary exists
    if [ ! -f "bin/cryptogen" ]; then
        fatalln "cryptogen binary not found. Please install Fabric binaries first: ./install-fabric.sh"
    fi
    
    # Clean existing crypto materials
    if [ -d "organizations" ]; then
        print_warning "Removing existing crypto materials..."
        rm -rf organizations
    fi
    
    # Generate crypto materials using cryptogen
    print_status "Generating crypto materials using cryptogen..."
    ./bin/cryptogen generate --config=./crypto-config.yaml --output="organizations"
    
    if [ $? -ne 0 ]; then
        fatalln "Failed to generate crypto materials"
    fi
    
    # Create additional required directories
    mkdir -p organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com
    mkdir -p organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com
    mkdir -p organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com
    
    # Generate connection profiles
    generateConnectionProfiles
    
    print_status "✅ Crypto materials generated successfully!"
    print_status "Generated organizations:"
    print_status "  - OrdererOrg (bki.com)"
    print_status "  - AuthorityMSP (authority.bki.com)"
    print_status "  - ShipOwnerMSP (shipowner.bki.com)"
}

function generateConnectionProfiles() {
    print_status "Generating connection profiles..."
    
    # Authority connection profile
    cat > organizations/peerOrganizations/authority.bki.com/connection-authority.json << EOF
{
    "name": "bki-network-authority",
    "version": "1.0.0",
    "client": {
        "organization": "AuthorityMSP",
        "connection": {
            "timeout": {
                "peer": {
                    "endorser": "300"
                }
            }
        }
    },
    "organizations": {
        "AuthorityMSP": {
            "mspid": "AuthorityMSP",
            "peers": [
                "peer0.authority.bki.com"
            ],
            "certificateAuthorities": [
                "ca.authority.bki.com"
            ]
        }
    },
    "peers": {
        "peer0.authority.bki.com": {
            "url": "grpcs://localhost:7051",
            "tlsCACerts": {
                "path": "organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/ca.crt"
            },
            "grpcOptions": {
                "ssl-target-name-override": "peer0.authority.bki.com",
                "hostnameOverride": "peer0.authority.bki.com"
            }
        }
    },
    "certificateAuthorities": {
        "ca.authority.bki.com": {
            "url": "https://localhost:7054",
            "caName": "ca-authority",
            "tlsCACerts": {
                "path": "organizations/fabric-ca/authority/tls-cert.pem"
            },
            "httpOptions": {
                "verify": false
            }
        }
    }
}
EOF

    # ShipOwner connection profile
    cat > organizations/peerOrganizations/shipowner.bki.com/connection-shipowner.json << EOF
{
    "name": "bki-network-shipowner",
    "version": "1.0.0",
    "client": {
        "organization": "ShipOwnerMSP",
        "connection": {
            "timeout": {
                "peer": {
                    "endorser": "300"
                }
            }
        }
    },
    "organizations": {
        "ShipOwnerMSP": {
            "mspid": "ShipOwnerMSP",
            "peers": [
                "peer0.shipowner.bki.com"
            ],
            "certificateAuthorities": [
                "ca.shipowner.bki.com"
            ]
        }
    },
    "peers": {
        "peer0.shipowner.bki.com": {
            "url": "grpcs://localhost:9051",
            "tlsCACerts": {
                "path": "organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/tls/ca.crt"
            },
            "grpcOptions": {
                "ssl-target-name-override": "peer0.shipowner.bki.com",
                "hostnameOverride": "peer0.shipowner.bki.com"
            }
        }
    },
    "certificateAuthorities": {
        "ca.shipowner.bki.com": {
            "url": "https://localhost:8054",
            "caName": "ca-shipowner",
            "tlsCACerts": {
                "path": "organizations/fabric-ca/shipowner/tls-cert.pem"
            },
            "httpOptions": {
                "verify": false
            }
        }
    }
}
EOF

    print_status "✅ Connection profiles generated"
}

function createOrgs() {
    print_header "Creating organizations and crypto materials..."
    
    # Check if crypto materials already exist
    if [ -d "organizations/peerOrganizations" ]; then
        print_status "Crypto materials already exist, skipping generation"
        return
    fi
    
    # Generate crypto materials
    generateCerts
}

function cleanUp() {
    print_header "Cleaning up all containers and volumes..."
    
    # Stop and remove containers
    docker compose down --volumes --remove-orphans
    
    # Remove generated materials
    rm -rf organizations/peerOrganizations
    rm -rf organizations/ordererOrganizations
    rm -rf channel-artifacts
    rm -rf wallet
    
    # Prune docker system
    docker system prune -f
    docker volume prune -f
    
    print_status "✅ Cleanup completed!"
}

function createChannel() {
    print_header "Creating channel: ${CHANNEL_NAME}"
    
    # Create channel artifacts directory
    mkdir -p channel-artifacts
    
    # Generate channel genesis block using the new profile that includes orderer
    export FABRIC_CFG_PATH=${PWD}
    print_status "Generating channel genesis block..."
    configtxgen -profile BKIChannelGenesis -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID ${CHANNEL_NAME}
    
    if [ $? -ne 0 ]; then
        fatalln "Failed to generate channel genesis block"
    fi
    
    # Use osnadmin to join channel to orderer (Fabric 2.3+ channel participation API)
    print_status "Adding channel to orderer using channel participation API..."
    osnadmin channel join \
        --channelID ${CHANNEL_NAME} \
        --config-block ./channel-artifacts/${CHANNEL_NAME}.block \
        -o localhost:7053 \
        --ca-file "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/ca.crt" \
        --client-cert "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/server.crt" \
        --client-key "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/server.key"
    
    if [ $? -eq 0 ]; then
        print_status "✅ Channel created successfully using channel participation API!"
        
        # Join peers to channel
        joinChannel
    else
        fatalln "Failed to create channel using channel participation API"
    fi
}

function joinChannel() {
    print_status "Joining peers to channel..."
    
    # Join Authority peer
    setGlobalsForPeer0Authority
    peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block
    
    # Join ShipOwner peer
    setGlobalsForPeer0ShipOwner
    peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block
    
    print_status "✅ All peers joined channel!"
}

function setGlobalsForPeer0Authority() {
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID="AuthorityMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/authority.bki.com/users/Admin@authority.bki.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

function setGlobalsForPeer0ShipOwner() {
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID="ShipOwnerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/shipowner.bki.com/users/Admin@shipowner.bki.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
}

function setGlobalsForOrderer() {
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID="OrdererMSP"
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/ordererOrganizations/bki.com/users/Admin@bki.com/msp
}

function deployCC() {
    print_header "Deploying chaincode: ${CHAINCODE_NAME}"
    
    # Create deployCC script if it doesn't exist
    if [ ! -f "scripts/deployCC.sh" ]; then
        createDeployCCScript
    fi
    
    # Deploy chaincode
    ./scripts/deployCC.sh ${CHANNEL_NAME} ${CHAINCODE_NAME} ${CHAINCODE_PATH} ${CHAINCODE_VERSION} ${CHAINCODE_LANGUAGE} ${CHAINCODE_SEQUENCE}
}

function createDeployCCScript() {
    print_status "Creating deployCC script..."
    mkdir -p scripts
    
    cat > scripts/deployCC.sh << 'EOF'
#!/bin/bash

CHANNEL_NAME="$1"
CHAINCODE_NAME="$2" 
CHAINCODE_PATH="$3"
CHAINCODE_VERSION="$4"
CHAINCODE_LANGUAGE="$5"

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
EOF
    
    chmod +x scripts/deployCC.sh
}

# Check for help first
if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ]; then
    printHelp
    exit 0
fi

# Main execution logic
MODE=$1
shift

# Parse command line arguments
while [[ $# -ge 1 ]] ; do
    key="$1"
    case $key in
        -c )
            CHANNEL_NAME="$2"
            shift
            ;;
        -l )
            CHAINCODE_LANGUAGE="$2"
            shift
            ;;
        -v )
            CHAINCODE_VERSION="$2"
            shift
            ;;
        * )
            print_error "Unknown flag: $key"
            printHelp
            exit 1
            ;;
    esac
    shift
done

# Execute based on mode
case $MODE in
    "generateCerts")
        generateCerts
        ;;
    "up")
        networkUp
        ;;
    "down")
        networkDown
        ;;
    "createChannel")
        createChannel
        ;;
    "deployCC")
        deployCC
        ;;
    "clean")
        cleanUp
        ;;
    *)
        print_error "Unknown mode: $MODE"
        printHelp
        exit 1
        ;;
esac