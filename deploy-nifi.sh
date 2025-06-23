#!/bin/bash

# NiFi Cluster Deployment Script
# This script sets up and deploys a NiFi cluster using Docker
# Version: 1.0
# Based on NiFi 2.4.0

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}"
echo "  _   _ _  __ _    ____ _           _            "
echo " | \ | (_)/ _(_)  / ___| |_   _ ___| |_ ___ _ __ "
echo " |  \| | | |_| | | |   | | | | / __| __/ _ \ '__|"
echo " | |\  | |  _| | | |___| | |_| \__ \ ||  __/ |   "
echo " |_| \_|_|_| |_|  \____|_|\__,_|___/\__\___|_|   "
echo "                                                  "
echo -e "${NC}"
echo -e "${GREEN}NiFi Cluster Deployment Script${NC}"
echo -e "${GREEN}Version: 1.0${NC}"
echo -e "${GREEN}NiFi Version: 2.4.0${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed. Please install Docker before running this script.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed. Please install Docker Compose before running this script.${NC}"
    exit 1
fi

# Create necessary directories
echo -e "${YELLOW}Creating necessary directories...${NC}"
mkdir -p config/nifi
mkdir -p config/nifi-registry
mkdir -p scripts

# Create toolkit scripts
echo -e "${YELLOW}Creating toolkit scripts...${NC}"

# Create script to get access token
cat > scripts/get-access-token.sh << 'EOF'
#!/bin/bash
# Script to get access token from NiFi

NIFI_HOST=${1:-nifi-1}
NIFI_PORT=${2:-8443}
USERNAME=${3:-admin}
PASSWORD=${4:-adminpassword}

echo "Getting access token from $NIFI_HOST:$NIFI_PORT with username $USERNAME"
/opt/nifi-toolkit/bin/cli.sh nifi get-access-token -u "https://$NIFI_HOST:$NIFI_PORT" --username $USERNAME --password $PASSWORD -v
EOF
chmod +x scripts/get-access-token.sh

# Create script to setup NiFi Registry client
cat > scripts/setup-registry-client.sh << 'EOF'
#!/bin/bash
# Script to setup NiFi Registry client

NIFI_HOST=${1:-nifi-1}
NIFI_PORT=${2:-8443}
REGISTRY_HOST=${3:-nifi-registry}
REGISTRY_PORT=${4:-18080}
TOKEN=${5}

if [ -z "$TOKEN" ]; then
    echo "Access token is required"
    exit 1
fi

echo "Setting up NiFi Registry client on $NIFI_HOST:$NIFI_PORT pointing to $REGISTRY_HOST:$REGISTRY_PORT"
/opt/nifi-toolkit/bin/cli.sh nifi create-reg-client -u "https://$NIFI_HOST:$NIFI_PORT" \
    --registryClientName "NiFi Registry" \
    --registryClientUrl "http://$REGISTRY_HOST:$REGISTRY_PORT" \
    --accessToken $TOKEN
EOF
chmod +x scripts/setup-registry-client.sh

# Create script to create a bucket in NiFi Registry
cat > scripts/create-registry-bucket.sh << 'EOF'
#!/bin/bash
# Script to create a bucket in NiFi Registry

REGISTRY_HOST=${1:-nifi-registry}
REGISTRY_PORT=${2:-18080}
BUCKET_NAME=${3:-"My Bucket"}

echo "Creating bucket '$BUCKET_NAME' in NiFi Registry at $REGISTRY_HOST:$REGISTRY_PORT"
/opt/nifi-toolkit/bin/cli.sh registry create-bucket -u "http://$REGISTRY_HOST:$REGISTRY_PORT" --bucketName "$BUCKET_NAME"
EOF
chmod +x scripts/create-registry-bucket.sh

# Create script to check cluster status
cat > scripts/check-cluster-status.sh << 'EOF'
#!/bin/bash
# Script to check NiFi cluster status

NIFI_HOST=${1:-nifi-1}
NIFI_PORT=${2:-8443}
TOKEN=${3}

if [ -z "$TOKEN" ]; then
    echo "Access token is required"
    exit 1
fi

echo "Checking cluster status on $NIFI_HOST:$NIFI_PORT"
/opt/nifi-toolkit/bin/cli.sh nifi cluster-summary -u "https://$NIFI_HOST:$NIFI_PORT" --accessToken $TOKEN
EOF
chmod +x scripts/check-cluster-status.sh

# Create initialization script
cat > scripts/initialize-nifi.sh << 'EOF'
#!/bin/bash
# Script to initialize NiFi cluster

# Wait for NiFi to be available
echo "Waiting for NiFi to be available..."
until curl -k -s https://nifi-1:8443/nifi-api/system-diagnostics > /dev/null; do
    echo "NiFi not yet available, waiting..."
    sleep 10
done

echo "NiFi is available, proceeding with initialization..."

# Get the initial admin credentials from logs
ADMIN_CREDENTIALS=$(grep -A 2 "Generated Username" /opt/nifi/nifi-current/logs/nifi-app.log | grep -oP '(?<=Generated Username \[).*(?=\])|(?<=Generated Password \[).*(?=\])')
ADMIN_USERNAME=$(echo "$ADMIN_CREDENTIALS" | head -1)
ADMIN_PASSWORD=$(echo "$ADMIN_CREDENTIALS" | tail -1)

echo "Retrieved admin credentials: Username=$ADMIN_USERNAME"

# Get access token
TOKEN=$(/scripts/get-access-token.sh nifi-1 8443 "$ADMIN_USERNAME" "$ADMIN_PASSWORD")
echo "Access token: $TOKEN"

# Setup NiFi Registry client
/scripts/setup-registry-client.sh nifi-1 8443 nifi-registry 18080 "$TOKEN"

# Create a bucket in NiFi Registry
/scripts/create-registry-bucket.sh nifi-registry 18080 "Production Flows"

# Check cluster status
/scripts/check-cluster-status.sh nifi-1 8443 "$TOKEN"

echo "NiFi cluster initialization completed successfully!"
EOF
chmod +x scripts/initialize-nifi.sh

# Create docker-compose override file for custom configurations
cat > docker-compose.override.yml << 'EOF'
version: '3.8'

# This file can be used to override settings in docker-compose.yml
# Uncomment and modify sections as needed

#services:
#  nifi-1:
#    environment:
#      - NIFI_WEB_PROXY_HOST=your-domain.com:8443
#
#  nifi-2:
#    environment:
#      - NIFI_WEB_PROXY_HOST=your-domain.com:8444
EOF

# Start the NiFi cluster
echo -e "${YELLOW}Starting NiFi cluster...${NC}"
docker-compose up -d

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
echo "This may take a few minutes..."
sleep 30

# Run initialization script in the toolkit container
echo -e "${YELLOW}Initializing NiFi cluster...${NC}"
docker-compose exec nifi-toolkit /scripts/initialize-nifi.sh

echo -e "${GREEN}NiFi cluster deployment completed!${NC}"
echo ""
echo -e "${BLUE}Access NiFi UI:${NC} https://localhost:8443/nifi"
echo -e "${BLUE}Access NiFi Registry:${NC} http://localhost:18080/nifi-registry"
echo ""
echo -e "${YELLOW}Note: It may take a few minutes for all services to fully initialize.${NC}"
echo -e "${YELLOW}Check logs with: docker-compose logs -f${NC}"
echo ""
echo -e "${GREEN}Happy data flowing!${NC}"