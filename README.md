# BKI Ship Certification System

Aplikasi blockchain lengkap untuk sistem sertifikasi kapal Biro Klasifikasi Indonesia (BKI) menggunakan Hyperledger Fabric, Node.js API, dan Vue.js frontend.

## Arsitektur Sistem

### Komponen Utama
- **Hyperledger Fabric Network**: Blockchain network dengan 2 organisasi (Authority dan ShipOwner)
- **Smart Contract (Chaincode)**: JavaScript chaincode untuk business logic
- **REST API Server**: Node.js Express server sebagai gateway ke blockchain
- **Frontend UI**: Vue.js + Vite aplikasi web dengan role-based access

### User Roles

#### 1. Authority (BKI)
- Mendaftarkan authority baru
- Mendaftarkan Ship Owner
- Mendaftarkan kapal (vessel)
- Menjadwalkan survey
- Mencatat findings
- Memverifikasi findings
- Mengeluarkan certificate

#### 2. Ship Owner
- Melihat findings
- Menyelesaikan findings
- Melihat kapal yang dimiliki
- Melihat survey dan sertifikat

#### 3. Public
- Melihat daftar kapal terdaftar
- Melihat daftar Ship Owner
- Melihat daftar findings (read-only)
- Melihat daftar survey
- Melihat dan memverifikasi sertifikat

## Business Process

1. **Pendaftaran**: Authority mendaftarkan kapal dan Ship Owner
2. **Penjadwalan Survey**: Authority menjadwalkan survey sesuai jenis dan periode
3. **Pelaksanaan Survey**: Surveyor melakukan survey dan mencatat findings
4. **Penyelesaian Findings**: Ship Owner menyelesaikan temuan dari survey
5. **Verifikasi**: Authority memverifikasi penyelesaian findings
6. **Penerbitan Sertifikat**: Certificate dikeluarkan setelah semua findings selesai

## Struktur Proyek

```
ship-certify-hl/
├── chaincode-javascript/         # Smart Contract
│   ├── index.js                  # Main chaincode file
│   └── package.json
├── api-server/                   # REST API Server
│   ├── server.js                 # Main server file
│   ├── package.json
│   └── .env
├── frontend/                     # Vue.js Frontend
│   ├── src/
│   │   ├── components/
│   │   ├── views/               # Page components
│   │   ├── stores/              # Pinia stores
│   │   ├── services/            # API services
│   │   └── main.js
│   ├── package.json
│   └── vite.config.js
├── organizations/                # Fabric network configurations
├── docker-compose.yaml          # Container orchestration
├── configtx.yaml               # Fabric configuration
├── network.sh                  # Network management script
└── README.md
```

## Prerequisites

1. **Docker & Docker Compose V2**
2. **Node.js** (v14 atau lebih tinggi)
3. **Hyperledger Fabric Binaries** (v2.5)
4. **Git**

## Installation & Setup

### 1. Clone Repository
```bash
git clone <repository-url>
cd ship-certify-hl
```

### 2. Install Hyperledger Fabric Binaries
```bash
# Option 1: Use our installation script (recommended)
./install-fabric.sh

# Option 2: Manual installation
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.4 1.5.5
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx
```

**Note**: We use Fabric 2.5.4 and Fabric CA 1.5.5 for compatibility.

### 3. Setup Fabric Network
```bash
# Generate crypto materials
./network.sh generateCerts

# Start the network
./network.sh up

# Create channel
./network.sh createChannel

# Deploy chaincode
./network.sh deployCC
```

### 4. Setup API Server
```bash
cd api-server
npm install
npm start
```

### 5. Setup Frontend
```bash
cd frontend
npm install
npm run dev
```

## Usage

### Akses Aplikasi
- **Frontend**: http://localhost:8080
- **API Server**: http://localhost:3000
- **Health Check**: http://localhost:3000/health

### Role Switching
Gunakan dropdown di header untuk berganti peran:
- **Public**: Akses terbatas, hanya dapat melihat informasi publik
- **BKI Authority**: Akses penuh untuk manajemen sistem
- **Ship Owner**: Akses terbatas untuk mengelola findings

### API Endpoints

#### Vessels
- `GET /api/vessels` - Get all vessels
- `POST /api/vessels` - Register new vessel
- `GET /api/vessels/:id` - Get vessel by ID

