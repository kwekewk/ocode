#!/bin/bash

nginx -t
service nginx start

ssh -o StrictHostKeyChecking=no -R nya:80:localhost:8080 tunne.link -p3332 &

echo "Starting VSCode Server..."
/app/openvscode-server/bin/openvscode-server --host 0.0.0.0 --port 7860 --without-connection-token "${@}" &

#/home/user/one-api/one-api --port 3000 --log-dir ./logs &

/usr/bin/code-server --bind-addr 0.0.0.0:8080 --auth none --proxy-domain cripp.link &

#echo "Starting Code Tunnel..."
#/usr/bin/code tunnel --accept-server-license-terms &

# Sleep for a long time to keep the container running
sleep infinity
