###############################################################################
# Cocotb test suite
###############################################################################

TOPLEVEL_LANG ?= verilog
SIM ?= icarus

PWD=$(shell pwd)

PYTHONPATH := ./:$(PYTHONPATH)

VERILOG_SOURCES = $(PWD)/../hdl/blinker_top.v

TOPLEVEL := blinker_top
MODULE   := test_blinker

# include $(shell cocotb-config --makefiles)/Makefile.inc
# include $(shell cocotb-config --makefiles)/Makefile.sim


# ==============================================================================
# cocotb
# ==============================================================================
GHDL_ARGS = --ieee=synopsys
SIM_ARGS  = --wave=$(TOPLEVEL).ghw
SIM_ARGS += --vcd=$(TOPLEVEL).vcd
COCOTB_ANSI_OUTPUT=0
COCOTB_REDUCED_LOG_FMT=1

# Invoke cocotb
include $(shell cocotb-config --makefiles)/Makefile.inc
include $(shell cocotb-config --makefiles)/Makefile.sim
# ==============================================================================

