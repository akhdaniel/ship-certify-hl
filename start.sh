#!/bin/bash
export PATH=${PWD}/bin:$PATH


echo "Starting the BKI Ship Certification System..."

# Start the network
./network.sh up

# Wait for the network to be ready
echo "Waiting for network to be ready..."
sleep 30


# Wait for the orderer to be ready
echo "Waiting for orderer to be ready..."
retry_count=0
max_retries=10
until osnadmin channel list -o localhost:7053 --ca-file "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/ca.crt" --client-cert "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/server.crt" --client-key "${PWD}/organizations/ordererOrganizations/bki.com/orderers/orderer.bki.com/tls/server.key" > /dev/null 2>&1; do
  retry_count=$((retry_count+1))
  if [ $retry_count -gt $max_retries ]; then
    echo "Orderer not ready after $max_retries attempts, exiting."
    exit 1
  fi
  echo "Waiting for orderer to be ready... (attempt $retry_count)"
  sleep 5
done
echo "Orderer is ready."

# Create the channel
./network.sh createChannel

# Deploy the chaincode
./network.sh deployCC

echo "BKI Ship Certification System started successfully!"
