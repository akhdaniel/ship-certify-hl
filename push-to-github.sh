#!/bin/bash

echo "🚀 Pushing BKI Ship Certification System to GitHub..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if git is initialized
if [ ! -d ".git" ]; then
    print_status "Initializing git repository..."
    git init
    git branch -M main
fi

# Check if files are staged
if [ -z "$(git diff --cached --name-only)" ]; then
    print_status "Adding files to git..."
    git add .
fi

# Check if there's a commit
if [ -z "$(git log --oneline 2>/dev/null)" ]; then
    print_status "Creating initial commit..."
    git commit -m "$(cat <<'EOF'
Initial commit: Complete BKI Ship Certification System on Hyperledger Fabric

Features:
- Hyperledger Fabric network with 2 organizations (Authority & ShipOwner)
- JavaScript smart contract for ship certification business logic
- Express.js REST API server with Fabric SDK integration
- Vue.js frontend with role-based access control
- Complete business process: vessel registration, survey scheduling, findings management, certificate issuance
- Docker containerization and deployment scripts

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
fi

# Check if remote exists
if ! git remote get-url origin > /dev/null 2>&1; then
    print_status "Adding GitHub remote..."
    git remote add origin https://github.com/akhdaniel/ship-certify-hl.git
fi

print_warning "Before pushing, please create the repository on GitHub:"
echo ""
echo "1. Go to: https://github.com/akhdaniel"
echo "2. Click 'New repository'"
echo "3. Repository name: ship-certify-hl"
echo "4. Description: BKI Ship Certification System on Hyperledger Fabric"
echo "5. Make it Public"
echo "6. DON'T initialize with README"
echo "7. Click 'Create repository'"
echo ""

read -p "Press Enter after creating the repository on GitHub..."

print_status "Pushing to GitHub..."
if git push -u origin main; then
    print_status "✅ Successfully pushed to GitHub!"
    echo ""
    echo "🌐 Repository URL: https://github.com/akhdaniel/ship-certify-hl"
    echo ""
    echo "📋 Next steps:"
    echo "1. Clone: git clone https://github.com/akhdaniel/ship-certify-hl.git"
    echo "2. Setup: ./deploy.sh"
    echo "3. Access: http://localhost:8080"
else
    print_error "Failed to push to GitHub"
    echo ""
    echo "💡 Troubleshooting:"
    echo "1. Make sure the repository exists on GitHub"
    echo "2. Check your GitHub credentials"
    echo "3. Verify repository name: akhdaniel/ship-certify-hl"
    echo "4. Make sure you have push access to the repository"
fi