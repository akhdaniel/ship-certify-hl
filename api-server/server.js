const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { Gateway, Wallets } = require('fabric-network');
const FabricCAServices = require('fabric-ca-client');
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
    max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Fabric network configuration  
const ccpPath = path.resolve(__dirname, 'connection-tls.json');
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
        
        // Check if admin user exists
        const adminExists = await this.wallet.get('admin');
        if (!adminExists) {
            await this.enrollAdmin();
        }
    }

    generateConnectionProfile() {
        // Detect environment and set appropriate paths
        const isContainer = fs.existsSync('/app/organizations');
        const basePath = isContainer ? '/app' : '/root/ship-certify-hl';
        const environment = isContainer ? 'container' : 'host';
        
        // For container: use Docker hostnames, for host: use localhost
        const peerHostname = isContainer ? 'peer0.authority.bki.com' : 'localhost';
        const shipownerHostname = isContainer ? 'peer0.shipowner.bki.com' : 'localhost';
        const ordererHostname = isContainer ? 'orderer.bki.com' : 'localhost';
        
        return {
            environment,
            basePath,
            name: "bki-network-authority",
            version: "1.0.0",
            client: {
                organization: "AuthorityMSP",
                connection: {
                    timeout: {
                        peer: {
                            endorser: "300"
                        },
                        orderer: "300"
                    }
                }
            },
            organizations: {
                AuthorityMSP: {
                    mspid: "AuthorityMSP",
                    peers: ["peer0.authority.bki.com"]
                },
                ShipOwnerMSP: {
                    mspid: "ShipOwnerMSP",
                    peers: ["peer0.shipowner.bki.com"]
                }
            },
            peers: {
                "peer0.authority.bki.com": {
                    url: `grpcs://${peerHostname}:7051`,
                    tlsCACerts: {
                        path: `${basePath}/organizations/peerOrganizations/authority.bki.com/peers/peer0.authority.bki.com/tls/ca.crt`
                    },
                    grpcOptions: {
                        "ssl-target-name-override": "peer0.authority.bki.com",
                        "hostnameOverride": "peer0.authority.bki.com"
                    }
                },
                "peer0.shipowner.bki.com": {
                    url: `grpcs://${shipownerHostname}:9051`,
                    tlsCACerts: {
                        path: `${basePath}/organizations/peerOrganizations/shipowner.bki.com/peers/peer0.shipowner.bki.com/tls/ca.crt`
                    },
                    grpcOptions: {
                        "ssl-target-name-override": "peer0.shipowner.bki.com",
                        "hostnameOverride": "peer0.shipowner.bki.com"
                    }
                }
            },
            orderers: {
                "orderer.bki.com": {
                    url: `grpcs://${ordererHostname}:7050`,
                    tlsCACerts: {
                        path: `${basePath}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/ca.crt`
                    },
                    grpcOptions: {
                        "ssl-target-name-override": "orderer.bki.com",
                        "hostnameOverride": "orderer.bki.com"
                    }
                }
            }
        };
    }

    async enrollAdmin() {
        try {
            // Read admin certificates from cryptogen output
            // Check if running in container (Docker) or on host
            const isContainer = fs.existsSync('/app/organizations');
            const baseDir = isContainer ? '/app' : '/root/ship-certify-hl';
            
            const adminCertPath = path.resolve(baseDir, 'organizations', 'peerOrganizations', 'authority.bki.com', 'users', 'Admin@authority.bki.com', 'msp', 'signcerts');
            const adminKeyPath = path.resolve(baseDir, 'organizations', 'peerOrganizations', 'authority.bki.com', 'users', 'Admin@authority.bki.com', 'msp', 'keystore');
            
            const certFiles = fs.readdirSync(adminCertPath);
            const keyFiles = fs.readdirSync(adminKeyPath);
            
            if (certFiles.length === 0 || keyFiles.length === 0) {
                throw new Error('Admin certificates not found. Run ./network.sh generateCerts first.');
            }
            
            const certificate = fs.readFileSync(path.join(adminCertPath, certFiles[0]), 'utf8');
            const privateKey = fs.readFileSync(path.join(adminKeyPath, keyFiles[0]), 'utf8');
            
            const x509Identity = {
                credentials: {
                    certificate: certificate,
                    privateKey: privateKey,
                },
                mspId: 'AuthorityMSP',
                type: 'X.509',
            };
            await this.wallet.put('admin', x509Identity);
            console.log('Successfully imported admin user from cryptogen certificates');
        } catch (error) {
            console.error(`Failed to enroll admin user: ${error}`);
            throw error;
        }
    }

    async connectToNetwork(userId = 'admin') {
        try {
            // Generate dynamic connection profile based on environment
            const ccp = this.generateConnectionProfile();
            
            console.log('Using dynamic connection profile');
            console.log('Environment:', ccp.environment);
            console.log('Base path:', ccp.basePath);
            console.log('Connection profile peers:', Object.keys(ccp.peers || {}));
            
            this.gateway = new Gateway();
            
            // Adjust discovery settings based on environment
            const isContainer = fs.existsSync('/app/organizations');
            const discoveryOptions = {
                enabled: false,  // Disable discovery, use manual endorsement strategy
                asLocalhost: !isContainer  // true for host mode, false for container mode
            };
            
            console.log('Discovery settings:', discoveryOptions);
            
            await this.gateway.connect(ccp, {
                wallet: this.wallet,
                identity: userId,
                discovery: discoveryOptions,
                eventHandlerOptions: {
                    strategy: null
                },
                queryHandlerOptions: {
                    timeout: 45
                }
            });

            const network = await this.gateway.getNetwork(channelName);
            this.contract = network.getContract(chaincodeName);
            
            console.log('Successfully connected to network and got contract');
            return this.contract;
        } catch (error) {
            console.error(`Failed to connect to network: ${error}`);
            console.error('Error details:', error.message);
            if (error.stack) {
                console.error('Stack trace:', error.stack);
            }
            throw error;
        }
    }

    async disconnect() {
        if (this.gateway) {
            await this.gateway.disconnect();
        }
    }

    async submitTransaction(functionName, ...args) {
        try {
            console.log(`Submitting transaction: ${functionName} with args:`, args);
            
            // Add retry logic for network issues
            let retries = 3;
            let lastError;
            
            while (retries > 0) {
                try {
                    // Use simple submitTransaction for endorsement policy compliance
                    const result = await this.contract.submitTransaction(functionName, ...args);
                    console.log(`Transaction result:`, result.toString());
                    
                    if (result.toString().trim() === '') {
                        return { success: true, message: 'Transaction submitted successfully' };
                    }
                    
                    return JSON.parse(result.toString());
                } catch (error) {
                    lastError = error;
                    console.error(`Transaction attempt failed (${4 - retries}/3):`, error.message);
                    
                    if (error.message.includes('No valid responses') || 
                        error.message.includes('connection error') ||
                        error.message.includes('UNAVAILABLE') ||
                        error.message.includes('endorsement policy failure')) {
                        retries--;
                        if (retries > 0) {
                            console.log(`Retrying in 2 seconds... (${retries} attempts left)`);
                            await new Promise(resolve => setTimeout(resolve, 2000));
                            continue;
                        }
                    } else {
                        // For other errors, don't retry
                        break;
                    }
                }
            }
            
            console.error(`Failed to submit transaction after all retries: ${lastError}`);
            console.error(`Transaction details:`, {
                functionName,
                args,
                error: lastError.message,
                responses: lastError.responses || [],
                errors: lastError.errors || []
            });
            
            // Log more detailed error information
            if (lastError.responses && lastError.responses.length > 0) {
                console.error(`Peer responses:`, lastError.responses.map(r => ({
                    status: r.response?.status,
                    message: r.response?.message,
                    peer: r.peer
                })));
            }
            
            if (lastError.errors && lastError.errors.length > 0) {
                console.error(`Peer errors:`, lastError.errors.map(e => ({
                    message: e.message,
                    peer: e.peer
                })));
            }
            
            throw lastError;
        } catch (error) {
            console.error(`Failed to submit transaction: ${error}`);
            throw error;
        }
    }

    async evaluateTransaction(functionName, ...args) {
        try {
            console.log(`Evaluating transaction: ${functionName} with args:`, args);
            
            // Create transaction for evaluation (read-only, no endorsement needed)
            const transaction = this.contract.createTransaction(functionName);
            
            // For queries, we can use any single peer since it's read-only
            // This avoids unnecessary endorsement complexity for read operations
            const result = await transaction.evaluate(...args);
            console.log(`Raw result length: ${result.length}, content:`, result.toString());
            
            const resultString = result.toString();
            if (!resultString || resultString.trim() === '') {
                console.log('Empty result, returning empty array');
                return [];
            }
            
            try {
                const parsed = JSON.parse(resultString);
                console.log('Successfully parsed result:', parsed);
                return parsed;
            } catch (parseError) {
                console.error('JSON parse error:', parseError);
                console.error('Attempting to parse:', resultString);
                return [];
            }
        } catch (error) {
            console.error(`Failed to evaluate transaction ${functionName}:`, error);
            console.error(`Error details:`, error.details || error.message);
            
            // If it's a query that should return an empty array on failure
            if (functionName.startsWith('queryAll')) {
                console.log('Query failed, returning empty array for queryAll function');
                return [];
            }
            
            throw error;
        }
    }
}

