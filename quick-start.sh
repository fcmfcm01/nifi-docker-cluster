#!/bin/bash

# NiFi Cluster Quick Start Script
# This script provides a quick start guide for using the NiFi cluster
# Version: 1.0

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
echo -e "${GREEN}NiFi Cluster Quick Start Guide${NC}"
echo -e "${GREEN}Version: 1.0${NC}"
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

# Check if the NiFi cluster is running
if ! docker-compose ps | grep -q "nifi-1"; then
    echo -e "${YELLOW}NiFi cluster is not running. Starting the cluster...${NC}"
    ./deploy-nifi.sh
else
    echo -e "${GREEN}NiFi cluster is already running.${NC}"
fi

# Display NiFi UI URL
echo -e "\n${BLUE}NiFi UI:${NC} https://localhost:8443/nifi"
echo -e "${BLUE}NiFi Registry:${NC} http://localhost:18080/nifi-registry"

# Display admin credentials
echo -e "\n${YELLOW}Retrieving admin credentials...${NC}"
ADMIN_CREDENTIALS=$(docker-compose exec -T nifi-1 grep -A 2 "Generated Username" /opt/nifi/nifi-current/logs/nifi-app.log | grep -oP '(?<=Generated Username \[).*(?=\])|(?<=Generated Password \[).*(?=\])')
ADMIN_USERNAME=$(echo "$ADMIN_CREDENTIALS" | head -1)
ADMIN_PASSWORD=$(echo "$ADMIN_CREDENTIALS" | tail -1)

if [ -n "$ADMIN_USERNAME" ] && [ -n "$ADMIN_PASSWORD" ]; then
    echo -e "${GREEN}Admin Username:${NC} $ADMIN_USERNAME"
    echo -e "${GREEN}Admin Password:${NC} $ADMIN_PASSWORD"
else
    echo -e "${YELLOW}Could not retrieve admin credentials from logs. Please check the logs manually:${NC}"
    echo -e "docker-compose exec nifi-1 cat /opt/nifi/nifi-current/logs/nifi-app.log | grep 'Generated Username'"
fi

# Display quick start guide
echo -e "\n${BLUE}Quick Start Guide:${NC}"
echo -e "1. Access the NiFi UI at https://localhost:8443/nifi"
echo -e "2. Log in with the admin credentials shown above"
echo -e "3. Create a new process group by dragging the Process Group icon to the canvas"
echo -e "4. Add processors by dragging the Processor icon to the canvas"
echo -e "5. Configure processors by right-clicking and selecting 'Configure'"
echo -e "6. Connect processors by dragging from one processor to another"
echo -e "7. Start processors by right-clicking and selecting 'Start'"

echo -e "\n${BLUE}Useful Commands:${NC}"
echo -e "- Check cluster status: ${YELLOW}./check-status.sh${NC}"
echo -e "- Stop the cluster: ${YELLOW}./stop-nifi.sh${NC}"
echo -e "- Backup the cluster: ${YELLOW}./backup-nifi.sh${NC}"
echo -e "- Scale the cluster: ${YELLOW}./scale-cluster.sh${NC}"

echo -e "\n${GREEN}Happy data flowing!${NC}"