#### Surveys
- `GET /api/surveys` - Get all surveys
- `POST /api/surveys` - Schedule new survey
- `PUT /api/surveys/:id/start` - Start survey

#### Findings
- `GET /api/surveys/:surveyId/findings` - Get findings by survey
- `POST /api/surveys/:surveyId/findings` - Add new finding
- `PUT /api/surveys/:surveyId/findings/:findingId/resolve` - Resolve finding
- `PUT /api/surveys/:surveyId/findings/:findingId/verify` - Verify finding

#### Certificates
- `GET /api/certificates` - Get all certificates
- `POST /api/certificates` - Issue new certificate
- `GET /api/certificates/:id` - Get certificate by ID
- `GET /api/certificates/:id/verify` - Verify certificate

#### Ship Owners
- `GET /api/shipowners` - Get all ship owners
- `POST /api/shipowners` - Register new ship owner

#### Authorities
- `POST /api/authorities` - Register new authority

## Smart Contract Functions

### Authority Management
- `registerAuthority(authorityId, address, name)`
- `registerShipOwner(shipOwnerId, address, name, companyName)`

### Vessel Management
- `registerVessel(vesselId, name, type, imoNumber, flag, buildYear, shipOwnerId)`

### Survey Management
- `scheduleSurvey(surveyId, vesselId, surveyType, scheduledDate, surveyorName)`
- `startSurvey(surveyId)`

### Findings Management
- `addFinding(surveyId, findingId, description, severity, location, requirement)`
- `resolveFinding(surveyId, findingId, resolutionDescription, evidenceUrl)`
- `verifyFinding(surveyId, findingId, verificationNotes)`

### Certificate Management
- `issueCertificate(certificateId, vesselId, surveyId, certificateType, validFrom, validTo)`
- `verifyCertificate(certificateId)`

### Query Functions
- `queryAllVessels()`
- `queryAllShipOwners()`
- `queryAllSurveys()`
- `queryAllCertificates()`
- `queryFindings(surveyId)`

## Development

### Adding New Features
1. Update smart contract in `chaincode-javascript/index.js`
2. Add API endpoints in `api-server/server.js`
3. Update frontend services in `frontend/src/services/api.js`
4. Create/update Vue components

### Testing
```bash
# Test API
curl http://localhost:3000/health

# Test smart contract
docker exec cli peer chaincode invoke -o orderer.bki.com:7050 -C bkichannel -n shipCertify -c '{"function":"queryAllVessels","Args":[]}'
```

## Security Features

1. **Role-based Access Control**: Pembatasan akses berdasarkan MSP ID
2. **Certificate Verification**: Hash-based certificate validation
3. **Immutable Audit Trail**: Semua transaksi tercatat di blockchain
4. **TLS Communication**: Encrypted communication between peers

## Blockchain Benefits

1. **Transparency**: Semua stakeholder dapat melihat status sertifikasi
2. **Immutability**: Data tidak dapat diubah setelah tercatat
3. **Traceability**: Riwayat lengkap proses sertifikasi
4. **Decentralization**: Tidak bergantung pada satu otoritas tunggal
5. **Trust**: Verifikasi otomatis tanpa perantara

## Troubleshooting

### Network Issues
```bash
# Stop network
docker compose down

# Clean up
docker system prune -f
docker volume prune -f

# Restart network
./network.sh up
```

### Fabric CA Version Issues
```bash
# If you encounter "fabric-ca-client binary is not available" error:
# 1. Remove existing binaries
rm -rf bin config

# 2. Install with compatible versions
./install-fabric.sh

# 3. Verify installation
./bin/fabric-ca-client version
```

### API Connection Issues
- Pastikan Fabric network berjalan
- Check connection profile di `organizations/`
- Verify wallet credentials

### Frontend Issues
- Check API server status
- Verify CORS settings
- Check browser console for errors

## Contributing

1. Fork repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License

Copyright © 2024 BKI Ship Certification System. All rights reserved.

---

**Catatan**: Aplikasi ini dibuat untuk demonstrasi sistem sertifikasi kapal menggunakan teknologi blockchain. Untuk implementasi production, diperlukan additional security measures dan compliance dengan regulasi maritim yang berlaku.