const fabricService = new FabricService();

// Initialize Fabric connection
async function initializeFabric() {
    try {
        await fabricService.initializeWallet();
        await fabricService.connectToNetwork();
        console.log('Fabric network connected successfully');
    } catch (error) {
        console.error('Failed to initialize Fabric connection:', error);
        process.exit(1);
    }
}

// Error handling middleware
const asyncHandler = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
};

// Helper: Load users from file with error handling
function loadUsers() {
  try {
    if (!fs.existsSync(USERS_FILE)) {
      console.warn(`[WARN] users.json not found at ${USERS_FILE}`);
      return [];
    }
    return JSON.parse(fs.readFileSync(USERS_FILE, 'utf8'));
  } catch (err) {
    console.error(`[ERROR] Failed to load users.json:`, err);
    return [];
  }
}

// Helper: Find user by username/email
function findUser(username) {
  const users = loadUsers();
  return users.find(u => u.username === username || u.email === username);
}

// JWT Auth Middleware
function authMiddleware(req, res, next) {
  // Allow /api/login and /health
  if (
    req.path === '/api/login' ||
    req.path === '/health' ||
    (req.method === 'GET' && (
      req.path.startsWith('/api/vessels') ||
      req.path.startsWith('/api/certificates') ||
      req.path.startsWith('/api/shipowners')
    ))
  ) {
    return next();
  }
  const authHeader = req.headers['authorization'] || '';
  const token = authHeader.replace('Bearer ', '');
  if (!token) {
    return res.status(401).json({ error: 'Missing token' });
  }
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = payload;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

// Role-based access control middleware
function requireRole(role) {
  return (req, res, next) => {
    if (!req.user || req.user.role !== role) {
      return res.status(403).json({ error: 'Forbidden: insufficient role' });
    }
    next();
  };
}

app.use(authMiddleware);

// ===================== Auth Routes =====================

app.post('/api/login', asyncHandler(async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required' });
  }
  const user = findUser(username);
  if (!user) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  // Issue JWT
  const token = jwt.sign({ id: user.id, username: user.username, role: user.role }, JWT_SECRET, { expiresIn: '8h' });
  res.json({
    success: true,
    token,
    user: { id: user.id, username: user.username, role: user.role, name: user.name }
  });
}));

