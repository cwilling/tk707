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
# =========================================================================
#	File gui.tcl
#	GUI for TK-707
# =========================================================================
eval destroy [winfo child .]
wm title . "TK-707"
set font {Helvetica 14}
wm iconify .
# -------------------------------------------------------------------------
# menu bar
# -------------------------------------------------------------------------
frame .mbar -borderwidth 1p -relief raised
pack .mbar -fill x

menubutton .mbar.file -text "File" -menu .mbar.file.m
menubutton .mbar.midi -text "Midi" -menu .mbar.midi.m
menubutton .mbar.map  -text "Map"  -menu .mbar.map.m
pack .mbar.file -side left
pack .mbar.midi -side left
pack .mbar.map  -side left

menubutton .mbar.help -text "Help"  -menu .mbar.help.m 
pack .mbar.help  -side right

# -----------------------------------------------------------------------------
# file menu
# -----------------------------------------------------------------------------
menu .mbar.file.m -tearoff 0
.mbar.file.m add command -label "Load Data" -command {load_data_file "."}   	\
					    -underline 0 		    	\
        				    -accelerator "Ctrl-O"
.mbar.file.m add command -label "Load Demo" -command {load_data_file $PKGDATADIR} \
					    -underline 0
.mbar.file.m add command -label "Save Data" -command {save_data_file} 		\
					    -underline 0 			\
					    -accelerator "Ctrl-S"
.mbar.file.m add command -label "Ports"     -command {port_setup} 		\
					    -underline 0
.mbar.file.m add command -label "Quit"      -command "exit" 			\
					    -underline 0 			\
					    -accelerator "Ctrl-Q"

bind . <Control-q> { exit;}
bind . <Control-o> { load_data_file ".";}
bind . <Control-s> { save_data_file;}

# -----------------------------------------------------------------------------
# midi & map menus
# -----------------------------------------------------------------------------
menu .mbar.midi.m -tearoff 0
menu .mbar.map.m  -tearoff 0

.mbar.midi.m add command -label "Save Midi Track"  -command {save_midi_file} -underline 0
.mbar.midi.m add command -label "Set MIDI Channel" -command {ac_midi} -underline 0


.mbar.map.m add command -label "Load Standard Sound Map" -command {load_sound_map $PKGDATADIR} -underline 0
.mbar.map.m add command -label "Load Local Sound Map" -command {load_sound_map "."} -underline 0
.mbar.map.m add command -label "Save Sound Map" -command {save_sound_map} -underline 0
.mbar.map.m add command -label "Edit Sound Map" -command {map_edit} -underline 0
.mbar.map.m add command -label "Edit Fader Map" -command {fader_edit} -underline 0

# TODO: next will put names on patterns for automatic score generation...
# menu .mbar.pattern -tearoff 0
# .mbar add cascade -menu .mbar.pattern -label "Pattern" -underline 0
# .mbar.pattern add command -label "Edit Comment" -command {edit_pattern_comment} -underline 0

# -----------------------------------------------------------------------------
# help menu
# -----------------------------------------------------------------------------
menu .mbar.help.m -tearoff 0

.mbar.help.m add command -label "About"         -command {about}      -underline 0
.mbar.help.m add command -label "User's Manual" -command {UserManual} -underline 0


. configure -menu .mbar

