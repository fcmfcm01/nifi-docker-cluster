#!/bin/bash

# NiFi Cluster Backup Script
# This script creates a backup of the NiFi cluster configuration and data
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
echo -e "${GREEN}NiFi Cluster Backup Script${NC}"
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

# Create backup directory
backup_dir="nifi_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"
echo -e "${YELLOW}Creating backup in directory: $backup_dir${NC}"

# Backup docker-compose.yml and scripts
echo -e "${YELLOW}Backing up configuration files...${NC}"
cp docker-compose.yml "$backup_dir/"
cp -r scripts "$backup_dir/"
cp *.sh "$backup_dir/"

# Export flows from NiFi Registry
echo -e "${YELLOW}Exporting flows from NiFi Registry...${NC}"
mkdir -p "$backup_dir/flows"

# Use NiFi Toolkit to export flows
docker-compose exec -T nifi-toolkit /opt/nifi-toolkit/bin/cli.sh registry list-buckets -u http://nifi-registry:18080 > "$backup_dir/buckets.txt"

# Parse bucket IDs and export flows for each bucket
if [ -f "$backup_dir/buckets.txt" ]; then
    echo -e "${YELLOW}Found buckets, exporting flows...${NC}"
    
    # Extract bucket IDs and names
    grep -E "id: [a-f0-9-]+" "$backup_dir/buckets.txt" | while read -r line; do
        bucket_id=$(echo "$line" | awk '{print $2}')
        bucket_name=$(grep -A 1 "$bucket_id" "$backup_dir/buckets.txt" | grep "name:" | awk '{$1=""; print $0}' | xargs)
        
        echo -e "${YELLOW}Exporting flows from bucket: $bucket_name ($bucket_id)${NC}"
        
        # Create directory for this bucket
        mkdir -p "$backup_dir/flows/$bucket_id"
        
        # Export bucket info
        echo "Bucket Name: $bucket_name" > "$backup_dir/flows/$bucket_id/bucket_info.txt"
        echo "Bucket ID: $bucket_id" >> "$backup_dir/flows/$bucket_id/bucket_info.txt"
        
        # List flows in this bucket
        docker-compose exec -T nifi-toolkit /opt/nifi-toolkit/bin/cli.sh registry list-flows -u http://nifi-registry:18080 --bucketId "$bucket_id" > "$backup_dir/flows/$bucket_id/flows.txt"
        
        # Extract flow IDs and export each flow
        grep -E "id: [a-f0-9-]+" "$backup_dir/flows/$bucket_id/flows.txt" | while read -r flow_line; do
            flow_id=$(echo "$flow_line" | awk '{print $2}')
            flow_name=$(grep -A 1 "$flow_id" "$backup_dir/flows/$bucket_id/flows.txt" | grep "name:" | awk '{$1=""; print $0}' | xargs)
            
            echo -e "${YELLOW}Exporting flow: $flow_name ($flow_id)${NC}"
            
            # Export the latest version of the flow
            docker-compose exec -T nifi-toolkit /opt/nifi-toolkit/bin/cli.sh registry export-flow-version -u http://nifi-registry:18080 --flowId "$flow_id" --output "/tmp/$flow_id.json"
            
            # Copy the exported flow from the container to the backup directory
            docker cp "$(docker-compose ps -q nifi-toolkit):/tmp/$flow_id.json" "$backup_dir/flows/$bucket_id/$flow_id.json"
        done
    done
else
    echo -e "${YELLOW}No buckets found in NiFi Registry or unable to connect.${NC}"
fi

# Create a compressed archive of the backup
echo -e "${YELLOW}Creating compressed archive of the backup...${NC}"
tar -czf "${backup_dir}.tar.gz" "$backup_dir"

# Remove the uncompressed backup directory
rm -rf "$backup_dir"

echo -e "${GREEN}Backup completed successfully!${NC}"
echo -e "${GREEN}Backup file: ${backup_dir}.tar.gz${NC}"
echo -e "${YELLOW}To restore this backup, extract the archive and run the deploy script.${NC}"