// ===================== API Routes =====================

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// ===================== Authority Routes =====================

app.post('/api/authorities', requireRole('authority'), asyncHandler(async (req, res) => {
    const { authorityId, address, name } = req.body;
    
    if (!authorityId || !address || !name) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    const result = await fabricService.submitTransaction('registerAuthority', authorityId, address, name);
    res.json({ success: true, data: result });
}));

app.post('/api/shipowners', requireRole('authority'), asyncHandler(async (req, res) => {
    const { shipOwnerId, address, name, companyName } = req.body;
    
    if (!shipOwnerId || !address || !name || !companyName) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    const result = await fabricService.submitTransaction('registerShipOwner', shipOwnerId, address, name, companyName);
    res.json({ success: true, data: result });
}));

app.get('/api/shipowners', asyncHandler(async (req, res) => {
    const result = await fabricService.evaluateTransaction('queryAllShipOwners');
    res.json({ success: true, data: result });
}));

// ===================== Vessel Routes =====================

app.post('/api/vessels', requireRole('authority'), asyncHandler(async (req, res) => {
    const { vesselId, name, type, imoNumber, flag, buildYear, shipOwnerId } = req.body;
    
    if (!vesselId || !name || !type || !imoNumber || !flag || !buildYear || !shipOwnerId) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    const result = await fabricService.submitTransaction('registerVessel', vesselId, name, type, imoNumber, flag, buildYear, shipOwnerId);
    res.json({ success: true, data: result });
}));

app.get('/api/vessels', asyncHandler(async (req, res) => {
    const result = await fabricService.evaluateTransaction('queryAllVessels');
    res.json({ success: true, data: result });
}));

app.get('/api/vessels/:vesselId', asyncHandler(async (req, res) => {
    const { vesselId } = req.params;
    const result = await fabricService.evaluateTransaction('queryVessel', vesselId);
    res.json({ success: true, data: result });
}));

// ===================== Survey Routes =====================

