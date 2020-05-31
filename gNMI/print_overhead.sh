#!/bin/bash

# This script is used by gnmi_impact.sh

period=$1
TestTime=20

sleep 1
Result=$(sudo tshark -i lo -a duration:20 2> /dev/null | grep Len | grep "50001 →" | awk '{print $7}' | awk '{ sum += $1 } END { print sum }')

Result=$(($Result*8/$TestTime))
echo $period $Result >> gnmi_out.txt

sudo kill -9 $(ps -aux | grep gnmi-cli | grep grpc | awk '{print $2}' | tr '\n' ' ') 2> /dev/null

