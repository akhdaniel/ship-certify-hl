#!/bin/bash

# BKI Ship Certification System - Public IP Deployment Script
# This script configures the system to run on a public IP address

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get public IP
get_public_ip() {
    if command -v curl &> /dev/null; then
        PUBLIC_IP=$(curl -s https://ipinfo.io/ip)
    elif command -v wget &> /dev/null; then
        PUBLIC_IP=$(wget -qO- https://ipinfo.io/ip)
    else
        print_warning "Could not automatically detect public IP. Please enter it manually:"
        read -p "Enter your public IP address: " PUBLIC_IP
    fi
    echo $PUBLIC_IP
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install Node.js first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Configure environment for public IP
configure_environment() {
    print_status "Configuring environment for public IP deployment..."
    
    PUBLIC_IP=$(get_public_ip)
    print_status "Detected public IP: $PUBLIC_IP"
    
    # Create API server environment file
    cat > api-server/.env << EOF
# API Server Configuration for Public IP
PORT=3000
HOST=0.0.0.0
NODE_ENV=production

# JWT Configuration
JWT_SECRET=bki-ship-certify-$(date +%s)-$(openssl rand -hex 16)

# Fabric Network Configuration
FABRIC_LOGGING_SPEC=INFO

# CORS Configuration for public access
CORS_ORIGIN=*
EOF
    
    # Create frontend environment file
    cat > frontend/.env << EOF
# Frontend Configuration for Public IP
VITE_API_URL=http://$PUBLIC_IP:3000

# Development Configuration
VITE_DEV_SERVER_HOST=0.0.0.0
VITE_DEV_SERVER_PORT=8080
EOF
    
    print_success "Environment files created"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Install API server dependencies
    cd api-server
    npm install
    cd ..
    
    # Install frontend dependencies
    cd frontend
    npm install
    cd ..
    
    print_success "Dependencies installed"
}

# Setup and start Fabric network
setup_network() {
    print_status "Setting up Fabric network..."
    
    # Generate certificates if not exists
    if [ ! -d "organizations/peerOrganizations" ]; then
        print_status "Generating certificates..."
        ./network.sh generateCerts
    fi
    
    # Start network
    print_status "Starting Fabric network..."
    ./network.sh up
    
    # Create channel
    print_status "Creating channel..."
    ./network.sh createChannel
    
    # Deploy chaincode
    print_status "Deploying chaincode..."
    ./network.sh deployCC
    
    print_success "Fabric network setup completed"
}

# Start API server
start_api() {
    print_status "Starting API server..."
    
    cd api-server
    
    # Start API server in background
    npm start &
    API_PID=$!
    
    cd ..
    
    # Wait for API to be ready
    print_status "Waiting for API server to be ready..."
    sleep 10
    
    # Check if API is responding
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        print_success "API server started"
    else
        print_error "API server failed to start"
        kill $API_PID 2>/dev/null
        exit 1
    fi
}

# Start frontend
start_frontend() {
    print_status "Starting frontend..."
    
    cd frontend
    
    # Build for production
    print_status "Building frontend for production..."
    npm run build
    
    # Start development server (for demo purposes)
    # In production, you should serve the built files with a proper web server
    npm run dev &
    FRONTEND_PID=$!
    
    cd ..
    
    # Wait for frontend to be ready
    print_status "Waiting for frontend to be ready..."
    sleep 5
    
    print_success "Frontend started"
}

# Display access information
show_access_info() {
    PUBLIC_IP=$(get_public_ip)
    
    echo ""
    print_success "🎉 BKI Ship Certification System deployed successfully!"
    echo ""
    echo "🌐 Access Information:"
    echo "   Frontend: http://$PUBLIC_IP:8080"
    echo "   API Server: http://$PUBLIC_IP:3000"
    echo "   Health Check: http://$PUBLIC_IP:3000/health"
    echo ""
    echo "🔧 Configuration Files:"
    echo "   API Server: api-server/.env"
    echo "   Frontend: frontend/.env"
    echo ""
    echo "⚠️  Security Notes:"
    echo "   - Change JWT_SECRET in api-server/.env for production"
    echo "   - Configure firewall to allow ports 3000 and 8080"
    echo "   - Use HTTPS in production environment"
    echo ""
    echo "🛑 To stop the system:"
    echo "   docker compose down"
    echo "   pkill -f 'npm'"
    echo ""
}

# Main deployment function
main() {
    print_status "Starting BKI Ship Certification System public IP deployment..."
    
    # Run deployment steps
    check_prerequisites
    configure_environment
    install_dependencies
    setup_network
    start_api
    start_frontend
    show_access_info
}

# Handle script interruption
trap 'print_error "Deployment interrupted"; exit 1' INT TERM

# Run main function
main "$@" 