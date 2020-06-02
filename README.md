# Overview

This repository includes a description and code for performing a few experiments that evaluate the performance of three significantly different measurement methods: (1) passive measurement with gNMI-based exporting, (2) active measurement using Continuity Check Messages (CCM), and (3) In situ OAM (IOAM).

Further details about each of the evaluation environments is presented below. The relevant files can be found in the respective folders (gNMI, CCM, IOAM).


# gNMI Experiment

## Background

This experiment uses the Stratum/BMv2 switch in a Mininet environment. gNMI is used for periodically exporting counter values.

The following topology is emulated in Mininet:

               ^
               |gNMI
+------+   +---+---+   +------+
| h1a  |---|Stratum|---| h1b  |
|(host)|   |switch |   |(host)|
+------+   +-------+   +------+

Data traffic is forwarded between the hosts h1a and h1b, while the Stratum switch counters are exported using gNMI to the localhost (which is logically external to the Mininet topology). The overhead of the gNMI exported information is measured and analyzed as a function of the exporting period.


## Setting up the environment

The simplest way to set up the environment is to use the NG-SDN tutorial as a baseline:

https://github.com/opennetworkinglab/ngsdn-tutorial

The tutorial page includes a downloadable VM that has a pre-installed environment with the Stratum switch in Mininet running over Ubuntu 18.04. Once the VM has been downloaded, copy the two (*.sh) files from the 'gNMI' folder in the current repository to the 'ngsdn-tutorial' folder in the VM.

Note that the Mininet topology in the tutorial includes some additional nodes beyond the nodes in the figure above, however they are not used in this experiment.

Install Tshark:

```
sudo apt-get install tshark
```

### Starting Mininet and verifying connectivity

It is possible to follow the instructions of Exercise-1 in the ngsdn-tutorial repository for starting the mininet topology and setting up basic connectivity between hosts h1a and h1b. 
These steps are described here for simplicity. If at some point one of the steps fails it is advised to refer to the tutorial.

Open a shell window and type:

```
cd ~/ngsdn-tutorial
make start
make mn-cli
```

Once the Mininet CLI has been started, type:
```
h1a ip -6 neigh replace 2001:1:1::B lladdr 00:00:00:00:00:1B dev h1a-eth0
h1b ip -6 neigh replace 2001:1:1::A lladdr 00:00:00:00:00:1A dev h1b-eth0
```

In a separate shell window, type:
```
cd ~/ngsdn-tutorial
util/p4rt-sh --grpc-addr localhost:50001 --config p4src/build/p4info.txt,p4src/build/bmv2.json --election-id 0,1
```

Once the P4runtime shell starts, type the following commands, one by one:
```
te = table_entry["IngressPipeImpl.l2_exact_table"](action = "IngressPipeImpl.set_egress_port")
te.match["hdr.ethernet.dst_addr"] = ("00:00:00:00:00:1B")
te.action['port_num'] = ("4")
te.insert()
te = table_entry["IngressPipeImpl.l2_exact_table"](action = "IngressPipeImpl.set_egress_port")
te.match["hdr.ethernet.dst_addr"] = ("00:00:00:00:00:1A")
te.action['port_num'] = ("3")
te.insert()
```

If everything goes well, ping should now work from the Mininet CLI:
```
h1a ping h1b
```

Keep the ping running and proceed to the experiment.


### Running the experiment

In a separate shell window, run:

```
cd ~/ngsdn-tutorial
./gnmi_impact.sh
```

This script runs the experiment and produces the file gnmi_out.txt. This output is the data rate impact [bps] as a function of the exporting period.


# CCM Experiment

## Background

This experiment uses an open source implementation of IEEE 802.1ag, running Continuity Check Messages (CCM). This was tested on Ubuntu 18.04, but should work on other version of Ubuntu as well.

The experiment uses the default Mininet topology, where two hosts are connected through a switch.

+------+   +------+   +------+
|  h1  |---|switch|---|  h2  |
|(host)|   |      |   |(host)|
+------+   +------+   +------+

The host h1 periodically sends CCMs, and this experiment measures the data rate impact of the CCMs.


## Setting up the environment

Start by installing Mininet, by following the instructions on:

http://mininet.org/download/

Download the dot1ag-utils repository:

```
git clone https://github.com/vnrick/dot1ag-utils.git
```

Copy the file dot1ag_ccd.c from the CCM folder in the current repository to ~/dot1ag-utils/src, overwriting the existing file. The reason for this modification is that there is a bug in the original dot1ag_ccd.c which affects the CCM transmission in an interval that is less than one second (bug in the wraparound of the seconds value).

Copy the file ccm_impact.sh from the CCM folder in the current repository to ~/dot1ag-utils.

Install dot1ag-utils according to the installation instructions in ~/dot1ag-utils/INSTALLATION.

