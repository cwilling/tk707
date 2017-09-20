#
#    This file is part of tk707.
#
#    Copyright (C) 2000, 2001, 2002, 2003, 2004 Chris Willing and Pierre Saramito 
#
#    tk707 is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    Foobar is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Foobar; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# -----------------------------------------------------------------------------
#	File ports.tcl
#	GUI for selection of ALSA port.
# -----------------------------------------------------------------------------

proc port_setup {} {
	global tcl_rcFileName
	global ports
	global iolists
	global font12
	global normal_r_14

	set ports .setup
	toplevel $ports
	wm title $ports "TK-707 ALSA port setup"

	set howto .setup.h
	set howtotext $howto.text
	set howtoscroll $howto.scroll
	frame $howto ;#-relief groove -borderwidth 2
	canvas $howtotext -yscrollcommand "$howtoscroll set" -width 13.5c -height 5c
	scrollbar $howtoscroll -command "$howtotext yview" -width 0.4c
	pack $howtoscroll -side right -fill y
	pack $howtotext
	pack $howto

	$howtotext create text 0.2c 0.2c -anchor nw -font *-${normal_r_14}-* -text	\
"Double click on one of Output Ports to make it the Selected Output.\n
The SAVE button will save the setting in ~/.tk707rc so that this
selection dialogue won't appear next time TK-707 is started.\n
The OK button will close this dialogue and allow TK-707 to start
using the selected port. If the current setting hasn't been SAVEd
then this dialogue will appear again next time TK-707 is run.
If no port has been selected, TK707 will not start.\n
Input Port selection is for future use and currently has no effect.\n
When this selection dialogue is raised from the File->Ports menu,
a selection can be SAVEd but ports cannot be changed while
TK-707 is running (yet)."

	set iolists $ports.l
	canvas $iolists -width 14c -height 8c -relief groove -borderwidth 2
	pack $iolists
	set	olist $iolists.ol
	set	ilist $iolists.il
	set oselect $iolists.op
	set iselect $iolists.ip

        scrollbar $iolists.os -command "$olist yview"
        scrollbar $iolists.is -command "$ilist yview"
        listbox $olist -font *-${normal_r_14}-* -width 26 -height 10 -selectmode browse -exportselection 1 -yscroll "$iolists.os set"
	listbox $ilist -font *-${normal_r_14}-* -width 26 -height 10 -selectmode browse -exportselection 1 -yscroll "$iolists.is set"

	label $oselect -width 28 -height 1 -relief sunken -borderwidth 2
	label $iselect -width 28 -height 1 -relief sunken -borderwidth 2


	$iolists create text 2c 0.5c -font *-${normal_r_14}-* -text "Input Ports" -anchor nw
	$iolists create text 9c 0.5c -font *-${normal_r_14}-* -text "Output Ports" -anchor nw
        $iolists create window 0c 1.5c -height 4c -window $iolists.is -anchor nw
        $iolists create window 0.5c 1.5c -height 4c -window $ilist -anchor nw
        $iolists create window 7c 1.5c -height 4c -window $iolists.os -anchor nw
        $iolists create window 7.5c 1.5c -height 4c -window $olist -anchor nw
	$iolists create window 0.2c 6c -window $iselect -anchor nw
	$iolists create window 7.05c 6c -window $oselect -anchor nw
	$iolists create text 2c 7c -font *-${normal_r_14}-* -text "Selected Input" -anchor nw
	$iolists create text 9c 7c -font *-${normal_r_14}-* -text "Selected Output" -anchor nw

	# Get list of output ports
	set oportlist [tk7_port_list 1]
	foreach i $oportlist {
		$olist insert end $i
	}
	# Get list of input ports
	set iportlist [tk7_port_list 0]
	foreach i $iportlist {
		$ilist insert end $i
	}
	bind .setup.l.il <Double-1> {
		$iolists.ip configure -font *-${normal_r_14}-* -text [selection get]
	}
	bind $olist <Double-1> {
		$iolists.op configure -font *-${normal_r_14}-* -text [selection get]
	}
	set portacts $ports.pa
	canvas $portacts -width 14c -height 1.5c
	pack $portacts

	button $portacts.c -font *-${normal_r_14}-* -text CANCEL -width 6 -command {
		if {! [tk7_port_setcheck]} {
			puts "NO PORTS SET"
			destroy .
			exit
		} else {
			destroy $ports
		}
	}
	button $portacts.s -font *-${normal_r_14}-* -text SAVE -width 6 -command {
		set oplist [.setup.l.op configure -text]
		# puts "XX${oplist}XX"
		if {[llength $oplist] != 5} {
			puts nothing
		} else {
			if {[llength [lindex $oplist 4]] > 0} {
				set op [lindex [lindex $oplist 4] 0]
				set oc [lindex [lindex $oplist 4] 1]
				set tkxox(ALSA_OUTPORT) "${op}:${oc}"
				# Save selection
				set OPstr [format "set tkxox(ALSA_OUTPORT) %d:%d" $op $oc]
				set f [open $tcl_rcFileName w]
				seek $f  0 end
				puts $f $OPstr
				close $f
				destroy $ports
			}
		}
	}
	button $portacts.b -font *-${normal_r_14}-* -text OK -width 6 -command {
		set oplist [.setup.l.op configure -text]
		if {[llength $oplist] != 5} {
			puts nothing
		} else {
			if {[llength [lindex $oplist 4]] > 0} {
				set op [lindex [lindex $oplist 4] 0]
				set oc [lindex [lindex $oplist 4] 1]
				set tkxox(ALSA_OUTPORT) "${op}:${oc}"
			}
		}
		if {! [tk7_port_setcheck]} {
			#puts "NO PORTS SET"
			destroy .
			exit
		} else {
			destroy $ports
		}
	}
	$portacts create window 3c 0.75c -window  $portacts.c
	$portacts create window 7c 0.75c -window  $portacts.s
	$portacts create window 11c 0.75c -window  $portacts.b

	grab set $ports
	tkwait window $portacts
}
