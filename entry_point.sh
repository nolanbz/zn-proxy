#!/bin/bash
die () {
  echo $@
  exit 1
}

# These are hard-coded ports in the config files and Dockerfile... change them there too if you change here
SQUID_PORT=5088
STUNNEL_PORT=8443

PROXY_USERNAME="${PROXY_USERNAME:-znprx}"
if [ -z "${PROXY_PASSWORD}" ]; then
  die "You must supply PROXY_PASSWORD env var. Make it secure!"
fi
if [ $( echo -n "${PROXY_PASSWORD}" | wc -c ) -lt 16 ]; then
  die "Minimum PROXY_PASSWORD length is 16 bytes"
fi

# Configure stunnel with password
echo "${PROXY_USERNAME}:${PROXY_PASSWORD}" > /etc/stunnel/psk.txt

# Configure squid with password
htpasswd -nb "${PROXY_USERNAME}" "${PROXY_PASSWORD}" > /etc/squid/passwords

# Set file permissions
chown root:proxy /etc/stunnel/psk.txt /etc/squid/passwords
chmod 640 /etc/stunnel/psk.txt /etc/squid/passwords

# Try to find our public IP
PUBIP=$(curl -s "https://api.zinc.io/whatsmyip")

# Output the connection strings that are now available
echo
echo "################################################################################################"
echo
echo "Proxy is starting. Ensure ports are open in all firewalls. Use the following connection strings:"
echo "socks5+stunnel://${PROXY_USERNAME}:${PROXY_PASSWORD}@${PUBIP}:${STUNNEL_PORT}"
echo "http://${PROXY_USERNAME}:${PROXY_PASSWORD}@${PUBIP}:${SQUID_PORT}"
echo
echo "################################################################################################"
echo
echo

# call runit to start services
exec runsvdir /etc/service
