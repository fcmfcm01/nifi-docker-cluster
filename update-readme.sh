#!/bin/bash

# Script to update the README.md file with the latest changes
# This script updates the README.md file with the latest changes
# Version: 1.0

set -e

# Color codes for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get the list of scripts
SCRIPTS=$(ls -1 *.sh | sort)

# Update the README.md file
cat > README.md << EOF
# NiFi Docker Cluster

This repository contains scripts and configuration files to deploy an Apache NiFi cluster using Docker.

## Components

The deployment includes the following components:

- **Apache NiFi (2.4.0)**: A powerful data processing and integration platform
- **Apache NiFi Registry**: A centralized storage for versioned flows
- **Apache NiFi Toolkit**: Command-line tools for NiFi administration
- **Bitnami ZooKeeper**: Coordination service for distributed applications

## Architecture

The deployment creates a NiFi cluster with the following architecture:

- 2 NiFi nodes in a cluster configuration
- 1 NiFi Registry instance for flow version control
- 1 ZooKeeper instance for cluster coordination
- 1 NiFi Toolkit container for administration tasks

## Prerequisites

- Docker Engine (version 19.03.0+)
- Docker Compose (version 1.27.0+)
- At least 4GB of RAM available for the containers
- At least 10GB of free disk space

## Quick Start

1. Clone this repository:
   \`\`\`bash
   git clone https://github.com/yourusername/nifi-docker-cluster.git
   cd nifi-docker-cluster
   \`\`\`

2. Make the scripts executable:
   \`\`\`bash
   chmod +x *.sh
   \`\`\`

3. Deploy the NiFi cluster:
   \`\`\`bash
   ./deploy-nifi.sh
   \`\`\`

4. Access the NiFi UI:
   - URL: https://localhost:8443/nifi
   - The initial admin credentials are automatically generated and can be found in the NiFi logs
   - You can view the logs with: \`docker-compose logs nifi-1\`

5. Access the NiFi Registry:
   - URL: http://localhost:18080/nifi-registry

6. To stop the cluster:
   \`\`\`bash
   ./stop-nifi.sh
   \`\`\`

## Available Scripts

The following scripts are available in this repository:

EOF

# Add each script to the README
for script in $SCRIPTS; do
    if grep -q "# This script" "$script"; then
        description=$(grep -m 1 "# This script" "$script" | sed 's/# This script //')
    else
        description="No description available"
    fi
    echo "- **$script**: $description" >> README.md
done

# Add the rest of the README
cat >> README.md << EOF

## Configuration

### Customizing the Deployment

You can customize the deployment by modifying the \`docker-compose.yml\` file or by creating a \`docker-compose.override.yml\` file with your specific configurations.

### Scaling the Cluster

To add more NiFi nodes to the cluster, use the \`scale-cluster.sh\` script or edit the \`docker-compose.yml\` file and add additional NiFi services following the pattern of the existing nodes.

### Persistent Storage

The deployment uses Docker volumes for persistent storage:

- NiFi configuration
- NiFi state
- Content repository
- Database repository
- FlowFile repository
- Provenance repository
- Logs
- NiFi Registry database and flow storage
- ZooKeeper data

## Administration

### NiFi Toolkit

The NiFi Toolkit container includes several scripts to help with administration tasks:

- \`get-access-token.sh\`: Get an access token for NiFi API calls
- \`setup-registry-client.sh\`: Configure NiFi to connect to NiFi Registry
- \`create-registry-bucket.sh\`: Create a bucket in NiFi Registry
- \`check-cluster-status.sh\`: Check the status of the NiFi cluster
- \`initialize-nifi.sh\`: Initialize the NiFi cluster (automatically run during deployment)
- \`create-sample-flow.sh\`: Create a sample flow in NiFi

### Accessing Logs

To view logs for any of the containers:

\`\`\`bash
docker-compose logs [service-name]
\`\`\`

Where \`[service-name]\` can be:
- \`nifi-1\`
- \`nifi-2\`
- \`nifi-registry\`
- \`zookeeper\`
- \`nifi-toolkit\`

### Backup and Restore

To backup your NiFi flows and configuration, use the \`backup-nifi.sh\` script.

## Troubleshooting

### Common Issues

1. **NiFi UI not accessible**:
   - Check if the containers are running: \`docker-compose ps\`
   - Check the logs for errors: \`docker-compose logs nifi-1\`
   - Ensure ports 8443 and 8444 are not in use by other applications

2. **Cluster nodes not connecting**:
   - Check ZooKeeper logs: \`docker-compose logs zookeeper\`
   - Verify network connectivity between containers

3. **Performance issues**:
   - Increase the memory allocated to Docker
   - Check resource usage with: \`docker stats\`

## References

- [Apache NiFi Documentation](https://nifi.apache.org/docs.html)
- [Apache NiFi Administration Guide](https://nifi.apache.org/nifi-docs/administration-guide.html)
- [Apache NiFi Toolkit Guide](https://nifi.apache.org/nifi-docs/toolkit-guide.html)
- [Apache NiFi Registry Documentation](https://nifi.apache.org/nifi-registry-docs/index.html)

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.
EOF

echo -e "${GREEN}README.md has been updated successfully.${NC}"