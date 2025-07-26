'use strict';

const { Contract } = require('fabric-contract-api');

class ShipCertifyContract extends Contract {

    // Helper function to get deterministic timestamp
    getTxTimestamp(ctx) {
        const timestamp = ctx.stub.getTxTimestamp();
        return new Date(timestamp.seconds * 1000 + Math.floor(timestamp.nanos / 1000000)).toISOString();
    }

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
                registeredAt: this.getTxTimestamp(ctx)
            }
        ];

        for (let i = 0; i < authorities.length; i++) {
            authorities[i].docType = 'authority';
            await ctx.stub.putState(authorities[i].id, Buffer.from(JSON.stringify(authorities[i])));
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
            registeredAt: this.getTxTimestamp(ctx)
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
            registeredAt: this.getTxTimestamp(ctx)
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
            registeredAt: this.getTxTimestamp(ctx)
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
            scheduledAt: this.getTxTimestamp(ctx),
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
        survey.startedAt = this.getTxTimestamp(ctx);
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
            addedAt: this.getTxTimestamp(ctx)
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

        // Security check: Ensure only the vessel owner can resolve the finding
        if (mspId === 'ShipOwnerMSP') {
            const vesselBytes = await ctx.stub.getState(survey.vesselId);
            if (!vesselBytes || vesselBytes.length === 0) {
                throw new Error(`Vessel ${survey.vesselId} not found`);
            }
            const vessel = JSON.parse(vesselBytes.toString());
            if (!identity.includes(vessel.shipOwnerId)) {
                throw new Error(`Caller (${identity}) is not the owner of vessel ${survey.vesselId}`);
            }
        }
        
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
        finding.resolvedAt = this.getTxTimestamp(ctx);

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
        finding.verifiedAt = this.getTxTimestamp(ctx);

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
            issuedAt: this.getTxTimestamp(ctx),
            hash: this.generateCertificateHash(certificateId, vesselId, validFrom, validTo)
        };

        // Update survey status
        survey.status = 'completed';
        survey.completedAt = this.getTxTimestamp(ctx);
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

    async queryAllOpenFindings(ctx) {
        const allSurveysString = await this.queryAllSurveys(ctx);
        const allSurveys = JSON.parse(allSurveysString);
        
        const openFindings = [];
        for (const surveyObj of allSurveys) {
            if (surveyObj.Record && surveyObj.Record.findings) {
                for (const finding of surveyObj.Record.findings) {
                    if (finding.status === 'open') {
                        const findingWithContext = { ...finding, surveyId: surveyObj.Key };
                        openFindings.push(findingWithContext);
                    }
                }
            }
        }
        return JSON.stringify(openFindings);
    }

    async queryMyVessels(ctx, shipOwnerId) {
        console.info('--- DEBUG: queryMyVessels ---');
        console.info(`Searching for shipOwnerId: "${shipOwnerId}" (length: ${shipOwnerId.length})`);

        if (!shipOwnerId) {
            throw new Error('shipOwnerId is required to query personal vessels');
        }
        
        const allVesselsString = await this.queryAllVessels(ctx);
        const allVessels = JSON.parse(allVesselsString);
        
        console.info(`Found ${allVessels.length} total vessels. Filtering...`);

        const myVessels = allVessels.filter(v => {
            const recordOwnerId = v.Record.shipOwnerId;
            const isMatch = recordOwnerId === shipOwnerId;
            console.info(`  - Vessel ${v.Key}: owner is "${recordOwnerId}" (length: ${recordOwnerId.length}). Match: ${isMatch}`);
            return isMatch;
        });

        console.info(`Found ${myVessels.length} matching vessels.`);
        console.info('--- END DEBUG: queryMyVessels ---');
        
        return JSON.stringify(myVessels);
    }

    async queryMyOpenFindings(ctx, shipOwnerId) {
        const myVesselsString = await this.queryMyVessels(ctx, shipOwnerId);
        const myVessels = JSON.parse(myVesselsString);
        const myVesselIds = myVessels.map(v => v.Key);

        const allSurveysString = await this.queryAllSurveys(ctx);
        const allSurveys = JSON.parse(allSurveysString);

        const myOpenFindings = [];
        for (const surveyObj of allSurveys) {
            if (surveyObj.Record && myVesselIds.includes(surveyObj.Record.vesselId) && surveyObj.Record.findings) {
                for (const finding of surveyObj.Record.findings) {
                    if (finding.status === 'open') {
                        myOpenFindings.push({ ...finding, surveyId: surveyObj.Key, vesselId: surveyObj.Record.vesselId });
                    }
                }
            }
        }
        return JSON.stringify(myOpenFindings);
    }

    async queryAllFindings(ctx) {
        const allSurveysString = await this.queryAllSurveys(ctx);
        const allSurveys = JSON.parse(allSurveysString);
        
        const allFindings = [];
        for (const surveyObj of allSurveys) {
            if (surveyObj.Record && surveyObj.Record.findings) {
                for (const finding of surveyObj.Record.findings) {
                    allFindings.push({ ...finding, surveyId: surveyObj.Key, vesselId: surveyObj.Record.vesselId });
                }
            }
        }
        return JSON.stringify(allFindings);
    }

    async queryMySurveys(ctx, shipOwnerId) {
        const myVesselsString = await this.queryMyVessels(ctx, shipOwnerId);
        const myVessels = JSON.parse(myVesselsString);
        const myVesselIds = myVessels.map(v => v.Key);

        const allSurveysString = await this.queryAllSurveys(ctx);
        const allSurveys = JSON.parse(allSurveysString);

        const mySurveys = allSurveys.filter(s => myVesselIds.includes(s.Record.vesselId));
        return JSON.stringify(mySurveys);
    }

    async queryMyCertificates(ctx, shipOwnerId) {
        const myVesselsString = await this.queryMyVessels(ctx, shipOwnerId);
        const myVessels = JSON.parse(myVesselsString);
        const myVesselIds = myVessels.map(v => v.Key);

        const allCertificatesString = await this.queryAllCertificates(ctx);
        const allCertificates = JSON.parse(allCertificatesString);

        const myCertificates = allCertificates.filter(c => myVesselIds.includes(c.Record.vesselId));
        return JSON.stringify(myCertificates);
    }
}

module.exports = ShipCertifyContract;