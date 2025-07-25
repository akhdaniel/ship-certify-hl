# Gemini Code Analysis: BKI Ship Certification System

## Project Overview

This project is a comprehensive blockchain application for managing ship certifications, ostensibly for the Biro Klasifikasi Indonesia (BKI). It utilizes Hyperledger Fabric for the distributed ledger, a Node.js Express server for the API layer, and a Vue.js single-page application for the user interface. The system is designed to handle the entire lifecycle of ship certification, from vessel registration to survey scheduling, finding management, and certificate issuance.

The application defines clear roles and permissions for different participants in the network, including a central `Authority` (representing BKI) and `ShipOwner` organizations. Public users also have read-only access to certain data.


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
- View logs: `docker compose logs -f api-server`
- Monitor containers: `docker ps -a`
- Check disk space: `df -h` (blockchain data can grow large)


## System Architecture

The architecture is composed of three main components:

1.  **Hyperledger Fabric Network**: The backend is a Hyperledger Fabric network defined by `configtx.yaml`, `crypto-config.yaml`, and orchestrated by `docker-compose.yaml`. It consists of:
    *   An Orderer organization (`OrdererOrg`).
    *   Two peer organizations: `AuthorityMSP` and `ShipOwnerMSP`.
    *   A single channel named `bkichannel`.
    *   The network uses TLS for secure communication between components.

2.  **Node.js API Server**: An Express.js server (`api-server/server.js`) acts as a gateway to the Fabric network. It exposes a RESTful API for the frontend to interact with the blockchain. Key features include:
    *   Connection to the Fabric network using the `fabric-network` SDK.
    *   User authentication and authorization using JWTs, with user data stored in `users.json`.
    *   Role-based access control for API endpoints.
    *   A dynamically generated connection profile to connect to the Fabric peers, adaptable for both local host and containerized environments.

3.  **Vue.js Frontend**: A single-page application (`frontend/`) built with Vue.js and Vite. It provides a user interface for interacting with the system. Key aspects include:
    *   Communication with the API server via an `api.js` service layer using `axios`.
    *   Role-based views for `Authority`, `ShipOwner`, and `Public` users.
    *   State management likely handled by Pinia (inferred from `stores/user.js`).
    *   Components for managing vessels, surveys, findings, certificates, and ship owners.

## Core Functionality (Chaincode)

The smart contract (`chaincode-javascript/index.js`) defines the business logic for the ship certification process. Key functions include:

*   **Registration**:
    *   `registerAuthority`: Adds a new authority to the network.
    *   `registerShipOwner`: Allows the authority to register a new ship owner.
    *   `registerVessel`: Allows the authority to register a new vessel.
*   **Survey and Findings**:
    *   `scheduleSurvey`: The authority can schedule a survey for a vessel.
    *   `addFinding`: The authority can add findings during a survey.
    *   `resolveFinding`: The ship owner can resolve findings.
    *   `verifyFinding`: The authority can verify the resolution of findings.
*   **Certification**:
    *   `issueCertificate`: The authority can issue a certificate once all findings are verified.
    *   `verifyCertificate`: A public-facing function to verify the validity of a certificate using a hash.
*   **Queries**: A set of `queryAll*` functions to retrieve assets from the ledger.

## How to Run the Project

The project includes a comprehensive set of scripts for setup and deployment:

1.  **Prerequisites**: Docker, Docker Compose, Node.js, and Git.
2.  **Installation**: The `install-fabric.sh` script downloads the required Hyperledger Fabric binaries.
3.  **Network Startup**: The `network.sh` script is used to:
    *   `generateCerts`: Create cryptographic materials.
    *   `up`: Start the Fabric network using `docker-compose`.
    *   `createChannel`: Create the application channel.
    *   `deployCC`: Deploy the chaincode.
4.  **Application Startup**:
    *   The API server is started with `npm start` in the `api-server` directory.
    *   The frontend is started with `npm run dev` in the `frontend` directory.
5.  **Deployment**: The `deploy.sh` and `deploy-public.sh` scripts seem to facilitate deployment to a server with a public IP address.

## Security Considerations

The application incorporates several security features:

*   **Role-Based Access Control (RBAC)**: Enforced at both the API server level (with JWTs) and within the chaincode (based on the client's MSP ID).
*   **TLS**: Communication between Fabric nodes and between the API server and the Fabric network is encrypted.
*   **Immutability**: The blockchain provides an immutable audit trail of all certification activities.
*   **Certificate Verification**: A cryptographic hash is used to ensure the integrity of issued certificates.

## Potential Areas for Improvement

*   **Hardcoded Paths**: The `api-server/server.js` contains hardcoded paths (`/root/ship-certify-hl`) which might make it less portable. These could be parameterized using environment variables.
*   **Error Handling**: While the API server has some retry logic, error handling could be made more robust, especially for distinguishing between different types of Fabric transaction errors.
*   **Configuration Management**: The API server's connection profile is generated dynamically, which is good. However, centralizing configuration into a single, well-structured config file or using a dedicated config library could improve maintainability.
*   **Testing**: There are no dedicated unit or integration tests visible in the file structure. Adding a test suite would significantly improve the reliability of the application.
*   **Frontend State Management**: The `README.md` mentions Pinia stores, but the file listing only shows `user.js`. A more comprehensive state management strategy might be needed for a production application.
