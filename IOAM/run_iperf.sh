#!/bin/bash

sudo lxc-attach -n beta -- iperf3 -s
