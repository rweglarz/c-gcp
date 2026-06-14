#!/bin/bash
set -o xtrace
mkdir -p /var/log/bird
touch /var/log/bird/bird.log
chown -R bird:bird /var/log/bird
# BIRD is (re)started by the per-boot vpn.sh once the xfrm tunnel exists.
