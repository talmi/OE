#!/bin/bash

# This script produces ioam_out.txt
# The output file shows the impact [bps] of the measurement as a function of the sampling ratio.

# Before running this script make sure that (1) run_iperf.sh is running in a separate shell window. (2) run_tshark.sh is running in a separate shell window. For further details see README.md.

# Note that the sampling ratio is directly correlated to the IOAM overhead - each IOAM-enabled packet has an 80 byte overhead (8 bytes of IOAM data per hop + 8 bytes of IOAM header + 4 bytes IPv6 extension header + 44 bytes IPv6 tunnel).

# ratio is the sampling ratio. For example, a sampling ratio of 128 means that 1 out of every 128 packets is encapsulated with IOAM.

ratio=(1 2 8 32 64 128 512 1024 2048 4096)
iterations=10
TestTime=20

sudo lxc-attach -n alpha -- bash -c "iperf3 -6 -b 10000 -c db03::2 -u -l 298 -t2"

echo "SamplingRatio Impact[Byte]" > ioam_out.txt

exec 2> /dev/null
prev=$(cat tmp_tshark.txt | grep "db00::2" | grep "UDP" | grep -v "62,63" | awk '{print $1}' | awk '{ sum += $1 } END { print sum }')
sudo lxc-attach -n athos -- bash -c "./athos/ioam_unregister"
sudo lxc-attach -n alpha -- bash -c "iperf3 -6 -b 1000000 -c db03::2 -u -l 298 -t20"
sleep 1
current=$(cat tmp_tshark.txt | grep "db00::2" | grep "UDP" | grep -v "62,63" | awk '{print $1}' | awk '{ sum += $1 } END { print sum }')
unobserved=$(($current-$prev))
prev=$current
sudo lxc-attach -n athos -- bash -c "./athos/ioam_register 1"

for ((i=0; i<iterations; i++))
do
    sudo lxc-attach -n athos -- bash -c "./athos/ioam_unregister"
    sudo lxc-attach -n athos -- bash -c "./athos/ioam_register ${ratio[i]}"
    sudo lxc-attach -n alpha -- bash -c "iperf3 -6 -b 1000000 -c db03::2 -u -l 298 -t20"
    sleep 5
    current=$(cat tmp_tshark.txt | grep "db00::2" | grep "UDP" | grep -v "62,63" | awk '{print $1}' | awk '{ sum += $1 } END { print sum }')
    Result=$(($current-$prev-$unobserved))
    prev=$current
    Result=$(($Result*8/$TestTime))
    echo ${ratio[i]} $Result >> ioam_out.txt
done

