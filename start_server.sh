#!/bin/bash

#nginx -t
#service nginx start

ssh -o StrictHostKeyChecking=no -R nya:80:localhost:8080 tunne.link -p8043 &

echo "Starting VSCode Server..."
#/app/openvscode-server/bin/openvscode-server --host 0.0.0.0 --port 8080 --without-connection-token "${@}" &


/app/code-server/bin/code-server --bind-addr 0.0.0.0:7860 --auth none --proxy-domain cripp.link &

#echo "Starting Code Tunnel..."
#/usr/bin/code tunnel --accept-server-license-terms &

# Sleep for a long time to keep the container running
sleep infinity
