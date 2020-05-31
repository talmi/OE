#!/bin/bash

# This script produces the output file gnmi_out.txt
# This output is the data rate impact [bps] as a function of the exporting period.

# the period is in milliseconds
period=(10000 6500 3000 2000 1000 300 100 30 10 3)
periods=10

echo "Period[ms] Impact[bps]" > gnmi_out.txt

exec 2> /dev/null

for ((i=0; i<periods; i++))
do
    ./print_overhead.sh ${period[i]} &
    util/gnmi-cli --grpc-addr localhost:50001 --interval ${period[i]} sub-sample /interfaces/interface[name=leaf1-eth3]/state/counters/in-unicast-pkts > /dev/null 2> /dev/null
done

