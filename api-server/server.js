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

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
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
const walletPath = path.join(process.cwd(), 'wallet');
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

    async enrollAdmin() {
        try {
            // Read admin certificates from cryptogen output
            const adminCertPath = path.resolve(__dirname, '..', 'organizations', 'peerOrganizations', 'authority.bki.com', 'users', 'Admin@authority.bki.com', 'msp', 'signcerts');
            const adminKeyPath = path.resolve(__dirname, '..', 'organizations', 'peerOrganizations', 'authority.bki.com', 'users', 'Admin@authority.bki.com', 'msp', 'keystore');
            
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
            const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));
            
            console.log('Using connection profile with absolute paths');
            
            this.gateway = new Gateway();
            await this.gateway.connect(ccp, {
                wallet: this.wallet,
                identity: userId,
                discovery: { enabled: false, asLocalhost: true },
                eventHandlerOptions: {
                    strategy: null
                }
            });

            const network = await this.gateway.getNetwork(channelName);
            this.contract = network.getContract(chaincodeName);
            
            return this.contract;
        } catch (error) {
            console.error(`Failed to connect to network: ${error}`);
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
            
            // Use default contract submission
            const result = await this.contract.submitTransaction(functionName, ...args);
            console.log(`Transaction result:`, result.toString());
            return JSON.parse(result.toString());
        } catch (error) {
            console.error(`Failed to submit transaction: ${error}`);
            console.error(`Transaction details:`, {
                functionName,
                args,
                error: error.message,
                responses: error.responses || [],
                errors: error.errors || []
            });
            
            // Log more detailed error information
            if (error.responses && error.responses.length > 0) {
                console.error(`Peer responses:`, error.responses.map(r => ({
                    status: r.response?.status,
                    message: r.response?.message,
                    peer: r.peer
                })));
            }
            
            if (error.errors && error.errors.length > 0) {
                console.error(`Peer errors:`, error.errors.map(e => ({
                    message: e.message,
                    peer: e.peer
                })));
            }
            
            throw error;
        }
    }

    async evaluateTransaction(functionName, ...args) {
        try {
            console.log(`Evaluating transaction: ${functionName} with args:`, args);
            const result = await this.contract.evaluateTransaction(functionName, ...args);
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

// ===================== API Routes =====================

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// ===================== Authority Routes =====================

app.post('/api/authorities', asyncHandler(async (req, res) => {
    const { authorityId, address, name } = req.body;
    
    if (!authorityId || !address || !name) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    const result = await fabricService.submitTransaction('registerAuthority', authorityId, address, name);
    res.json({ success: true, data: result });
}));

app.post('/api/shipowners', asyncHandler(async (req, res) => {
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

app.post('/api/vessels', asyncHandler(async (req, res) => {
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

app.post('/api/surveys', asyncHandler(async (req, res) => {
    const { surveyId, vesselId, surveyType, scheduledDate, surveyorName } = req.body;
    
    if (!surveyId || !vesselId || !surveyType || !scheduledDate || !surveyorName) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    const result = await fabricService.submitTransaction('scheduleSurvey', surveyId, vesselId, surveyType, scheduledDate, surveyorName);
    res.json({ success: true, data: result });
}));

app.put('/api/surveys/:surveyId/start', asyncHandler(async (req, res) => {
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

app.post('/api/certificates', asyncHandler(async (req, res) => {
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
        
        app.listen(PORT, () => {
            console.log(`🚀 BKI Ship Certification API Server running on port ${PORT}`);
            console.log(`📚 API Documentation available at http://localhost:${PORT}/health`);
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