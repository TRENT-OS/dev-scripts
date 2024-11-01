#!/bin/bash -uex

#-------------------------------------------------------------------------------
#
# Copyright (C) 2021-2024, HENSOLDT Cyber GmbH
# 
# SPDX-License-Identifier: GPL-2.0-or-later
#
# For commercial licensing, contact: info.cyber@hensoldt.net
#
# TAP device creation script
#
#-------------------------------------------------------------------------------

BRIDGE_NAME=br0
TAP_INTERFACES=(tap0 tap1)

# physical network interface to connect to bridge
# NOTE: PLEASE ADOPT TO YOU SYSTEM
NETWORK_INTERFACE_NAME=enp0s31f6
#NETWORK_INTERFACE_NAME=enp0s25

# MAC of the bridge, will use the MAC of the physical network interface by
# default, since this is good enough for most cases
BRIDGE_MAC=$(ip -br link show ${NETWORK_INTERFACE_NAME} | awk '{print $3}')


#-------------------------------------------------------------------------------
function restart_dhcp_client()
{
    local INTERFACE=$1
    # kill any dhclient already running and start the daemon again for the
    # interface
    if [ -n "$(pidof dhclient)" ]; then
        kill -9 $(pidof dhclient)
    fi
    dhclient -v ${INTERFACE}
}


#-------------------------------------------------------------------------------
function create_bridge()
{
    # create the bridge
    ip link add ${BRIDGE_NAME} type bridge
    ip link set ${BRIDGE_NAME} address ${BRIDGE_MAC}

    # add TAP devices to bridge
    for TAP in "${TAP_INTERFACES[@]}"; do
        ip tuntap add ${TAP} mode tap
        ip link set ${TAP} master ${BRIDGE_NAME}
    done

    # add host network interface to bridge
    ip link set dev ${NETWORK_INTERFACE_NAME} down
    ip addr flush dev ${NETWORK_INTERFACE_NAME}
    ip link set ${NETWORK_INTERFACE_NAME} master ${BRIDGE_NAME}

    # activate the bridge and the devices connected to it
    ip link set dev ${BRIDGE_NAME} up
    for TAP in "${TAP_INTERFACES[@]}"; do
        ip link set ${TAP} up
    done
    ip link set dev ${NETWORK_INTERFACE_NAME} up

    # the default policy is DROP on many system, change this to FORWARD
    for TAP in "${TAP_INTERFACES[@]}"; do
        iptables -A INPUT -i ${TAP} -j ACCEPT
    done

    iptables -A INPUT -i ${BRIDGE_NAME} -j ACCEPT
    iptables -A FORWARD -i ${BRIDGE_NAME} -j ACCEPT

    restart_dhcp_client ${BRIDGE_NAME}
}


#-------------------------------------------------------------------------------
function remove_bridge()
{
    for TAP in "${TAP_INTERFACES[@]}"; do
        ip tuntap del dev ${TAP} mode tap
    done

    ip link set dev ${NETWORK_INTERFACE_NAME} down

    ip link delete ${BRIDGE_NAME}

    ip link set dev ${NETWORK_INTERFACE_NAME} up

    restart_dhcp_client ${NETWORK_INTERFACE_NAME}
}


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

MODE=${1:-}
echo "MODE=${MODE}"
shift
case "${MODE}" in
   create)
        create_bridge $@
        ;;
   remove)
        remove_bridge $@
        ;;
   *)
        echo "use parameter 'create' or 'remove'"
        ;;
esac
