#!/bin/bash

echo "Start Caddy"
/usr/bin/caddy run --config /home/user/app/Caddyfile --adapter caddyfile &

#ssh -o StrictHostKeyChecking=no -R nya:80:localhost:7860 tunne.link -p8043 &
autossh -M 0 -o "StrictHostKeyChecking=no" -R nya:80:localhost:7860 tunne.link -p8043 &

/app/.npm-global/bin/serve . -l 8080 &

echo "Starting VSCode Server..."
/app/openvscode-server/bin/openvscode-server --host 0.0.0.0 --port 7860 --without-connection-token "${@}" 
