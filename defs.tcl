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
# -----------------------------------------
#	File defs.tcl
#	Definitions and pre-start set up.
# -----------------------------------------
proc usage {} {
    puts "usage: tk707 options...; please read the documentation (html,info,..) and the unix manual."
    exit 0
}
set small_size_factor  0.75;
set medium_size_factor 0.9;
set normal_size_factor 1.0;
set large_size_factor  2;
set size_factor        $normal_size_factor
set input_file_name "";
set new_argv ""
for {set i 0} {$i < $argc} {incr i} {
        set argi [lindex $argv $i];
#       puts "defs.tcl: argv($i) = `$argi'";
        if {$argi == "--help"} {
	    usage
        } elseif {$argi == "-small"} {
#           puts "defs.tcl: small!";
	    set [lindex $argv $i] "-n";
	    set size_factor $small_size_factor;
        } elseif {$argi == "-medium"} {
#           puts "defs.tcl: medium!";
	    set size_factor $medium_size_factor;
        } elseif {$argi == "-normalsize"} {
#           puts "defs.tcl: normal!";
	    set new_argv "$new_argv $argi"
	    set size_factor $normal_size_factor;
        } elseif {$argi == "-big"} {
#           puts "defs.tcl: large!";
	    set new_argv "$new_argv $argi"
	    set size_factor $large_size_factor;
	} else {
	    # send option to the 2nd C-code pass...
#           puts "defs.tcl: argv($i) = `$argi'...added";
	    set new_argv "$new_argv $argi"
	}
}
#
# we strip options to avoid mistakes
#  TODO: send -p x:y nd so to C code
set argv $new_argv
set argc [llength $argv]
#puts "argv := $argv"
#puts "argc := $argc"
# -----------------------------------------
# pixel to centimeter conversion
# -----------------------------------------
package require Tcl 8.0
package require Tk 8.0
set VERSION     0.6
set PKGDATADIR  [pwd]

# uncomment to show sonme boxes:
#set debug_relief "-borderwidth 2p -relief groove";
set debug_relief "";
# -----------------------------------------
# pixel <--> point/inch/cm
# -----------------------------------------
set cm_per_inch     2.54;
set point_per_inch 72.00;
set point_per_cm [expr $point_per_inch / $cm_per_inch];
set pixel_per_point [tk scaling]
# puts "dpi $pixel_per_point"
set pixel_per_inch [expr int($pixel_per_point*$point_per_inch+0.5)]
set pixel_per_cm   [expr $pixel_per_inch/$cm_per_inch]
# -----------------------------------------
# get window max dimension
# -----------------------------------------
set maxsize_in_pixel   [wm maxsize .]
set maxwidth_in_pixel  [lindex $maxsize_in_pixel 0]
set maxheight_in_pixel [lindex $maxsize_in_pixel 1]
set maxwidth_in_cm     [expr $maxwidth_in_pixel * $pixel_per_cm ]
set maxheight_in_cm    [expr $maxheight_in_pixel* $pixel_per_cm ]
# -----------------------------------------
# resize coefficient if window is too small
# -----------------------------------------
if {$size_factor < $medium_size_factor} { 	# small screens
    set size_factor $small_size_factor; 
    set font8 "6";
    set font12 "6"; 
    set boldfont12 "6"; 
    set boldfont13 "6";
    set courrier_boldfont_i_50 "10"; 
    set boldr14 "8";
    set helvetica_bold_r_12 "6"; 
    set normal_r_14 "8"; 
} elseif {$size_factor < $normal_size_factor} { # medium screen
    set size_factor $medium_size_factor; 
    set font8      "6";
    set font12     "8";
    set boldfont12 "8"; 
    set boldfont13 "8"; 
    set courrier_boldfont_i_50 "adobe-courier-bold-i-*-30"; 
    set boldr14 "bold-r-*-10"; 
    set helvetica_bold_r_12 "8"; 
    set normal_r_14 "10"; 
} else { 			# normal screen
    set size_factor $normal_size_factor;
    set font8      "7";
    set font12     "9";
    set boldfont12 "9"; 
    set boldfont13 "9";
    set courrier_boldfont_i_50 "adobe-courier-bold-i-*-50"; 
    set boldr14 "bold-r-*-11"; 
    set helvetica_bold_r_12 "9"; 
    set normal_r_14 "10"; 
}
# -----------------------------------------
# pixel to centimeter conversion
# -----------------------------------------
set scaling $size_factor;
tk scaling $scaling
set pixel_per_point [tk scaling]
set point_per_pixel [expr 1./$pixel_per_point]
set pixel_per_inch [expr int($pixel_per_point*$point_per_inch+0.5)]
set pixel_per_cm   [expr $pixel_per_inch/$cm_per_inch]
# -----------------------------------------
# set global constants
# -----------------------------------------
set tcl_rcFileName "~/.tk707rc"
if {[catch {open $tcl_rcFileName r} fid]} {
} else {
      catch {source $tcl_rcFileName}
}
set res [eval tk7_init $argv]
if {$res == 1 || $res == 3} {
	exit
} elseif {$res ==2} {
	wm iconify .
	port_setup
	tk7_init
}
rename exit exit.old
proc exit {} {
	exit707
	exit.old
}
# -----------------------------------------
# set global constants
# -----------------------------------------
set right_space_width 0.5;


