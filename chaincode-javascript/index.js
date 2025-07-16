'use strict';

const { Contract } = require('fabric-contract-api');

class ShipCertifyContract extends Contract {

    async initLedger(ctx) {
        console.info('============= START : Initialize Ledger ===========');
        
        // Initialize with some sample data
        const authorities = [
            {
                id: 'AUTH001',
                address: 'authority1@bki.com',
                name: 'BKI Authority Jakarta',
                isActive: true,
                registeredBy: 'system',
                registeredAt: new Date().toISOString()
            }
        ];

        for (let i = 0; i < authorities.length; i++) {
            authorities[i].docType = 'authority';
            await ctx.stub.putState('AUTH' + i, Buffer.from(JSON.stringify(authorities[i])));
            console.info('Added <--> ', authorities[i]);
        }
        
        console.info('============= END : Initialize Ledger ===========');
    }

    // ===================== Authority Management =====================
    
    async registerAuthority(ctx, authorityId, address, name) {
        const identity = ctx.clientIdentity.getID();
        const mspId = ctx.clientIdentity.getMSPID();
        
        if (mspId !== 'AuthorityMSP') {
            throw new Error('Only BKI Authority can register new authorities');
        }

        const authority = {
            id: authorityId,
            address: address,
            name: name,
            isActive: true,
            docType: 'authority',
            registeredBy: identity,
            registeredAt: new Date().toISOString()
        };

        await ctx.stub.putState(authorityId, Buffer.from(JSON.stringify(authority)));
        return JSON.stringify(authority);
    }

    async registerShipOwner(ctx, shipOwnerId, address, name, companyName) {
        const identity = ctx.clientIdentity.getID();
        const mspId = ctx.clientIdentity.getMSPID();
        
        if (mspId !== 'AuthorityMSP') {
            throw new Error('Only BKI Authority can register ship owners');
        }

        const shipOwner = {
            id: shipOwnerId,
            address: address,
            name: name,
            companyName: companyName,
            isActive: true,
            docType: 'shipowner',
            registeredBy: identity,
            registeredAt: new Date().toISOString()
        };

        await ctx.stub.putState(shipOwnerId, Buffer.from(JSON.stringify(shipOwner)));
        return JSON.stringify(shipOwner);
    }

    // ===================== Vessel Management =====================
    
    async registerVessel(ctx, vesselId, name, type, imoNumber, flag, buildYear, shipOwnerId) {
        const identity = ctx.clientIdentity.getID();
        const mspId = ctx.clientIdentity.getMSPID();
        
        if (mspId !== 'AuthorityMSP') {
            throw new Error('Only BKI Authority can register vessels');
        }

        // Verify ship owner exists
        const shipOwnerBytes = await ctx.stub.getState(shipOwnerId);
        if (!shipOwnerBytes || shipOwnerBytes.length === 0) {
            throw new Error(`Ship owner ${shipOwnerId} does not exist`);
        }

        const vessel = {
            id: vesselId,
            name: name,
            type: type,
            imoNumber: imoNumber,
            flag: flag,
            buildYear: buildYear,
            shipOwnerId: shipOwnerId,
            status: 'registered',
            docType: 'vessel',
            registeredBy: identity,
            registeredAt: new Date().toISOString()
        };

        await ctx.stub.putState(vesselId, Buffer.from(JSON.stringify(vessel)));
        return JSON.stringify(vessel);
    }

    // ===================== Survey Management =====================
    
    async scheduleSurvey(ctx, surveyId, vesselId, surveyType, scheduledDate, surveyorName) {
        const identity = ctx.clientIdentity.getID();
        const mspId = ctx.clientIdentity.getMSPID();
        
        if (mspId !== 'AuthorityMSP') {
            throw new Error('Only BKI Authority can schedule surveys');
        }

        // Verify vessel exists
        const vesselBytes = await ctx.stub.getState(vesselId);
        if (!vesselBytes || vesselBytes.length === 0) {
            throw new Error(`Vessel ${vesselId} does not exist`);
        }

        const survey = {
            id: surveyId,
            vesselId: vesselId,
            surveyType: surveyType, // 'hull', 'machinery', 'annual', 'intermediate', 'renewal'
            scheduledDate: scheduledDate,
            surveyorName: surveyorName,
            status: 'scheduled', // 'scheduled', 'in-progress', 'completed'
            docType: 'survey',
            scheduledBy: identity,
            scheduledAt: new Date().toISOString(),
            findings: []
        };

        await ctx.stub.putState(surveyId, Buffer.from(JSON.stringify(survey)));
        return JSON.stringify(survey);
    }

