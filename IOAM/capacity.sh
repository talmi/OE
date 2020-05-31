#!/bin/bash

# This script produces the file capacity_out.txt
# The output presents the loss rate (percentage) as a function of the user traffic rate.
#     The loss rate is measured for two cases: with and without IOAM. 
# Port 2 of the Porthos switch (which is the middle switch) is rate limited: 1 Mbps.

# Before running this script make sure that run_iperf.sh is running in a separate shell window. For further details see README.md.

# bw is in bps
bw=(1000 100000 300000 500000 650000 750000 830000 900000 1000000 1100000)
iterations=10

sudo lxc-attach -n porthos -- bash -c "tc qdisc del dev h_porthos2 root"
sudo lxc-attach -n porthos -- bash -c "tc qdisc add dev h_porthos2 root tbf rate 1mbit burst 32kbit latency 100ms"

echo "UserTrafficRate[bps] LossNoIoam[%] LossIoam[%]" > capacity_out.txt

exec 2> /dev/null


for ((i=0; i<iterations; i++))
do
    sudo lxc-attach -n athos -- bash -c "./athos/ioam_unregister"
    LossNoIoam=$(sudo lxc-attach -n alpha -- bash -c "iperf3 -6 -b ${bw[i]} -c db03::2 -u -l 298 -t10" | grep "0.00-10" | cut -d'(' -f 2 | cut -d'%' -f 1)
    sudo lxc-attach -n athos -- bash -c "./athos/ioam_register 1"
    LossIoam=$(sudo lxc-attach -n alpha -- bash -c "iperf3 -6 -b ${bw[i]} -c db03::2 -u -l 298 -t10" | grep "0.00-10" | cut -d'(' -f 2 | cut -d'%' -f 1)
    sleep 1
    
    echo ${bw[i]} $LossNoIoam $LossIoam  >> capacity_out.txt
done