Install Iperf and Tshark:

```
sudo apt-get install iperf tshark
```


## Running the experiment

Run Mininet using the default topology:
```
sudo mn
```

Verify connectivity from the Mininet CLI:
```
h1 ping h2
```

From the Mininet CLI run the experiment:
```
h1 cd ~/dot1ag-utils
h1 ./ccm_impact.sh
```

This script produces the output file ccm_out.txt. The output presents the impact [bps] as a function of the CCM period.


# IOAM Experiment

## Background

The experiment uses the IOAM setup of https://github.com/IurmanJ/kernel_ipv6_ioam

Specifically, five Linux Containers (LXC) are used to emulate two hosts and three switches.

+------+   +------+   +-------+   +-------+   +------+
|Alpha |---|Athos |---|Porthos|---|Aramis |---| Beta |
|(host)|   |      |   |       |   |       |   |(host)|
+------+   +------+   +-------+   +-------+   +------+
            IOAM         IOAM      IOAM
        encapsulating   transit    decapsulating
            switch      switch     switch
			
In the experiment traffic is sent between Alpha and Beta using Iperf. The traffic is IPv6 UDP packets with a constant length of 360 bytes (including the L2 and L3 headers) - which fits the mean packet length in IMIX. The IOAM encapsulation is pushed by Athos, and each of the switches (Athos, Porthos, Aramis) pushes its own IOAM data onto packets. Finally, Aramis removes the IOAM encapsulation. Various experiments can be run using the scripts in the IOAM folder. The experiments compare the performance (data rate and loss rate) with and without OAM, and for various IOAM sampling ratio values (the sampling ratio determines the fraction of data traffic that is encapsulated with IOAM).
			
			
## Setting up the environment

In order to install IOAM on an Ubuntu 16.04 machine, follow the installation instructions on:

https://github.com/IurmanJ/kernel_ipv6_ioam

Specifically, make sure you complete the instructions on the 'Patching the kernel' and 'LXC Topology' sections on that page. After this is completed, you should have a folder named ~/kernel_ipv6_ioam/lxc which includes the relevant files for running IOAM. Once these two steps are completed, follow the following steps:

Copy the ioam_register.c file from the IOAM folder in the current repository to the following folder: ~/kernel_ipv6_ioam/lxc/athos, overwriting the existing file.
Copy all the rest of the files from the IOAM folder in the current repository to the following folder: ~/kernel_ipv6_ioam/lxc. Note that the file start.sh is overwritten.
The modifications above in ioam_register.c and start.sh enable to easily configure the sampling ratio of IOAM (the sampling ratio is the fraction of packets that are processed by IOAM).
For each of the three switch nodes (Athos, Porthos, Aramis), perform the following:

```
cd lxc/<node>/
gcc ioam_register.c -o ioam_register
gcc ioam_unregister.c -o ioam_unregister
```

Install Iperf and Tshark:

```
sudo apt-get install iperf tshark
```

Start the topology
```
cd lxc/
./start.sh
```

Verify the connectivity by:

```
sudo lxc-attach -n alpha
ping6 db03::2
```


## Running the experiments

Before starting any of the experiments open a new shell window and run:

```
cd ~/kernel_ipv6_ioam/lxc
./run_iperf.sh
```

This script runs an Iperf server on node Beta, which will be used in all the experiments.


### Loss (observed vs. unobserved) experiment

Before running this experiment make sure that run_iperf.sh is running in a separate shell window.

Run the experiment by:

```
cd ~/kernel_ipv6_ioam/lxc
./capacity.sh
```

The experiment produces an output called capacity_out.txt. The output presents the loss rate (percentage) as a function of the user traffic rate.


### Impact experiment

Before running this experiment make sure that run_iperf.sh is running in a separate shell window, and that run_tshark.sh is running in another shell window.

Run the experiment by:

```
cd ~/kernel_ipv6_ioam/lxc
./ioam_impact.sh
```

This script produces ioam_out.txt. The output file shows the impact [bps] of the measurement as a function of the sampling ratio.


### Data rate impact experiment

Before running this experiment make sure that run_iperf.sh is running in a separate shell window, and that run_tshark.sh is running in another shell window.

Run the experiment by:

```
cd ~/kernel_ipv6_ioam/lxc
./data.sh
```

This script produces data_out.txt. The output file shows the data rate impact [bps] of the measurement as a function of the sampling ratio in an overprovisioned network.


### Loss rate impact experiment

Before running this experiment make sure that run_iperf.sh is running in a separate shell window.

Run the experiment by:

```
cd ~/kernel_ipv6_ioam/lxc
./loss.sh
```

This script produces loss_out.txt. The output file presents the loss rate[%] as a function of the sampling ratio.
