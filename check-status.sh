#!/bin/bash

# NiFi Cluster Status Check Script
# This script checks the status of the NiFi cluster
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
echo -e "${GREEN}NiFi Cluster Status Check${NC}"
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

# Check if containers are running
echo -e "${YELLOW}Checking container status...${NC}"
docker-compose ps

# Check container resource usage
echo -e "\n${YELLOW}Checking container resource usage...${NC}"
docker stats --no-stream $(docker-compose ps -q)

# Check NiFi logs (last 10 lines)
echo -e "\n${YELLOW}Recent NiFi logs (nifi-1):${NC}"
docker-compose logs --tail=10 nifi-1

echo -e "\n${YELLOW}Recent NiFi logs (nifi-2):${NC}"
docker-compose logs --tail=10 nifi-2

# Check NiFi Registry logs (last 10 lines)
echo -e "\n${YELLOW}Recent NiFi Registry logs:${NC}"
docker-compose logs --tail=10 nifi-registry

# Check ZooKeeper logs (last 10 lines)
echo -e "\n${YELLOW}Recent ZooKeeper logs:${NC}"
docker-compose logs --tail=10 zookeeper

echo -e "\n${GREEN}Status check completed.${NC}"
echo -e "${YELLOW}For more detailed logs, use: docker-compose logs [service-name]${NC}"