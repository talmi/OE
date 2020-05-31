#!/bin/bash

# This script produces the file loss_out.txt
# It presents the loss rate[%] as a function of the sampling ratio.

# Before running this script make sure that run_iperf.sh is running in a separate shell window. For further details see README.md.

# Note that the sampling ratio is directly correlated to the IOAM overhead - each IOAM-enabled packet has an 80 byte overhead (8 bytes of IOAM data per hop + 8 bytes of IOAM header + 4 bytes IPv6 extension header + 44 bytes IPv6 tunnel).

# ratio is the sampling ratio. For example, a sampling ratio of 128 means that 1 out of every 128 packets is encapsulated with IOAM.

ratio=(128 64 32 16 10 8 6 4 2 1)
iterations=10

sudo lxc-attach -n porthos -- bash -c "tc qdisc del dev h_porthos2 root"
sudo lxc-attach -n porthos -- bash -c "tc qdisc add dev h_porthos2 root tbf rate 1mbit burst 32kbit latency 100ms"

echo "SamplingRatio Loss[%]" > loss_out.txt

exec 2> /dev/null
sudo lxc-attach -n athos -- bash -c "./athos/ioam_unregister"
Loss=$(sudo lxc-attach -n alpha -- bash -c "iperf3 -6 -b 833000 -c db03::2 -u -l 298 -t10" | grep "0.00-10" | cut -d'(' -f 2 | cut -d'%' -f 1)
sleep 1
sudo lxc-attach -n athos -- bash -c "./athos/ioam_register 1"

echo 0 $Loss >> loss_out.txt

for ((i=0; i<iterations; i++))
do
    sudo lxc-attach -n athos -- bash -c "./athos/ioam_unregister"
    sudo lxc-attach -n athos -- bash -c "./athos/ioam_register ${ratio[i]}"
    Loss=$(sudo lxc-attach -n alpha -- bash -c "iperf3 -6 -b 833000 -c db03::2 -u -l 298 -t10" | grep "0.00-10" | cut -d'(' -f 2 | cut -d'%' -f 1)
    sleep 1
    
    echo ${ratio[i]} $Loss >> loss_out.txt
done

