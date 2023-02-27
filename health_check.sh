#!/bin/sh

# if any of the runit services are down, we're unhealthy
sv status /etc/service/* | grep -v ^run: && exit 1

# otherwise we're healthy
exit 0
