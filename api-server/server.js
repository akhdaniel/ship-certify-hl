const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { Gateway, Wallets } = require('fabric-network');
const path = require('path');
const fs = require('fs');
require('dotenv').config();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const USERS_FILE = path.join(__dirname, 'users.json');
const JWT_SECRET = process.env.JWT_SECRET || 'supersecretkey';

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

// Middleware
app.use(helmet());
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Serve static files from frontend dist
app.use(express.static(path.join(__dirname, 'frontend', 'dist')));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 1000 // limit each IP to 1000 requests per windowMs
});
app.use(limiter);

// Fabric network configuration  
const walletPath = path.join(__dirname, 'wallet');
const channelName = 'bkichannel';
const chaincodeName = 'shipCertify';

class FabricService {
    constructor() {
        this.gateway = null;
        this.wallet = null;
        this.contract = null;
    }

    async initializeWallet() {
        this.wallet = await Wallets.newFileSystemWallet(walletPath);
    }

    generateConnectionProfile(mspId) {
        const isContainer = fs.existsSync('/app/organizations');
        const basePath = isContainer ? '/app' : '/root/ship-certify-hl';
        const peerHostname = isContainer ? 'peer0.authority.bki.com' : 'localhost';
        const shipownerHostname = isContainer ? 'peer0.shipowner.bki.com' : 'localhost';
        const ordererHostname = isContainer ? 'orderer.bki.com' : 'localhost';
        
        return {
            name: "bki-network-dynamic",
            version: "1.0.0",
            client: {
                organization: mspId,
                connection: { timeout: { peer: { endorser: "300" }, orderer: "300" } }
            },
            organizations: {
                AuthorityMSP: { mspid: "AuthorityMSP", peers: ["peer0.authority.bki.com"] },
                ShipOwnerMSP: { mspid: "ShipOwnerMSP", peers: ["peer0.shipowner.bki.com"] }
            },
            peers: {
                "peer0.authority.bki.com": {
                    url: `grpcs://${peerHostname}:7051`,
                    tlsCACerts: { path: `${basePath}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/ca.crt` },
                    grpcOptions: { "ssl-target-name-override": "peer0.authority.bki.com", "hostnameOverride": "peer0.authority.bki.com" }
                },
                "peer0.shipowner.bki.com": {
                    url: `grpcs://${shipownerHostname}:9051`,
                    tlsCACerts: { path: `${basePath}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/tls/ca.crt` },
                    grpcOptions: { "ssl-target-name-override": "peer0.shipowner.bki.com", "hostnameOverride": "peer0.shipowner.bki.com" }
                }
            },
            orderers: {
                "orderer.bki.com": {
                    url: `grpcs://${ordererHostname}:7050`,
                    tlsCACerts: { path: `${basePath}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/ca.crt` },
                    grpcOptions: { "ssl-target-name-override": "orderer.bki.com", "hostnameOverride": "orderer.bki.com" }
                }
            }
        };
    }

    async connectToNetwork(userId = 'admin') {
        const maxRetries = 10;
        const retryInterval = 10000; // 10 seconds

        for (let i = 0; i < maxRetries; i++) {
            try {
                const identity = await this.wallet.get(userId);
                if (!identity) {
                    throw new Error(`Identity not found in wallet: ${userId}`);
                }
                const userMspId = identity.mspId;

                const ccp = this.generateConnectionProfile(userMspId);
                this.gateway = new Gateway();
                
                await this.gateway.connect(ccp, {
                    wallet: this.wallet,
                    identity: userId,
                    discovery: { enabled: false },
                    eventHandlerOptions: { strategy: null },
                    queryHandlerOptions: { timeout: 45 }
                });

                const network = await this.gateway.getNetwork(channelName);
                this.contract = network.getContract(chaincodeName);
                
                // Perform a test query to ensure chaincode is ready
                await this.evaluateTransaction('queryAllVessels');
                console.log('Chaincode is responsive.');

                return; // Success
            } catch (error) {
                console.error(`Failed to connect to network for user ${userId}: ${error}`);
                if (this.gateway && this.gateway.isConnected()) {
                    await this.gateway.disconnect();
                }
                if (i < maxRetries - 1) {
                    console.log(`Retrying in ${retryInterval / 1000} seconds...`);
                    await new Promise(resolve => setTimeout(resolve, retryInterval));
                } else {
                    throw new Error('Could not connect to Fabric network after multiple retries.');
                }
            }
        }
    }