    async startSurvey(ctx, surveyId) {
        const identity = ctx.clientIdentity.getID();
        const mspId = ctx.clientIdentity.getMSPID();
        
        if (mspId !== 'AuthorityMSP') {
            throw new Error('Only BKI Authority can start surveys');
        }

        const surveyBytes = await ctx.stub.getState(surveyId);
        if (!surveyBytes || surveyBytes.length === 0) {
            throw new Error(`Survey ${surveyId} does not exist`);
        }

        const survey = JSON.parse(surveyBytes.toString());
        if (survey.status !== 'scheduled') {
            throw new Error(`Survey ${surveyId} is not in scheduled status`);
        }

        survey.status = 'in-progress';
        survey.startedAt = new Date().toISOString();
        survey.startedBy = identity;

        await ctx.stub.putState(surveyId, Buffer.from(JSON.stringify(survey)));
        return JSON.stringify(survey);
    }

    // ===================== Findings Management =====================
    
    async addFinding(ctx, surveyId, findingId, description, severity, location, requirement) {
        const identity = ctx.clientIdentity.getID();
        const mspId = ctx.clientIdentity.getMSPID();
        
        if (mspId !== 'AuthorityMSP') {
            throw new Error('Only BKI Authority can add findings');
        }

        const surveyBytes = await ctx.stub.getState(surveyId);
        if (!surveyBytes || surveyBytes.length === 0) {
            throw new Error(`Survey ${surveyId} does not exist`);
        }

        const survey = JSON.parse(surveyBytes.toString());
        if (survey.status !== 'in-progress') {
            throw new Error(`Survey ${surveyId} is not in progress`);
        }

        const finding = {
            id: findingId,
            description: description,
            severity: severity, // 'minor', 'major', 'critical'
            location: location,
            requirement: requirement,
            status: 'open', // 'open', 'resolved', 'verified'
            addedBy: identity,
            addedAt: new Date().toISOString()
        };

        survey.findings.push(finding);
        await ctx.stub.putState(surveyId, Buffer.from(JSON.stringify(survey)));
        
        return JSON.stringify(finding);
    }

    async resolveFinding(ctx, surveyId, findingId, resolutionDescription, evidenceUrl) {
        const identity = ctx.clientIdentity.getID();
        const mspId = ctx.clientIdentity.getMSPID();
        
        // Ship owners can resolve findings
        if (mspId !== 'ShipOwnerMSP' && mspId !== 'AuthorityMSP') {
            throw new Error('Only Ship Owner or BKI Authority can resolve findings');
        }

        const surveyBytes = await ctx.stub.getState(surveyId);
        if (!surveyBytes || surveyBytes.length === 0) {
            throw new Error(`Survey ${surveyId} does not exist`);
        }

        const survey = JSON.parse(surveyBytes.toString());
        const finding = survey.findings.find(f => f.id === findingId);
        
        if (!finding) {
            throw new Error(`Finding ${findingId} not found in survey ${surveyId}`);
        }

        if (finding.status !== 'open') {
            throw new Error(`Finding ${findingId} is not in open status`);
        }

        finding.status = 'resolved';
        finding.resolutionDescription = resolutionDescription;
        finding.evidenceUrl = evidenceUrl;
        finding.resolvedBy = identity;
        finding.resolvedAt = new Date().toISOString();

        await ctx.stub.putState(surveyId, Buffer.from(JSON.stringify(survey)));
        return JSON.stringify(finding);
    }

    async verifyFinding(ctx, surveyId, findingId, verificationNotes) {
        const identity = ctx.clientIdentity.getID();
        const mspId = ctx.clientIdentity.getMSPID();
        
        if (mspId !== 'AuthorityMSP') {
            throw new Error('Only BKI Authority can verify findings');
        }

        const surveyBytes = await ctx.stub.getState(surveyId);
        if (!surveyBytes || surveyBytes.length === 0) {
            throw new Error(`Survey ${surveyId} does not exist`);
        }

        const survey = JSON.parse(surveyBytes.toString());
        const finding = survey.findings.find(f => f.id === findingId);
        
        if (!finding) {
            throw new Error(`Finding ${findingId} not found in survey ${surveyId}`);
        }

        if (finding.status !== 'resolved') {
            throw new Error(`Finding ${findingId} is not resolved yet`);
        }

        finding.status = 'verified';
        finding.verificationNotes = verificationNotes;
        finding.verifiedBy = identity;
        finding.verifiedAt = new Date().toISOString();

        await ctx.stub.putState(surveyId, Buffer.from(JSON.stringify(survey)));
        return JSON.stringify(finding);
    }

    // ===================== Certificate Management =====================
    
