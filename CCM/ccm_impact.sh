#!/bin/bash

# This script produces the output file ccm_out.txt.
# The output presents the impact [bps] as a function of the CCM period.

# period in milliseconds:
period=(10000 5000 2500 1000 500 250 100 33 3.33)
interval=(10000 10000 10000 1000 1000 1000 100 100 100)
flows=(1 2 4 1 2 4 1 3 30)
periods=9
TestTime=20

echo "Period[ms] Impact[bps]" > ccm_out.txt

exec 2> /dev/null

for ((i=0; i<periods; i++))
do
    for  ((j=0; j<${flows[i]}; j++))
    do
      timeout 40 ~/dot1ag-utils/src/dot1ag_ccd -i h1-eth0 -t ${interval[i]} -d testdomain -m 3 -a testing > /dev/null 2> /dev/null &
    done
    sleep 5
    Result=$(sudo tshark -i h1-eth0 -a duration:20 2> /dev/null | grep CFM | awk '{print $7}' | awk '{ sum += $1 } END { print sum }')
    Result=$(($Result*8/$TestTime))
    echo ${period[i]} $Result >> ccm_out.txt
    sleep 15
done

