#!/bin/bash

testFile=""
hostName=""
namespace=""

# Display prompt if not arguments passed
if [[ -z "$1" && -z "$2" && -z "$3" ]]
then
  read -p 'File to run: ' namespace
  read -p 'File to run: ' testFile
  read -p 'Host to attack: ' hostName
else
  namespace=$1
  testFile=$2
  hostName=$3
fi

# Confirmation
echo "Confirmation: file to run is: $testFile and the host: $hostName"

# Prepare Config map with new values
cat > config-map.yaml << EOF1
kind: ConfigMap
apiVersion: v1
metadata:
  name: host-url
  namespace: $namespace
data:
  ATTACKED_HOST: $hostName
EOF1

# Push it to cluster
cat config-map.yaml | oc apply -f -

# Clean after yourself
rm ./config-map.yaml

# Prepare Config map with new values
cat > config-map.yaml << EOF1
kind: ConfigMap
apiVersion: v1
metadata:
  name: script-file
  namespace: $namespace
data:
  locustfile.py: |
$(cat $testFile | sed 's/^/    /')
EOF1

# Push it to cluster
cat config-map.yaml | oc apply -f -

# Clean after yourself
rm ./config-map.yaml

# Update the environment variable to trigger a change
oc project $namespace
oc set env dc/locust-master --overwrite CONFIG_HASH=`date +%s%N`
oc set env dc/locust-slave --overwrite CONFIG_HASH=`date +%s%N`