    async issueCertificate(ctx, certificateId, vesselId, surveyId, certificateType, validFrom, validTo) {
        const identity = ctx.clientIdentity.getID();
        const mspId = ctx.clientIdentity.getMSPID();
        
        if (mspId !== 'AuthorityMSP') {
            throw new Error('Only BKI Authority can issue certificates');
        }

        // Verify vessel exists
        const vesselBytes = await ctx.stub.getState(vesselId);
        if (!vesselBytes || vesselBytes.length === 0) {
            throw new Error(`Vessel ${vesselId} does not exist`);
        }

        // Verify survey exists and all findings are resolved
        const surveyBytes = await ctx.stub.getState(surveyId);
        if (!surveyBytes || surveyBytes.length === 0) {
            throw new Error(`Survey ${surveyId} does not exist`);
        }

        const survey = JSON.parse(surveyBytes.toString());
        const openFindings = survey.findings.filter(f => f.status === 'open' || f.status === 'resolved');
        
        if (openFindings.length > 0) {
            throw new Error('Cannot issue certificate while there are unverified findings');
        }

        const certificate = {
            id: certificateId,
            vesselId: vesselId,
            surveyId: surveyId,
            certificateType: certificateType, // 'class', 'safety', 'load_line'
            validFrom: validFrom,
            validTo: validTo,
            status: 'active',
            docType: 'certificate',
            issuedBy: identity,
            issuedAt: new Date().toISOString(),
            hash: this.generateCertificateHash(certificateId, vesselId, validFrom, validTo)
        };

        // Update survey status
        survey.status = 'completed';
        survey.completedAt = new Date().toISOString();
        survey.certificateId = certificateId;

        await ctx.stub.putState(surveyId, Buffer.from(JSON.stringify(survey)));
        await ctx.stub.putState(certificateId, Buffer.from(JSON.stringify(certificate)));
        
        return JSON.stringify(certificate);
    }

    generateCertificateHash(certificateId, vesselId, validFrom, validTo) {
        const crypto = require('crypto');
        const data = `${certificateId}${vesselId}${validFrom}${validTo}`;
        return crypto.createHash('sha256').update(data).digest('hex');
    }

    async verifyCertificate(ctx, certificateId) {
        const certificateBytes = await ctx.stub.getState(certificateId);
        if (!certificateBytes || certificateBytes.length === 0) {
            throw new Error(`Certificate ${certificateId} does not exist`);
        }

        const certificate = JSON.parse(certificateBytes.toString());
        const currentDate = new Date();
        const validTo = new Date(certificate.validTo);
        
        const isValid = certificate.status === 'active' && currentDate <= validTo;
        
        return JSON.stringify({
            certificateId: certificate.id,
            vesselId: certificate.vesselId,
            isValid: isValid,
            validTo: certificate.validTo,
            hash: certificate.hash
        });
    }

    // ===================== Query Functions =====================
    
    async queryAllVessels(ctx) {
        const startKey = '';
        const endKey = '';
        const allResults = [];
        
        for await (const {key, value} of ctx.stub.getStateByRange(startKey, endKey)) {
            const strValue = Buffer.from(value).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            
            if (record.docType === 'vessel') {
                allResults.push({Key: key, Record: record});
            }
        }
        
        return JSON.stringify(allResults);
    }

    async queryAllShipOwners(ctx) {
        const startKey = '';
        const endKey = '';
        const allResults = [];
        
        for await (const {key, value} of ctx.stub.getStateByRange(startKey, endKey)) {
            const strValue = Buffer.from(value).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            
            if (record.docType === 'shipowner') {
                allResults.push({Key: key, Record: record});
            }
        }
        
        return JSON.stringify(allResults);
    }

    async queryAllSurveys(ctx) {
        const startKey = '';
        const endKey = '';
        const allResults = [];
        
        for await (const {key, value} of ctx.stub.getStateByRange(startKey, endKey)) {
            const strValue = Buffer.from(value).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            
            if (record.docType === 'survey') {
                allResults.push({Key: key, Record: record});
            }
        }
        
        return JSON.stringify(allResults);
    }

    async queryAllCertificates(ctx) {
        const startKey = '';
        const endKey = '';
        const allResults = [];
        
        for await (const {key, value} of ctx.stub.getStateByRange(startKey, endKey)) {
            const strValue = Buffer.from(value).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            
            if (record.docType === 'certificate') {
                allResults.push({Key: key, Record: record});
            }
        }
        
        return JSON.stringify(allResults);
    }

    async queryFindings(ctx, surveyId) {
        const surveyBytes = await ctx.stub.getState(surveyId);
        if (!surveyBytes || surveyBytes.length === 0) {
            throw new Error(`Survey ${surveyId} does not exist`);
        }

        const survey = JSON.parse(surveyBytes.toString());
        return JSON.stringify(survey.findings || []);
    }

    async queryVessel(ctx, vesselId) {
        const vesselBytes = await ctx.stub.getState(vesselId);
        if (!vesselBytes || vesselBytes.length === 0) {
            throw new Error(`Vessel ${vesselId} does not exist`);
        }
        return vesselBytes.toString();
    }

    async queryCertificate(ctx, certificateId) {
        const certificateBytes = await ctx.stub.getState(certificateId);
        if (!certificateBytes || certificateBytes.length === 0) {
            throw new Error(`Certificate ${certificateId} does not exist`);
        }
        return certificateBytes.toString();
    }

    async queryUser(ctx, userId) {
        const userBytes = await ctx.stub.getState(userId);
        if (!userBytes || userBytes.length === 0) {
            throw new Error(`User ${userId} does not exist`);
        }
        return userBytes.toString();
    }
}

module.exports = ShipCertifyContract;