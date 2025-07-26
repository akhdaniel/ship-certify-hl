'use strict';

const { Wallets } = require('fabric-network');
const fs = require('fs');
const path = require('path');

async function main() {
    try {
        const walletPath = path.join(__dirname, 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        const usersFilePath = path.join(__dirname, 'users.json');
        const users = JSON.parse(fs.readFileSync(usersFilePath, 'utf8'));

        const isContainer = fs.existsSync('/app/organizations');
        const basePath = isContainer ? '/app' : '/root/ship-certify-hl';

        // Enroll Admin
        const adminIdentity = await wallet.get('admin');
        if (!adminIdentity) {
            const adminCertPath = path.resolve(basePath, 'organizations/peerOrganizations/authority.bki.com/users/Admin@authority.bki.com/msp/signcerts/Admin@authority.bki.com-cert.pem');
            const adminKeyPath = path.resolve(basePath, 'organizations/peerOrganizations/authority.bki.com/users/Admin@authority.bki.com/msp/keystore');
            const adminKey = fs.readFileSync(path.join(adminKeyPath, fs.readdirSync(adminKeyPath)[0]), 'utf8');
            const adminCert = fs.readFileSync(adminCertPath, 'utf8');

            const adminX509Identity = {
                credentials: { certificate: adminCert, privateKey: adminKey },
                mspId: 'AuthorityMSP',
                type: 'X.509',
            };
            await wallet.put('admin', adminX509Identity);
            console.log('Successfully enrolled admin user and imported it into the wallet');
        }

        // Enroll other users
        for (const user of users) {
            const userId = user.shipOwnerId || user.username;
            const identity = await wallet.get(userId);
            if (identity) {
                console.log(`An identity for the user "${userId}" already exists in the wallet`);
                continue;
            }

            if (user.role === 'shipowner' || user.role === 'authority') {
                const org = user.role === 'authority' ? 'authority.bki.com' : 'shipowner.bki.com';
                const msp = user.role === 'authority' ? 'AuthorityMSP' : 'ShipOwnerMSP';

                const userCertPath = path.resolve(basePath, `organizations/peerOrganizations/${org}/users/${user.id}/msp/signcerts/${user.id}-cert.pem`);
                const userKeyPath = path.resolve(basePath, `organizations/peerOrganizations/${org}/users/${user.id}/msp/keystore`);
                
                if (!fs.existsSync(userCertPath) || !fs.existsSync(userKeyPath)) {
                    console.warn(`[WARN] Crypto materials not found for user ${userId}. Skipping enrollment.`);
                    continue;
                }
                
                const userKey = fs.readFileSync(path.join(userKeyPath, fs.readdirSync(userKeyPath)[0]), 'utf8');
                const userCert = fs.readFileSync(userCertPath, 'utf8');

                const userX509Identity = {
                    credentials: { certificate: userCert, privateKey: userKey },
                    mspId: msp,
                    type: 'X.509',
                };
                await wallet.put(userId, userX509Identity);
                console.log(`Successfully enrolled user "${userId}" (${user.role}) and imported it into the wallet`);
            }
        }

    } catch (error) {
        console.error(`Failed to enroll users: ${error}`);
        process.exit(1);
    }
}

main();
