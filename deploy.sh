#!/bin/bash

echo "🚀 Deploying BKI Ship Certification System..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed or not accessible via 'docker compose'"
        exit 1
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed"
        exit 1
    fi
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root is not recommended"
    fi
    
    print_status "Prerequisites check passed ✅"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Install main dependencies
    npm install
    
    # Install chaincode dependencies
    print_status "Installing chaincode dependencies..."
    cd chaincode-javascript && npm install && cd ..
    
    # Install API server dependencies
    print_status "Installing API server dependencies..."
    cd api-server && npm install && cd ..
    
    # Install frontend dependencies
    print_status "Installing frontend dependencies..."
    cd frontend && npm install && cd ..
    
    print_status "Dependencies installed ✅"
}

# Setup Hyperledger Fabric network
setup_network() {
    print_status "Setting up Hyperledger Fabric network..."
    
    # Make network script executable
    chmod +x network.sh
    
    # Check if Fabric binaries exist
    if [ ! -d "bin" ]; then
        print_warning "Fabric binaries not found. Please install them first:"
        print_warning "curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.0 1.5.0"
        exit 1
    fi
    
    # Set PATH
    export PATH=${PWD}/bin:$PATH
    export FABRIC_CFG_PATH=${PWD}/configtx
    
    # Generate crypto materials if not exists
    if [ ! -d "organizations" ]; then
        print_status "Generating crypto materials..."
        ./network.sh generateCerts
    fi
    
    print_status "Network setup completed ✅"
}

# Start the network
start_network() {
    print_status "Starting Hyperledger Fabric network..."
    
    # Set environment variables
    export PATH=${PWD}/bin:$PATH
    export FABRIC_CFG_PATH=${PWD}/configtx
    
    # Stop any existing network
    docker compose down
    
    # Start the network
    docker compose up -d
    
    # Wait for containers to be ready
    print_status "Waiting for containers to be ready..."
    sleep 10
    
    # Check if containers are running
    if [ $(docker ps | grep -c "hyperledger\|peer\|orderer") -lt 3 ]; then
        print_error "Some containers failed to start"
        docker ps -a
        exit 1
    fi
    
    print_status "Network started ✅"
}

# Deploy chaincode
deploy_chaincode() {
    print_status "Deploying chaincode..."
    
    # Set environment variables
    export PATH=${PWD}/bin:$PATH
    export FABRIC_CFG_PATH=${PWD}
    
    # Create channel if not exists
    print_status "Creating channel..."
    ./network.sh createChannel
    
    # Deploy chaincode
    print_status "Installing and instantiating chaincode..."
    ./network.sh deployCC
    
    print_status "Chaincode deployed ✅"
}

# Start API server
start_api() {
    print_status "Starting API server..."
    
    cd api-server
    
    # Create .env if not exists
    if [ ! -f ".env" ]; then
        echo "PORT=3000" > .env
        echo "NODE_ENV=development" >> .env
        echo "FABRIC_LOGGING_SPEC=INFO" >> .env
    fi
    
    # Start API server in background
    npm start &
    API_PID=$!
    
    cd ..
    
    # Wait for API to be ready
    print_status "Waiting for API server to be ready..."
    sleep 5
    
    # Check if API is responding
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        print_status "API server started ✅"
    else
        print_error "API server failed to start"
        kill $API_PID 2>/dev/null
        exit 1
    fi
}

# Build and start frontend
start_frontend() {
    print_status "Building and starting frontend..."
    
    cd frontend
    
    # Build for production
    npm run build
    
    # Start development server
    npm run dev &
    FRONTEND_PID=$!
    
    cd ..
    
    # Wait for frontend to be ready
    print_status "Waiting for frontend to be ready..."
    sleep 5
    
    print_status "Frontend started ✅"
}

# Main deployment function
main() {
    print_status "Starting BKI Ship Certification System deployment..."
    
    # Run deployment steps
    check_prerequisites
    install_dependencies
    setup_network
    start_network
    deploy_chaincode
    start_api
    start_frontend
    
    print_status "🎉 Deployment completed successfully!"
    echo ""
    echo "🌐 Access the application:"
    echo "   Frontend: http://localhost:8080"
    echo "   API: http://localhost:3000"
    echo "   Health Check: http://localhost:3000/health"
    echo ""
    echo "📚 Documentation: README.md"
    echo ""
    echo "🛑 To stop the system:"
    echo "   docker compose down"
    echo "   pkill -f 'npm'"
    echo ""
}

# Handle script interruption
cleanup() {
    print_warning "Deployment interrupted. Cleaning up..."
    docker compose down
    pkill -f 'npm' 2>/dev/null
    exit 1
}

trap cleanup INT TERM

# Run main function
main