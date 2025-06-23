#!/bin/bash

# NiFi Cluster Shutdown Script
# This script stops and optionally cleans up the NiFi cluster
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
echo -e "${RED}NiFi Cluster Shutdown Script${NC}"
echo -e "${GREEN}Version: 1.0${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed.${NC}"
    exit 1
fi

# Ask if user wants to remove volumes
read -p "Do you want to remove all data volumes? (y/n): " remove_volumes

# Stop the NiFi cluster
echo -e "${YELLOW}Stopping NiFi cluster...${NC}"
docker-compose down

# Remove volumes if requested
if [[ "$remove_volumes" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Removing all data volumes...${NC}"
    docker volume rm $(docker volume ls -q | grep -E 'nifi_|zookeeper_') 2>/dev/null || true
    echo -e "${GREEN}All data volumes have been removed.${NC}"
else
    echo -e "${GREEN}Data volumes have been preserved.${NC}"
fi

echo -e "${GREEN}NiFi cluster has been stopped.${NC}"
echo ""
echo -e "${YELLOW}To restart the cluster, run: ./deploy-nifi.sh${NC}"