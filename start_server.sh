#!/bin/bash

echo "Starting VSCode Server..."
/app/openvscode-server/bin/openvscode-server --host 0.0.0.0 --port 7860 --without-connection-token "${@}" &

echo "Starting Code Tunnel..."
/usr/bin/code tunnel --accept-server-license-terms &

# Sleep for a long time to keep the container running
sleep infinity
