#!/bin/bash -e
# Creates some basic elements on an empty overcloud deployment (from tripleo-quickstart):
# m1.nano flavor, cirros image, public and private networks to match the other scripts

if [[ -e ~/overcloudrc ]]; then
    echo "Sourcing overcloud credentials"
    source ~/overcloudrc
else
    echo "Could not find any credentials file"
    exit 1
fi

CIRROS=/tmp/cirros.img

# Upload cirros
CIRROS_VER=0.4.0
curl -LS -o "${CIRROS}" http://download.cirros-cloud.net/${CIRROS_VER}/cirros-${CIRROS_VER}-x86_64-disk.img
openstack image create "cirros" \
  --file "${CIRROS}" \
  --disk-format qcow2 --container-format bare \
  --public

# Flavor
openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano

# Public network (direct access)
openstack network create "${PUB_NETWORK}" --share --external --provider-network-type flat --provider-physical-network datacentre
openstack subnet create public-subnet --network "${PUB_NETWORK}" --subnet-range 192.168.24.0/24 --gateway 192.168.24.1 --allocation-pool start=192.168.24.100,end=192.168.24.120 --no-dhcp

# Private network
openstack network create "${PRIV_NETWORK}" --provider-network-type vxlan
openstack subnet create private-subnet --network "${PRIV_NETWORK}" --subnet-range 172.24.4.0/24 --gateway 172.24.4.1 --dns-nameserver 8.8.8.8

# And link them both
openstack router create router1
openstack router set --external-gateway "${PUB_NETWORK}" router1
openstack router add subnet router1 private-subnet

# Cleanup
rm -f "${CIRROS}"