app.post('/api/surveys', requireRole('authority'), asyncHandler(async (req, res) => {
    const { surveyId, vesselId, surveyType, scheduledDate, surveyorName } = req.body;
    
    if (!surveyId || !vesselId || !surveyType || !scheduledDate || !surveyorName) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    const result = await fabricService.submitTransaction('scheduleSurvey', surveyId, vesselId, surveyType, scheduledDate, surveyorName);
    res.json({ success: true, data: result });
}));

app.put('/api/surveys/:surveyId/start', requireRole('authority'), asyncHandler(async (req, res) => {
    const { surveyId } = req.params;
    const result = await fabricService.submitTransaction('startSurvey', surveyId);
    res.json({ success: true, data: result });
}));

app.get('/api/surveys', asyncHandler(async (req, res) => {
    const result = await fabricService.evaluateTransaction('queryAllSurveys');
    res.json({ success: true, data: result });
}));

// ===================== Findings Routes =====================

app.post('/api/surveys/:surveyId/findings', asyncHandler(async (req, res) => {
    const { surveyId } = req.params;
    const { findingId, description, severity, location, requirement } = req.body;
    
    if (!findingId || !description || !severity || !location || !requirement) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    const result = await fabricService.submitTransaction('addFinding', surveyId, findingId, description, severity, location, requirement);
    res.json({ success: true, data: result });
}));

app.put('/api/surveys/:surveyId/findings/:findingId/resolve', asyncHandler(async (req, res) => {
    const { surveyId, findingId } = req.params;
    const { resolutionDescription, evidenceUrl } = req.body;
    
    if (!resolutionDescription) {
        return res.status(400).json({ error: 'Resolution description is required' });
    }

    const result = await fabricService.submitTransaction('resolveFinding', surveyId, findingId, resolutionDescription, evidenceUrl || '');
    res.json({ success: true, data: result });
}));

app.put('/api/surveys/:surveyId/findings/:findingId/verify', asyncHandler(async (req, res) => {
    const { surveyId, findingId } = req.params;
    const { verificationNotes } = req.body;
    
    const result = await fabricService.submitTransaction('verifyFinding', surveyId, findingId, verificationNotes || '');
    res.json({ success: true, data: result });
}));

app.get('/api/surveys/:surveyId/findings', asyncHandler(async (req, res) => {
    const { surveyId } = req.params;
    const result = await fabricService.evaluateTransaction('queryFindings', surveyId);
    res.json({ success: true, data: result });
}));

// ===================== Certificate Routes =====================

app.post('/api/certificates', requireRole('authority'), asyncHandler(async (req, res) => {
    const { certificateId, vesselId, surveyId, certificateType, validFrom, validTo } = req.body;
    
    if (!certificateId || !vesselId || !surveyId || !certificateType || !validFrom || !validTo) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    const result = await fabricService.submitTransaction('issueCertificate', certificateId, vesselId, surveyId, certificateType, validFrom, validTo);
    res.json({ success: true, data: result });
}));

app.get('/api/certificates', asyncHandler(async (req, res) => {
    const result = await fabricService.evaluateTransaction('queryAllCertificates');
    res.json({ success: true, data: result });
}));

app.get('/api/certificates/:certificateId', asyncHandler(async (req, res) => {
    const { certificateId } = req.params;
    const result = await fabricService.evaluateTransaction('queryCertificate', certificateId);
    res.json({ success: true, data: result });
}));

app.get('/api/certificates/:certificateId/verify', asyncHandler(async (req, res) => {
    const { certificateId } = req.params;
    const result = await fabricService.evaluateTransaction('verifyCertificate', certificateId);
    res.json({ success: true, data: result });
}));

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('API Error:', error);
    res.status(500).json({
        error: 'Internal server error',
        message: error.message,
        ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
});

// SPA fallback - serve index.html for non-API routes
app.get('*', (req, res) => {
    if (req.path.startsWith('/api/')) {
        res.status(404).json({ error: 'API route not found' });
    } else {
        res.sendFile(path.join(__dirname, 'frontend', 'dist', 'index.html'));
    }
});

// Start server
const startServer = async () => {
    try {
        await initializeFabric();
        
        app.listen(PORT, HOST, () => {
            console.log(`🚀 BKI Ship Certification API Server running on ${HOST}:${PORT}`);
            console.log(`📚 API Documentation available at http://${HOST}:${PORT}/health`);
        });
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
};

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('Shutting down gracefully...');
    await fabricService.disconnect();
    process.exit(0);
});

process.on('SIGTERM', async () => {
    console.log('Shutting down gracefully...');
    await fabricService.disconnect();
    process.exit(0);
});

startServer();