# =========================================================================
# Frame for Grid & Volume controls
# =========================================================================
set grid_vols .gv
eval frame $grid_vols $debug_relief
pack $grid_vols -anchor c
# --------------------------------------------------------------------------
# Grid Display
# --------------------------------------------------------------------------
set display $grid_vols.d
frame $display -relief groove -borderwidth 2p
pack $display -side left
frame $display.g
pack $display.g ;#-side left
set gridlabel $display.g.l		;	# Instrument label
canvas $gridlabel -width 3c -height 9.0c
set grid $display.g.c			;	# Pattern Grid
canvas $grid -width 8.5c -height 9.0c
pack $gridlabel $grid -side left
# --------------------------------------------------------------------------
# Status area
# --------------------------------------------------------------------------
set infosection $display.i		;	# to contain Tempo, Track & Mode widgets
frame $infosection
pack $infosection -side bottom
set tempoinfo $infosection.t
set tminfo $infosection.tm
frame $tminfo
canvas $tempoinfo -width 4c -height 2c -relief groove -borderwidth 2
canvas $tminfo.t -width 7.5c -height 0.75c -relief groove -borderwidth 2
canvas $tminfo.m -width 7.5c -height 1.25c -relief groove -borderwidth 2
pack $tminfo.t $tminfo.m
pack $tempoinfo $tminfo -side left -expand true -fill y
# --------------------------------------------------------------------------
# Volume controls
# --------------------------------------------------------------------------
set vcunit $grid_vols.cu
eval frame $vcunit $debug_relief
pack $vcunit -side left
#
# Controls + Notes Staff
#
set ctrls_notes_staff .cns
frame $ctrls_notes_staff
pack $ctrls_notes_staff -expand true -fill x
# ==========================================================================
# Controls
# ==========================================================================
set ctrl_height  4.0;
set ctrls $ctrls_notes_staff.c
frame $ctrls
pack $ctrls -side top -expand true -fill x
# ---------------------------------------
# Scale lamps + Score + Notes/Instruments
# ---------------------------------------
set notes_staff $ctrls_notes_staff.ns
frame $notes_staff
pack $notes_staff -anchor s
# ---------------------------------------
# Transport control (Start/Cont)
# ---------------------------------------
set    stop_box $ctrls.stop_box
eval canvas $stop_box -width 2.3c -height ${ctrl_height}c $debug_relief;
pack   $stop_box -side left -anchor n ;
set button_stop  $stop_box.stop
label $stop_box.lt  -text STOP/CONT -font *-${boldfont13}-*
radiobutton $button_stop -bitmap nix -width 1.45c -height 2.6c    \
        -variable ss -value stop -indicatoron false     \
        -bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)  \
        -selectcolor $tkxox(but_grey_active)    \
        -command "ac_stopgo $tkxox(CONT)"
$stop_box  create window 1.25c 0.4c -window $stop_box.lt
$stop_box  create window 1.25c 2.2c -window $button_stop
bind all <space> {
        if {$mode(stopgo) == $tkxox(START)} {
                $button_stop invoke
        } else {
                ac_stopgo $tkxox(START)
                $button_start invoke
        }
}
#
# Transport control (start)
#
set     start_box $notes_staff.start_box
canvas $start_box -width 2.3c -height 4.5c ;#-relief groove -borderwidth 4
pack   $start_box -side left -anchor n ;#-expand true -fill y
set button_start $start_box.start
label $start_box.lb -text START     -font *-${boldfont13}-*
radiobutton $button_start -bitmap nix -width 1.45c -height 2.6c   \
        -variable ss -value start -indicatoron false    \
        -bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)  \
        -selectcolor $tkxox(but_grey_active)
$start_box create window 1.25c 0.4c -window $start_box.lb
$start_box create window 1.25c 2.1c -window $button_start
bind $button_start <1> {ac_stopgo $tkxox(START)}
# ================================================================
# button controls
# ================================================================
set space_width  2.8;
set misc_width   5.0;
set st_width     4.0;
set trpa_width   3.0;
set grp_width    5.0;
set accent_width 2.6;
#
# Empty Space : adjust vectical alignment with score
#
set empty_case $ctrls.z
eval canvas $empty_case -width ${space_width}c -height ${ctrl_height}c \
	$debug_relief;
pack   $empty_case -side left -anchor nw ;
#
# Clear/Scale/Last Step/Instrument Guide
#
set misc $ctrls.misc
eval canvas $misc -width ${misc_width}c -height ${ctrl_height}c $debug_relief;
pack $misc -side left -anchor n
#
# Shuffle/Flam Tempo/Measure controls
#
set st $ctrls.st
eval canvas $st -width ${st_width}c -height ${ctrl_height}c $debug_relief;
pack $st -side left -anchor n
#
# Track/Pattern Read/Write Control
#
set trpa $ctrls.trpa
eval canvas $trpa -width 3c -height ${ctrl_height}c $debug_relief;
pack $trpa -side left -anchor n
#
# Pattern Group & Track Number selection
#
set grps $ctrls.grps
eval canvas $grps  -width 5c -height ${ctrl_height}c $debug_relief;
pack $grps -side left -anchor n
#
# Accent/Enter
#
set accenter $ctrls.accenter
eval canvas $accenter -width 2.6c -height ${ctrl_height}c $debug_relief;
pack $accenter -side left -anchor n
#
# Tempo Dial
#
set dial $ctrls.dial
eval frame $dial $debug_relief
pack $dial -side left -expand true;
# ---------------------------
# Score + Notes/Instruments
# ---------------------------
set note_score $notes_staff.sc
eval frame $note_score $debug_relief;
pack $note_score
# ---------------------------
# Notes/Instruments
# ---------------------------
set notes $notes_staff.n;
eval frame $notes $debug_relief;
pack $notes -anchor w -side left