set tkxox(VERSION)		"TK707-$VERSION"
set tkxox(READ) 		0
set tkxox(WRITE) 		1
set tkxox(TRACK) 		0
set tkxox(PATTERN) 		1
set tkxox(STOP)			0
set tkxox(START)		1
set tkxox(CONT)			2
set tkxox(FILE_UNCHANGED)	0
set tkxox(FILE_MODIFIED)	1
set tkxox(col_on) 		#ffaa00
set tkxox(col_active) 		#ffaaaa
set tkxox(col_def_bg) 		#d9d9d9
set tkxox(col_def_active) 	#ececec
set tkxox(but_grey) 		#888888
set tkxox(but_grey_active) 	#999999
set tkxox(but_grey_on) 		#bbbbbb
set tkxox(lamp_off) 		#882200
set tkxox(lamp_on) 		#ff8800
set tkxox(color_fg_shift)    	#ffffff;       # the text on the shift keys (white)
set tkxox(color_bg_shift)       #000044cffb22; # the box on the shift keys (blue)
set tkxox(vol_trough_color) 	#a5e3a5e3a5e3; # background of the trough for volume
set tkxox(vol_slider_passive)   #570a570a570a; # volume slider when nothing append
set tkxox(vol_slider_active)    #204120412041; # volume slider when we interact
set tkxox(vol_highlightbackground) $tkxox(col_def_bg); # the border outside volumes

set tkxox(color_score_bg)       #c24d108c09e9;  # the color of rectangles arround notes
set tkxox(score_active_note)    #ffffff; 	# the color of used notes on the score
set tkxox(score_passive_note)   #87cfff; 	# the color of unused  notes (at right)

set tkxox(color_title_fg)       $tkxox(color_bg_shift);  # the color of "RHYTHM COMPOSER"
set tkxox(color_title_logo_fg)  $tkxox(vol_slider_active); # the color of "TK-707"
set tkxox(color_title_bg)       $tkxox(col_def_bg); 

set tkxox(tick_flam_duration)	4
#
# color background
#
tk_setPalette $tkxox(col_def_bg)
#
#
# Properties of note elements:
# WARNING: may be as in <util.h>
#
set tkxox(flam)               	[expr 1 << 0]
set tkxox(weak_accent)       	[expr 1 << 1]
set tkxox(strong_accent)     	[expr 1 << 2]
set tkxox(zero_velocity)       	[expr 1 << 3]
set tkxox(velocity_field)       [expr $tkxox(zero_velocity) | \
				      $tkxox(weak_accent)   | \
				      $tkxox(strong_accent)]

set tkxox(col_default_velocity) $tkxox(but_grey)
set tkxox(col_weak_accent)      $tkxox(lamp_on)
set tkxox(col_strong_accent)    #ff0000
set tkxox(col_zero_velocity)    white


set mode(rdrw) 			$tkxox(READ)
set mode(patr) 			-1
set mode(stopgo) 		$tkxox(STOP)
set mode(patgroup) 		0
set mode(current_track) 	0
set mode(current_pattern) 	0
set mode(current_instr)		1
set mode(measure) 		-1
set mode(tempo) 		120
set mode(cartridge) 		0
set mode(midi_channel) 		0
set mode(PATTERN_REPEAT) 	false
set mode(TRACK_START) 		false
set mode(REPEAT_INTERVAL) 	5
set mode(showtrack)		true
set mode(current_accent)	0
set mode(file_status)		$tkxox(FILE_UNCHANGED)

