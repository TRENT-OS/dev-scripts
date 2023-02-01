#!/bin/bash -uex

#
# Setup networking for NET_DEV
#
# show tables: iptables [-t nat] -L -v -n --line-numbers
#

# VM/Host NIC (virt-io)
NET_VM_NIC="enp0s3" # MAC 38:22:e2:46:9a:ad
NET_VM_SUBNET="192.168.56.0/24"

# HW NIC
NET_CORP_NIC="enp0s8" # MAC 08:00:27:63:63:c8
# inet 10.178.232.166/26 brd 10.178.232.191

# Genucard/USB
#NET_CORP_NIC="enx0050c4101f51" # MAC 00:50:c4:10:1f:51
# inet 10.78.202.6/23 brd 10.78.203.255

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

# Port forwarding must be enabled
#
# Show setting
#    sysctl -n net.ipv4.ip_forward
#
# Enable temporarily
#    cat /proc/sys/net/ipv4/ip_forward
#    echo 1 > /proc/sys/net/ipv4/ip_forward
# or
#    sysctl -w net.ipv4.ip_forward=1
#
# Enable permanently in /etc/sysctl.conf, enable "net.ipv4.ip_forward=1", then
# apply the settings running "sudo sysctl -p"
#
sysctl -w net.ipv4.ip_forward=1


# Allow traffic between NET_VM and NET_CORP for existing connections. The state
# RELATED is not really necessary.
iptables \
    -A FORWARD \
    -i ${NET_VM_NIC} \
    -o ${NET_CORP_NIC} \
    -m conntrack \
    --ctstate ESTABLISHED,RELATED \
    -j ACCEPT

iptables \
    -A FORWARD \
    -i ${NET_CORP_NIC} \
    -o ${NET_VM_NIC} \
    -m conntrack \
    --ctstate ESTABLISHED,RELATED \
    -j ACCEPT

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
    "10.78.172.34:7999@7999" # 7999 -> bitbucket.cc.ebs.corp:7999
    "10.178.232.167:5000@5000" # 5000 -> hc-docker.ac.ebs.corp:5000
)

for e in "${MY_PORT_MAPPING[@]}"; do

    DST_IP="${e%%:*}"
    e="${e#*:}"
    DST_PORT="${e%%@*}"
    MY_PORT="${e#*@}"

    # setup firewall rules, accept new TCP connections from NET_VM_NIC on
    # MY_PORT.
    iptables \
        -A FORWARD \
        -i ${NET_VM_NIC} \
        -p tcp \
        --dport ${MY_PORT} \
        --syn \
        -m conntrack \
        --ctstate NEW \
        -j ACCEPT

    # Change the packet to apply port forwarding. We take any packet arriving
    # from NET_VM and do not explicitly filter ("-d ${NET_VM_IP}") if
    # it's targeted for us.
    # Notes:
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
        -i ${NET_VM_NIC} \
        -p tcp \
        --dport ${MY_PORT} \
        -j DNAT \
        --to-destination ${DST_IP}:${DST_PORT}

    # We have to change the packet's source address also, so the server at
    # DST_IP will think the packet comes from us and responds to us. We change
    # the address then that the packet get sent back
    iptables \
        -t nat \
        -A POSTROUTING \
        -o ${NET_CORP_NIC} \
        -p tcp \
        --dport ${DST_PORT} \
        -d ${DST_IP} \
        -j MASQUERADE

done
