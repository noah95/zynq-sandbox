#!/bin/bash

# build fpga
source /home/noah/Xilinx/Vivado/2018.2/settings64.sh
pushd fpga/hlx/
make
popd

# build linux
pushd sw/linux/
make
popd

