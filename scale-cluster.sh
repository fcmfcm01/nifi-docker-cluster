#!/bin/bash

# NiFi Cluster Scaling Script
# This script adds a new node to the NiFi cluster
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
echo -e "${GREEN}NiFi Cluster Scaling Script${NC}"
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

# Get the number of nodes to add
read -p "How many additional NiFi nodes do you want to add? " num_nodes

if ! [[ "$num_nodes" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error: Please enter a valid number.${NC}"
    exit 1
fi

if [ "$num_nodes" -eq 0 ]; then
    echo -e "${YELLOW}No nodes to add. Exiting.${NC}"
    exit 0
fi

# Check current number of nodes
current_nodes=$(grep -c "container_name: nifi-" docker-compose.yml)
echo -e "${YELLOW}Current number of NiFi nodes: $current_nodes${NC}"
echo -e "${YELLOW}Adding $num_nodes more nodes...${NC}"

# Create a temporary file for the new docker-compose.yml
temp_file=$(mktemp)

# Copy the existing docker-compose.yml to the temp file
cp docker-compose.yml "$temp_file"

# Add new nodes to the temp file
for ((i=1; i<=num_nodes; i++)); do
    node_num=$((current_nodes + i))
    port=$((8443 + node_num - 1))
    protocol_port=$((9990 + node_num))
    
    # Add the new node service definition
    cat >> "$temp_file" << EOF

  nifi-$node_num:
    image: apache/nifi:2.4.0
    container_name: nifi-$node_num
    restart: always
    ports:
      - "$port:8443"
    environment:
      - NIFI_WEB_HTTPS_PORT=8443
      - NIFI_CLUSTER_IS_NODE=true
      - NIFI_CLUSTER_NODE_PROTOCOL_PORT=$protocol_port
      - NIFI_ZK_CONNECT_STRING=zookeeper:2181
      - NIFI_ELECTION_MAX_WAIT=1 min
      - NIFI_SENSITIVE_PROPS_KEY=nifi-key
      - NIFI_SENSITIVE_PROPS_ALGORITHM=PBEWITHMD5AND256BITAES-CBC-OPENSSL
      - NIFI_SECURITY_USER_AUTHORIZER=managed-authorizer
      - NIFI_SECURITY_USER_LOGIN_IDENTITY_PROVIDER=single-user-provider
      - NIFI_SECURITY_IDENTITY_MAPPING_PATTERN_KERB=^(.*?)@(.*?)$
      - NIFI_SECURITY_IDENTITY_MAPPING_VALUE_KERB=\$1
      - NIFI_SECURITY_IDENTITY_MAPPING_TRANSFORM_KERB=NONE
      - NIFI_SECURITY_IDENTITY_MAPPING_PATTERN_DN=^CN=(.*?), OU=(.*?)$
      - NIFI_SECURITY_IDENTITY_MAPPING_VALUE_DN=\$1
      - NIFI_SECURITY_IDENTITY_MAPPING_TRANSFORM_DN=NONE
      - NIFI_SECURITY_IDENTITY_MAPPING_PATTERN_NONE=^(.*?)$
      - NIFI_SECURITY_IDENTITY_MAPPING_VALUE_NONE=\$1
      - NIFI_SECURITY_IDENTITY_MAPPING_TRANSFORM_NONE=NONE
      - NIFI_WEB_PROXY_HOST=
    volumes:
      - nifi_${node_num}_conf:/opt/nifi/nifi-current/conf
      - nifi_${node_num}_state:/opt/nifi/nifi-current/state
      - nifi_${node_num}_content_repository:/opt/nifi/nifi-current/content_repository
      - nifi_${node_num}_database_repository:/opt/nifi/nifi-current/database_repository
      - nifi_${node_num}_flowfile_repository:/opt/nifi/nifi-current/flowfile_repository
      - nifi_${node_num}_provenance_repository:/opt/nifi/nifi-current/provenance_repository
      - nifi_${node_num}_logs:/opt/nifi/nifi-current/logs
    networks:
      - nifi-net
    depends_on:
      - zookeeper
      - nifi-registry
EOF
    
    # Add the new volumes
    cat >> "$temp_file" << EOF
  nifi_${node_num}_conf:
  nifi_${node_num}_state:
  nifi_${node_num}_content_repository:
  nifi_${node_num}_database_repository:
  nifi_${node_num}_flowfile_repository:
  nifi_${node_num}_provenance_repository:
  nifi_${node_num}_logs:
EOF
done

# Replace the original docker-compose.yml with the new one
mv "$temp_file" docker-compose.yml

echo -e "${GREEN}Added $num_nodes new NiFi nodes to the configuration.${NC}"
echo -e "${YELLOW}Applying changes...${NC}"

# Restart the cluster with the new configuration
docker-compose up -d

echo -e "${GREEN}NiFi cluster has been scaled to $((current_nodes + num_nodes)) nodes.${NC}"
echo -e "${YELLOW}New nodes may take a few minutes to join the cluster.${NC}"
echo -e "${YELLOW}Check status with: ./check-status.sh${NC}"