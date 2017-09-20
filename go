#!/bin/sh
#
# This program loads and run the tk707
# implementation that uses the tcl interpreter
#
# Next line restarts as tk707sh	\
exec tk707tcl "$0" "$@"

source ports.tcl
source title_defs.tcl
source score_defs.tcl
source defs.tcl
source gui.tcl
source title.tcl
source score.tcl
source procs.tcl
source tk707.tcl
source help.tcl

