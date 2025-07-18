#!/bin/bash

# Check and restart network if needed
echo "Checking network status..."

# Check if containers are running
if ! docker ps | grep -q "orderer.bki.com"; then
    echo "Orderer is not running. Starting network..."
    ./network.sh down
    ./network.sh up
    ./network.sh createChannel
else
    echo "Network is running. Checking channel..."
    
    # Check if channel exists
    if [ ! -f "channel-artifacts/bkichannel.block" ]; then
        echo "Channel block not found. Creating channel..."
        ./network.sh createChannel
    else
        echo "Channel exists. Proceeding with chaincode deployment..."
    fi
fi

echo "Network is ready. Deploying chaincode..."
./network.sh deployCC 