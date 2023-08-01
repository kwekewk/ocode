#!/bin/bash

ssh -o StrictHostKeyChecking=no -R nya:80:localhost:8080 tunne.link -p8043 &

echo "Starting VSCode Server..."
/app/openvscode-server/bin/openvscode-server --host 0.0.0.0 --port 8080 --without-connection-token "${@}" 
