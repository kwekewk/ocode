#!/bin/bash

#ssh -o StrictHostKeyChecking=no -R nya:80:localhost:7860 tunne.link -p8043 &
autossh -M 0 -o "StrictHostKeyChecking=no" -R nya:80:localhost:7860 tunne.link -p8043 &

/app/.npm-global/bin/serve . -l 8080 &

echo "Starting VSCode Server..."
/app/openvscode-server/bin/openvscode-server --host 0.0.0.0 --port 7860 --without-connection-token "${@}" &


# start tailscale
echo "Start tailscale"
mkdir -p /tmp/tailscale
/bin/tailscaled --tun=userspace-networking --outbound-http-proxy-listen=localhost:1055 --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
HOSTNAME=${SPACE_HOST#"https://"}
/bin/tailscale up --authkey ${TS_AUTHKEY} --hostname=${HOSTNAME} --accept-routes --accept-dns --ssh --accept-risk=all
echo "Tailscale started"
echo

echo "redirect 7860 -> backend through tailscale"
socat TCP4-LISTEN:7860,reuseaddr,fork PROXY:localhost:10.254.0.11:7860,proxyport=1055 &
socat TCP4-LISTEN:8080,reuseaddr,fork PROXY:localhost:10.254.0.11:8080,proxyport=1055 &

# Start caddy
echo "Start Caddy"
/usr/bin/caddy run --config /home/user/app/Caddyfile --adapter caddyfile
