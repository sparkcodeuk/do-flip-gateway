#!/bin/bash
# Force outbound traffic through the assigned floating IP

NET_INT="eth0"
CURL_TIMEOUT=3

echo -n "Setting floating IP as the default gateway: "

# Check there's a floating IP attached to this droplet
if [ "$(curl -s --connect-timeout $CURL_TIMEOUT http://169.254.169.254/metadata/v1/floating_ip/ipv4/active)" != "true" ]; then
	echo "Error: this droplet doesn't have a floating IP assigned to it."
	exit 1
fi

# Get the gateway IP for the floating IP
GATEWAY_IP=$(curl -s --connect-timeout $CURL_TIMEOUT http://169.254.169.254/metadata/v1/interfaces/public/0/anchor_ipv4/gateway)

if [ -z "$GATEWAY_IP" ]; then
	echo "Error: failed getting gateway IP for this droplet."
	exit 1
fi

# Check we haven't already got the floating IP as a default gateway
if [ ! -z $(ip route list 0/0|awk '{print $3}'|grep "$GATEWAY_IP") ]; then
	echo "Error: gateway IP already a default route."
	exit 1
fi

# Add the new route before we remove any
route add default gw $GATEWAY_IP $NET_INT

# Delete any other default gatways for this interface
ip route list 0/0 dev $NET_INT|awk '{print $3}'|grep -v "$GATEWAY_IP"|xargs -n1 -I{} route del default gw {}

echo "Done."
