# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### System Location
- **Project Path**: `/root/ship-certify-hl/`
- **Working Directory**: Always run commands from `/root/ship-certify-hl/`

### Network Management
- `cd /root/ship-certify-hl && ./network.sh generateCerts` - Generate crypto materials for organizations
- `cd /root/ship-certify-hl && ./network.sh up` - Start the Hyperledger Fabric network
- `cd /root/ship-certify-hl && ./network.sh down` - Stop the network
- `cd /root/ship-certify-hl && ./network.sh createChannel` - Create and join channel
- `cd /root/ship-certify-hl && ./network.sh deployCC` - Deploy chaincode
- `cd /root/ship-certify-hl && ./network.sh clean` - Full cleanup of containers and volumes

### Application Development
- `cd /root/ship-certify-hl && npm run install:all` - Install dependencies for all components
- `cd /root/ship-certify-hl && npm run start:dev` - Start both API server and frontend in development
- `cd /root/ship-certify-hl && npm run api:start` - Start API server only
- `cd /root/ship-certify-hl && npm run frontend:start` - Start frontend development server
- `cd /root/ship-certify-hl && npm run frontend:build` - Build frontend for production
- `cd /root/ship-certify-hl && npm run deploy` - Deploy full system with Docker

### Ubuntu Server Specific
- Check system status: `systemctl status docker`
- View logs: `docker-compose logs -f api-server`
- Monitor containers: `docker ps -a`
- Check disk space: `df -h` (blockchain data can grow large)

### Testing & Development
- Test API health: `curl http://localhost:3000/health`
- Test from external: `curl http://YOUR_SERVER_IP:3000/health`
- Test chaincode: `docker exec cli peer chaincode invoke -o orderer.bki.com:7050 -C bkichannel -n shipCertify -c '{"function":"queryAllVessels","Args":[]}'`

### Login Credentials
- **Authority User**: username: `authority`, password: `authority123`
- **Ship Owner User**: username: `shipowner`, password: `shipowner123`
- **User storage**: `/root/ship-certify-hl/api-server/users.json`
- **Authentication**: JWT-based with bcrypt password hashing

## System Architecture

### Core Components
1. **Hyperledger Fabric Network**: Blockchain infrastructure with 2 organizations
   - AuthorityMSP (authority.bki.com) - BKI certification authority
   - ShipOwnerMSP (shipowner.bki.com) - Ship owners
   - OrdererMSP (bki.com) - Ordering service

2. **Smart Contract** (`chaincode-javascript/index.js`): Ship certification business logic
   - Authority, vessel, survey, findings, and certificate management
   - Role-based access control via MSP ID validation
   - Cryptographic certificate hashing for verification

3. **REST API Server** (`api-server/server.js`): Node.js Express gateway
   - JWT authentication with role-based authorization
   - Rate limiting and security middleware (helmet, CORS)
   - Fabric network connection management with retry logic
   - Serves frontend static files in production

4. **Frontend** (`frontend/`): Vue.js 3 + Vite SPA
   - Role-based UI (Authority, Ship Owner, Public)
   - Naive UI component library
   - Pinia state management
   - Axios for API communication

### Key Business Entities
- **Authority**: BKI certification authorities who manage the system
- **Ship Owner**: Companies that own vessels requiring certification
- **Vessel**: Ships registered for certification
- **Survey**: Inspection processes (hull, machinery, annual, etc.)
- **Finding**: Issues discovered during surveys (severity: minor/major/critical)
- **Certificate**: Issued after successful survey completion

### Network Configuration
- Channel: `bkichannel`
- Chaincode: `shipCertify`
- TLS enabled for all communication
- Connection profiles: `/root/ship-certify-hl/organizations/peerOrganizations/*/connection-*.json`
- Crypto materials: `/root/ship-certify-hl/organizations/`
- Wallet location: `/root/ship-certify-hl/api-server/wallet/`
- Crypto materials generated via cryptogen (not CA-based in current setup)

### Security & Access Control
- **MSP-based Authorization**: AuthorityMSP can create/manage, ShipOwnerMSP can resolve findings
- **JWT Authentication**: API layer with role-based access (authority/shipowner/public)
- **Certificate Hash Verification**: SHA-256 hashing for certificate integrity

## Development Guidelines

### Working with Hyperledger Fabric
- Always start network before API server: `cd /root/ship-certify-hl && ./network.sh up`
- Connection profile path: `/root/ship-certify-hl/api-server/connection-tls.json`
- Wallet stored in: `/root/ship-certify-hl/api-server/wallet/`
- Organizations crypto: `/root/ship-certify-hl/organizations/`
- Admin user auto-enrolled from cryptogen certificates
- Docker network: `fabric_bki`

### API Development
- All chaincode interactions go through `FabricService` class
- Retry logic implemented for network resilience
- Error handling distinguishes between network and business logic errors
- Rate limiting: 100 requests per 15 minutes per IP

### Frontend Development
- Vue 3 Composition API preferred
- Role switching via dropdown (no actual authentication in demo)
- Environment variables: `VITE_API_URL` for API endpoint
- Build output: `/root/ship-certify-hl/frontend/dist/`
- Served statically by API server in production

### Common Issues
- **Network connectivity**: Ensure Docker is running and network is up
- **Certificate issues**: Regenerate crypto materials with `cd /root/ship-certify-hl && ./network.sh generateCerts`
- **Port conflicts**: Default ports 3000 (API), 8080 (frontend), 7050/7051/9051 (Fabric)
- **Permission errors**: Check Docker socket permissions and file ownership in `/root/ship-certify-hl/`
- **Ubuntu firewall**: May need to configure UFW to allow ports 3000, 8080 for external access
- **Root privileges**: Most operations require root access due to Docker and file permissions
- **Identity/Certificate errors**: "creator org unknown, creator is malformed" - Fix with:
  ```bash
  cd /root/ship-certify-hl
  ./network.sh down
  ./network.sh clean
  ./network.sh generateCerts
  ./network.sh up
  ./network.sh createChannel
  ./network.sh deployCC
  # Restart API server after network is fully up
  ```

### Database & State
- No external database - all data stored on blockchain ledger
- Document types: `authority`, `shipowner`, `vessel`, `survey`, `certificate`
- Query functions for each entity type available in chaincode
- Findings stored as array within survey documents

This is a blockchain-based ship certification system demonstrating Hyperledger Fabric integration with modern web technologies. The system maintains immutable records of ship inspections and certifications for maritime compliance.