    async disconnect() {
        if (this.gateway) {
            await this.gateway.disconnect();
        }
    }

    async submitTransaction(functionName, ...args) {
        return this.contract.submitTransaction(functionName, ...args);
    }

    async evaluateTransaction(functionName, ...args) {
        console.log(`Evaluating transaction: ${functionName}(${args.join(',')})`);
        const resultBytes = await this.contract.evaluateTransaction(functionName, ...args);
        const resultString = resultBytes.toString();
        console.log(`Transaction result: ${resultString}`);
        return resultString ? JSON.parse(resultString) : [];
    }
}

const asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

function findUser(username) {
  const users = JSON.parse(fs.readFileSync(USERS_FILE, 'utf8'));
  return users.find(u => u.username === username || u.email === username);
}

function authMiddleware(req, res, next) {
  const publicRoutes = ['/api/login', '/health'];
  if (publicRoutes.includes(req.path) || (req.method === 'GET' && !req.path.includes('/my'))) {
    return next();
  }
  const token = (req.headers['authorization'] || '').replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Missing token' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

function requireRole(role) {
  return (req, res, next) => {
    if (!req.user || req.user.role !== role) {
      return res.status(403).json({ error: 'Forbidden: insufficient role' });
    }
    next();
  };
}

const connectAsUser = asyncHandler(async (req, res, next) => {
  const userId = req.user.shipOwnerId || req.user.username;
  req.fabricService = new FabricService();
  await req.fabricService.initializeWallet();
  await req.fabricService.connectToNetwork(userId);
  res.on('finish', () => req.fabricService.disconnect());
  next();
});

const globalFabricService = new FabricService();

app.use(authMiddleware);

// Auth Routes
app.post('/api/login', asyncHandler(async (req, res) => {
  const { username, password } = req.body;
  const user = findUser(username);
  if (!user || !await bcrypt.compare(password, user.passwordHash)) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  const token = jwt.sign({ id: user.id, username: user.username, role: user.role, shipOwnerId: user.shipOwnerId }, JWT_SECRET, { expiresIn: '8h' });
  res.json({ success: true, token, user: { id: user.id, username: user.username, role: user.role, name: user.name, shipOwnerId: user.shipOwnerId } });
}));

// ===================== API Routes =====================

// Health check
app.get('/health', (req, res) => res.json({ status: 'OK', timestamp: new Date().toISOString() }));

// Authority Routes
app.post('/api/authorities', requireRole('authority'), asyncHandler(async (req, res) => {
    const result = await globalFabricService.submitTransaction('registerAuthority', ...Object.values(req.body));
    res.json({ success: true, data: result });
}));

app.post('/api/shipowners', requireRole('authority'), asyncHandler(async (req, res) => {
    const result = await globalFabricService.submitTransaction('registerShipOwner', ...Object.values(req.body));
    res.json({ success: true, data: result });
}));

app.get('/api/shipowners', asyncHandler(async (req, res) => {
    const result = await globalFabricService.evaluateTransaction('queryAllShipOwners');
    res.json({ success: true, data: result });
}));

// Vessel Routes
app.post('/api/vessels', requireRole('authority'), asyncHandler(async (req, res) => {
    const result = await globalFabricService.submitTransaction('registerVessel', ...Object.values(req.body));
    res.json({ success: true, data: result });
}));

app.get('/api/vessels', asyncHandler(async (req, res) => {
    const result = await globalFabricService.evaluateTransaction('queryAllVessels');
    res.json({ success: true, data: result });
}));

app.get('/api/vessels/my', requireRole('shipowner'), connectAsUser, asyncHandler(async (req, res) => {
    const result = await req.fabricService.evaluateTransaction('queryMyVessels', req.user.shipOwnerId);
    res.json({ success: true, data: result });
}));

// Survey Routes
app.post('/api/surveys', requireRole('authority'), asyncHandler(async (req, res) => {
    const result = await globalFabricService.submitTransaction('scheduleSurvey', ...Object.values(req.body));
    res.json({ success: true, data: result });
}));

app.get('/api/surveys', asyncHandler(async (req, res) => {
    const result = await globalFabricService.evaluateTransaction('queryAllSurveys');
    res.json({ success: true, data: result });
}));

app.get('/api/surveys/my', requireRole('shipowner'), connectAsUser, asyncHandler(async (req, res) => {
    const result = await req.fabricService.evaluateTransaction('queryMySurveys', req.user.shipOwnerId);
    res.json({ success: true, data: result });
}));

// Findings Routes
app.post('/api/surveys/:surveyId/findings', asyncHandler(async (req, res) => {
    const result = await globalFabricService.submitTransaction('addFinding', req.params.surveyId, ...Object.values(req.body));
    res.json({ success: true, data: result });
}));

app.put('/api/surveys/:surveyId/findings/:findingId/resolve', connectAsUser, asyncHandler(async (req, res) => {
    const result = await req.fabricService.submitTransaction('resolveFinding', req.params.surveyId, req.params.findingId, ...Object.values(req.body));
    res.json({ success: true, data: result });
}));

app.put('/api/surveys/:surveyId/findings/:findingId/verify', requireRole('authority'), asyncHandler(async (req, res) => {
    const result = await globalFabricService.submitTransaction('verifyFinding', req.params.surveyId, req.params.findingId, ...Object.values(req.body));
    res.json({ success: true, data: result });
}));

app.get('/api/findings', asyncHandler(async (req, res) => {
    const result = await globalFabricService.evaluateTransaction('queryAllFindings');
    res.json({ success: true, data: result });
}));

app.get('/api/findings/my/open', requireRole('shipowner'), connectAsUser, asyncHandler(async (req, res) => {
    const result = await req.fabricService.evaluateTransaction('queryMyOpenFindings', req.user.shipOwnerId);
    res.json({ success: true, data: result });
}));

// Certificate Routes
app.post('/api/certificates', requireRole('authority'), asyncHandler(async (req, res) => {
    const result = await globalFabricService.submitTransaction('issueCertificate', ...Object.values(req.body));
    res.json({ success: true, data: result });
}));

app.get('/api/certificates', asyncHandler(async (req, res) => {
    const result = await globalFabricService.evaluateTransaction('queryAllCertificates');
    res.json({ success: true, data: result });
}));

app.get('/api/certificates/my', requireRole('shipowner'), connectAsUser, asyncHandler(async (req, res) => {
    const result = await req.fabricService.evaluateTransaction('queryMyCertificates', req.user.shipOwnerId);
    res.json({ success: true, data: result });
}));

app.get('/api/certificates/:id/verify', asyncHandler(async (req, res) => {
    const result = await globalFabricService.evaluateTransaction('verifyCertificate', req.params.id);
    res.json({ success: true, data: result });
}));

// Error handling
app.use((error, req, res, next) => {
    console.error('API Error:', error);
    res.status(500).json({ error: 'Internal server error', message: error.message });
});

// SPA fallback
app.get('*', (req, res) => res.sendFile(path.join(__dirname, 'frontend', 'dist', 'index.html')));

// Start server
(async () => {
    try {
        await globalFabricService.initializeWallet();
        
        const maxRetries = 10;
        const retryInterval = 10000; // 10 seconds
        let connected = false;

        for (let i = 0; i < maxRetries; i++) {
            try {
                console.log(`Attempting to connect to Fabric network (attempt ${i + 1}/${maxRetries})...`);
                await globalFabricService.connectToNetwork('authority');
                console.log('Successfully connected to Fabric network.');
                
                // Perform a test query to ensure chaincode is ready
                await globalFabricService.evaluateTransaction('queryAllVessels');
                console.log('Chaincode is responsive.');

                connected = true;
                break;
            } catch (error) {
                console.error(`Connection attempt ${i + 1} failed:`, error.message);
                if (i < maxRetries - 1) {
                    console.log(`Retrying in ${retryInterval / 1000} seconds...`);
                    await new Promise(resolve => setTimeout(resolve, retryInterval));
                }
            }
        }

        if (!connected) {
            throw new Error('Could not connect to Fabric network after multiple retries.');
        }

        app.listen(PORT, HOST, () => console.log(`🚀 Server running on ${HOST}:${PORT}`));
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
})();