#!/bin/bash

nginx -t
service nginx start

echo "Starting VSCode Server..."
/app/openvscode-server/bin/openvscode-server --host 0.0.0.0 --port 7860 --without-connection-token "${@}" &

#/home/user/one-api/one-api --port 3000 --log-dir ./logs &
cd /usr/lib/node_modules/code-server/lib/vscode/ && npm i . --production --force
/usr/bin/code-server --bind-addr 0.0.0.0:8080 --auth none --proxy-domain cripp.link &

#echo "Starting Code Tunnel..."
#/usr/bin/code tunnel --accept-server-license-terms &

# Sleep for a long time to keep the container running
sleep infinity