set flash(count) -1
set flash(duration) 20

# Default sound mapping
#
set sound(1,name) "Bass 1"
set sound(1,shortname) "Bass 1"
set sound(1,note) 35
set sound(2,name) "Bass 2"
set sound(2,shortname) "Bass 2"
set sound(2,note) 36
set sound(3,name) "Snare 1"
set sound(3,shortname) "Snare 1"
set sound(3,note) 38
set sound(4,name) "Snare 2"
set sound(4,shortname) "Snare 2"
set sound(4,note) 40
set sound(5,name) "LowTom"
set sound(5,shortname) "LowTom"
set sound(5,note) 41
set sound(6,name) "MidTom"
set sound(6,shortname) "MidTom"
set sound(6,note) 45
set sound(7,name) "HighTom"
set sound(7,shortname) "HighTom"
set sound(7,note) 48
set sound(8,name) "Rim"
set sound(8,shortname) "Rim"
set sound(8,note) 37
set sound(9,name) "Cowbell"
set sound(9,shortname) "Cowbell"
set sound(9,note) 56
set sound(10,name) "Hand Clap"
set sound(10,shortname) "Clap"
set sound(10,note) 39
set sound(11,name) "Tambourine"
set sound(11,shortname) "Tamb"
set sound(11,note) 54
set sound(12,name) "HH Closed 1"
set sound(12,shortname) "HH C1"
set sound(12,note) 42
set sound(13,name) "HH Closed 2"
set sound(13,shortname) "HH C2"
set sound(13,note) 42
set sound(14,name) "HHat Open"
set sound(14,shortname) "HH Open"
set sound(14,note) 46
set sound(15,name) "Crash"
set sound(15,shortname) "Crash"
set sound(15,note) 49
set sound(16,name) "Ride"
set sound(16,shortname) "Ride"
set sound(16,note) 51
tk7_set_sounds
#
# instrument(1:16) to volume(1:10) mapping
#
set instrument_to_volume(1) 1
set instrument_to_volume(2) 1
set instrument_to_volume(3) 2
set instrument_to_volume(4) 2
set instrument_to_volume(5) 3
set instrument_to_volume(6) 4
set instrument_to_volume(7) 5
set instrument_to_volume(8) 6
set instrument_to_volume(9) 6
set instrument_to_volume(10) 7
set instrument_to_volume(11) 7
set instrument_to_volume(12) 8
set instrument_to_volume(13) 8
set instrument_to_volume(14) 8
set instrument_to_volume(15) 9
set instrument_to_volume(16) 10

#
# default abbrevs, for volume labels
#
set sound(1,abbrev)  "BASS"
set sound(2,abbrev)  ""
set sound(3,abbrev)  "SNARE"
set sound(4,abbrev)  ""
set sound(5,abbrev)  "LT"
set sound(6,abbrev)  "MT"
set sound(7,abbrev)  "HT"
set sound(8,abbrev)  "R"
set sound(9,abbrev)  "CB"
set sound(10,abbrev) "C"
set sound(11,abbrev) "T"
set sound(12,abbrev) "HH"
set sound(13,abbrev) ""
set sound(14,abbrev) ""
set sound(15,abbrev) "CRASH"
set sound(16,abbrev) "RIDE"
#
# default volume labels
#
set volume_label(0) "ACCENT"
set volume_label(1) "$sound(1,abbrev)"
set volume_label(2) "$sound(3,abbrev)"
set volume_label(3) "$sound(5,abbrev)"
set volume_label(4) "$sound(6,abbrev)"
set volume_label(5) "$sound(7,abbrev)"
set volume_label(6) "$sound(8,abbrev)/$sound(9,abbrev)"
set volume_label(7) "$sound(10,abbrev)/$sound(11,abbrev)"
set volume_label(8) "$sound(12,abbrev)"
set volume_label(9) "$sound(15,abbrev)"
set volume_label(10) "$sound(16,abbrev)"
#
# default implicit delay (e.g. short sound)
#
set has_delay(1) 0
set has_delay(2) 0
set has_delay(3) 0
set has_delay(4) 0
set has_delay(5) 0
set has_delay(6) 0
set has_delay(7) 0
set has_delay(8) 0
set has_delay(9) 0
set has_delay(10) 0
set has_delay(11) 0
set has_delay(12) 0
set has_delay(13) 0
set has_delay(14) 0
set has_delay(15) 0
set has_delay(16) 0
