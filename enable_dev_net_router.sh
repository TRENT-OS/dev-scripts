#!/bin/bash -uex

#
# Setup networking for NET_DEV
#
# show tables: iptables [-t nat] -L -v -n --line-numbers
#


NET_CORP_NIC="enp0s31f6"
NET_CORP_SUBNET="10.178.232.128/26"
#NET_CORP_MY_IP="10.178.232.171"

NET_DEV_NIC="enx00e04c6beeae"
NET_DEV_SUBNET="192.168.17.0/24"
#NET_DEV_MY_IP="192.168.17.50"

#
# https://unix.stackexchange.com/questions/8518/how-to-get-my-own-ip-address-and-save-it-to-a-variable-in-a-shell-script
#
#NET_DEV_MY_IP=$(ip -4 -oneline addr show ${NET_DEV_NIC} | sed -n 's/.* inet \(.*\)\/.*/\1/p')
#NET_DEV_MY_IP=$(ip -4 -br addr | grep ${NET_DEV_NIC} | tr -s [:space:] | cut -d ' ' -f 3 | sed -n 's/\(.*\)\/.*/\1/p')
#NET_DEV_MY_IP=$(ip -4 -br addr show {NET_DEV_NIC} | awk '{print $3}'
#NET_DEV_MY_IP=$(ip -4 -br addr show {NET_DEV_NIC} | sed -rn 's/'"${NET_DEV_NIC}"'\s+UP\s+(.*)\/.*/\1/p')
#if [ -z "${NET_DEV_MY_IP}" ]; then
#    echo "could not get IP on '${NET_DEV_NIC}'"
#    exit 1
#fi
#echo "IP on ${NET_DEV_NIC}: ${NET_DEV_MY_IP}"
#map -sP ${NET_DEV_SUBNET}


# Allow all traffic from any IP in NET_DEV to NET_CORP, do not care about the
# protocol or connection state.
iptables \
    -A FORWARD \
    -i ${NET_DEV_NIC} \
    -s ${NET_DEV_SUBNET} \
    -o ${NET_CORP_NIC} \
    -j ACCEPT

# Allow traffic from NET_CORP to NET_DEV for existing connections
iptables \
    -A FORWARD \
    -i ${NET_CORP_NIC} \
    -o ${NET_DEV_NIC} \
    -m conntrack \
    --ctstate ESTABLISHED \
    -j ACCEPT

# Hide anything in NET_DEV via NAT from NET_CORP. In POSTROUTING we can filter
# on IPs only, because the source NIC information is no longer available.
iptables \
    -t nat \
    -A POSTROUTING \
    -o ${NET_CORP_NIC} \
    -s ${NET_DEV_SUBNET} \
    -j MASQUERADE

# Make specific services on machines in NET_DEV accessible from NET_CORP via
# port forwarding.
# There are two option here
# - DNAT:
#   - IP addresses must be known
#   - source remains visible on machines in NET_DEV
#   - requires routing to be set up properly and we are the gateway
# - MASQUERADING:
#   - IP addresses are detected automatically based on NIC
#   - source machines in NET_CORP are not seen in NET_DEV
#   - must be used if routing does not guarantee we get thr response packets.
# See also
# - https://www.netfilter.org/documentation/HOWTO/NAT-HOWTO-6.html
# - https://wiki.debian.org/de/Portweiterleitung
# - https://devstorage.eu/blog/linux-port-forwarding-mit-iptables/
# - https://www.digitalocean.com/community/tutorials/how-to-forward-ports-through-a-linux-gateway-with-iptables

MY_PORT_MAPPING=(
    # <proxy-port>@<ip_in_NET_DEV>:<port>
    "192.168.17.51:22@8022" # ssh to raspi3-b827ebb9c638 via our port 8022
    "192.168.17.52:22@8023" # ssh to rockpi4b-5adf19ff5e72 via our port 8023
)

for e in "${MY_PORT_MAPPING[@]}"; do

    DST_IP="${e%%:*}"
    e="${e#*:}"
    DST_PORT="${e%%@*}"
    MY_PORT="${e#*@}"

    # Change the packet to apply port forwarding. We take any packet arriving
    # from NET_CORP and do not explicitly filter ("-d ${NET_CORP_MY_IP}") if
    # it's targeted for us.
    # Notes:
    # - We have not changed the packet's source address. Thus, the server at
    #   DST_IP will see where the request came from and tries to respond to this
    #   address. As long as routing is set up with us as gateway, things will
    #   work as expected, as the response packet still comes back to us.
    # - Response packets are handled automatically because NAT rules and
    #   conntrack work together. Only the first packet of a connection is
    #   evaluated against the rules. Any decisions made for this packet will be
    #   applied to all subsequent packets in the connection without additional
    #   evaluation. Responses to packets of a NAT'ed connections will
    #   automatically have "reverse NAT" applied. Thus there is no need for an
    #   explicit SNAT rule in the POSTROUTING on the response path - this would
    #   actually be quite tricky as stateless rule, that's why conntrack exists.
    iptables \
        -t nat \
        -A PREROUTING \
        -i ${NET_CORP_NIC} \
        -p tcp \
        --dport ${MY_PORT} \
        -j DNAT \
        --to-destination ${DST_IP}:${DST_PORT}

    # setup firewall rules, accept new TCP connections from NET_CORP_NIC to
    # NET_DEV_NIC for DST_IP:DST_PORT. That the only specific thing we need,
    # becuase above we have created a general rule already for established
    # connection from NET_CORP to NET_DEV, they can pass.
    iptables \
        -A FORWARD \
        -i ${NET_CORP_NIC} \
        -o ${NET_DEV_NIC} \
        -d ${DST_IP} \
        -p tcp \
        --dport ${DST_PORT} \
        --syn \
        -m conntrack \
        --ctstate NEW \
        -j ACCEPT

done


# use transparent proxy
#   iptables -t nat -A PREROUTING -i enx00e04c6beeae -p tcp --dport 80 -j REDIRECT --to-port 3128
#   iptables -t nat -A PREROUTING -i enx00e04c6beeae -p tcp --dport 443 -j REDIRECT --to-port 3130
SQUID_PORT_MAPPING=(
    # <port>:<squid-port>
#    "80:3128"
#    "443:3130"
)

for e in "${SQUID_PORT_MAPPING[@]}"; do

    DST_PORT="${e%%:*}"
    SQUID_PORT="${e#*:}"

    iptables \
        -t nat \
        -A PREROUTING \
        -i ${NET_DEV_NIC} \
        -p tcp \
        --dport ${DST_PORT} \
        -j REDIRECT \
        --to-port ${SQUID_PORT}

done
