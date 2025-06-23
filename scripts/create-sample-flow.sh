#!/bin/bash

# Script to create a sample flow in NiFi
# This script creates a simple data flow in NiFi using the NiFi API

NIFI_HOST=${1:-nifi-1}
NIFI_PORT=${2:-8443}
TOKEN=${3}

if [ -z "$TOKEN" ]; then
    echo "Access token is required"
    exit 1
fi

echo "Creating a sample flow in NiFi at $NIFI_HOST:$NIFI_PORT"

# Get the root process group ID
ROOT_PG_ID=$(/opt/nifi-toolkit/bin/cli.sh nifi get-root-id -u "https://$NIFI_HOST:$NIFI_PORT" --accessToken $TOKEN)
echo "Root process group ID: $ROOT_PG_ID"

# Create a new process group
echo "Creating a new process group..."
PG_ID=$(/opt/nifi-toolkit/bin/cli.sh nifi pg-create -u "https://$NIFI_HOST:$NIFI_PORT" --processGroupId $ROOT_PG_ID --processGroupName "Sample Flow" --accessToken $TOKEN | grep -oP '(?<=ID: ).*')
echo "Process group ID: $PG_ID"

# Create a GenerateFlowFile processor
echo "Creating a GenerateFlowFile processor..."
GFF_ID=$(/opt/nifi-toolkit/bin/cli.sh nifi create-processor -u "https://$NIFI_HOST:$NIFI_PORT" --processGroupId $PG_ID --processorType "org.apache.nifi.processors.standard.GenerateFlowFile" --processorName "Generate Test Data" --accessToken $TOKEN | grep -oP '(?<=ID: ).*')
echo "GenerateFlowFile processor ID: $GFF_ID"

# Set properties for the GenerateFlowFile processor
echo "Setting properties for the GenerateFlowFile processor..."
/opt/nifi-toolkit/bin/cli.sh nifi update-processor -u "https://$NIFI_HOST:$NIFI_PORT" --processorId $GFF_ID --processorProperty "File Size" "1 KB" --accessToken $TOKEN
/opt/nifi-toolkit/bin/cli.sh nifi update-processor -u "https://$NIFI_HOST:$NIFI_PORT" --processorId $GFF_ID --processorProperty "Batch Size" "1" --accessToken $TOKEN
/opt/nifi-toolkit/bin/cli.sh nifi update-processor -u "https://$NIFI_HOST:$NIFI_PORT" --processorId $GFF_ID --processorProperty "Data Format" "Text" --accessToken $TOKEN
/opt/nifi-toolkit/bin/cli.sh nifi update-processor -u "https://$NIFI_HOST:$NIFI_PORT" --processorId $GFF_ID --processorProperty "Unique FlowFiles" "true" --accessToken $TOKEN

# Create a LogAttribute processor
echo "Creating a LogAttribute processor..."
LA_ID=$(/opt/nifi-toolkit/bin/cli.sh nifi create-processor -u "https://$NIFI_HOST:$NIFI_PORT" --processGroupId $PG_ID --processorType "org.apache.nifi.processors.standard.LogAttribute" --processorName "Log Attributes" --accessToken $TOKEN | grep -oP '(?<=ID: ).*')
echo "LogAttribute processor ID: $LA_ID"

# Create a connection between the processors
echo "Creating a connection between processors..."
/opt/nifi-toolkit/bin/cli.sh nifi create-connection -u "https://$NIFI_HOST:$NIFI_PORT" --sourceId $GFF_ID --sourceGroupId $PG_ID --sourceType PROCESSOR --destinationId $LA_ID --destinationGroupId $PG_ID --destinationType PROCESSOR --relationshipName "success" --accessToken $TOKEN

# Start the processors
echo "Starting the processors..."
/opt/nifi-toolkit/bin/cli.sh nifi update-processor -u "https://$NIFI_HOST:$NIFI_PORT" --processorId $GFF_ID --processorState RUNNING --accessToken $TOKEN
/opt/nifi-toolkit/bin/cli.sh nifi update-processor -u "https://$NIFI_HOST:$NIFI_PORT" --processorId $LA_ID --processorState RUNNING --accessToken $TOKEN

echo "Sample flow created successfully!"
echo "You can now view the flow in the NiFi UI at https://localhost:8443/nifi"