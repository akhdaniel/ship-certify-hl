# Production Server Troubleshooting Guide

## Issue: Chaincode Discovery Error
The error `DiscoveryService: shipCertify error: failed constructing descriptor for chaincodes` indicates that the chaincode is not properly deployed or accessible.

## Step-by-Step Troubleshooting

### 1. Check Network Status
```bash
cd /root/ship-certify-hl
./test-network.sh
```

### 2. If Network Issues Found, Restart Network
```bash
# Stop network
./network.sh down

# Start network
./network.sh up

# Create channel
./network.sh createChannel

# Deploy chaincode
./network.sh deployCC
```

### 3. Check Chaincode Deployment
```bash
# Set environment variables
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}

# Set peer environment
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="AuthorityMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/authority.bki.com/users/Admin@authority.bki.com/msp
export CORE_PEER_ADDRESS=localhost:7051

# Check chaincode status
peer lifecycle chaincode querycommitted --channelID bkichannel --name shipCertify
```

### 4. Test Chaincode Query
```bash
# Test a simple query
peer chaincode query -C bkichannel -n shipCertify -c '{"function":"queryAllVessels","Args":[]}'
```

### 5. Check API Server Configuration
```bash
cd /root/ship-certify-hl/api-server

# Check if wallet exists
ls -la wallet/

# If wallet doesn't exist, restart API server to recreate it
cd ..
pkill -f "node.*server.js"
cd api-server
npm start
```

### 6. Verify Connection Profile Paths
Make sure the connection profile has correct paths for your production server:
- All paths should start with `/root/ship-certify-hl/`
- Check `api-server/connection-tls.json`

### 7. Check Docker Containers
```bash
# Check if all containers are running
docker ps

# Check container logs for errors
docker logs peer0.authority.bki.com
docker logs peer0.shipowner.bki.com
docker logs orderer.bki.com
```

### 8. Restart API Server
```bash
cd /root/ship-certify-hl/api-server
pkill -f "node.*server.js"
npm start
```

### 9. Test API Endpoint
```bash
# Test health endpoint
curl http://localhost:3000/health

# Test chaincode query via API
curl http://localhost:3000/api/vessels
```

## Common Issues and Solutions

### Issue 1: Chaincode not deployed
**Solution**: Run `./network.sh deployCC`

### Issue 2: Channel not created
**Solution**: Run `./network.sh createChannel`

### Issue 3: Network not running
**Solution**: Run `./network.sh up`

### Issue 4: Wallet not initialized
**Solution**: Restart API server - it will auto-create wallet

### Issue 5: Certificate path issues
**Solution**: Verify all paths in `connection-tls.json` point to `/root/ship-certify-hl/`

## Quick Fix Script
If you want to quickly reset everything:

```bash
cd /root/ship-certify-hl

# Stop everything
./network.sh down
pkill -f "node.*server.js"

# Clean up
rm -rf api-server/wallet
rm -rf channel-artifacts

# Restart everything
./network.sh up
./network.sh createChannel
./network.sh deployCC

# Start API server
cd api-server
npm start
```

## Verification Commands
After fixing, verify with:

```bash
# 1. Check network
./test-network.sh

# 2. Check API
curl http://localhost:3000/health

# 3. Test chaincode via API
curl http://localhost:3000/api/vessels

# 4. Test frontend
# Open browser to your frontend URL
``` 