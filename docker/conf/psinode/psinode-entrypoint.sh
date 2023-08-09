#!/bin/bash

set -ae
export HOST_IP=$(ip route | awk "/default/ { print \$3 }")

/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

psinode "$@"
