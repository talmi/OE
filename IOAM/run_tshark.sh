#!/bin/bash

sudo lxc-attach -n aramis -- bash -c "sudo tshark -l -i h_aramis1 -T fields -e frame.len -e ipv6.hlim -e ipv6.hopopts -e ipv6.src -e _ws.col.Protocol > tmp_tshark.txt"
