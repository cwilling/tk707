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
# ======================================================
#	File tk707.tcl
#	Remainder of gui, including key & mouse bindings. Then RUN!
#
#	Pattern memory is now in C-land but track memory still in tcl/tk.
# ======================================================

mem_init

# ======================================================
# lamps into the score
# ======================================================
set score_width  [expr $score_width_in_inch  * $cm_per_inch]
set score_height [expr $score_height_in_inch * $cm_per_inch]
set lamp_width  0.40;
set lamp_height 0.15;
set scale_lamps $score

set scale_lamp3 $score.l3
set scale_lamp2 $score.l2
set scale_lamp1 $score.l1
set scale_lamp0 $score.l0
label $scale_lamp3 -bitmap nix -width ${lamp_width}c -height ${lamp_height}c	\
	-relief groove -borderwidth 2 -bg $tkxox(lamp_off)
label $scale_lamp2 -bitmap nix -width ${lamp_width}c -height ${lamp_height}c	\
	-relief groove -borderwidth 2 -bg $tkxox(lamp_off)
label $scale_lamp1 -bitmap nix -width ${lamp_width}c -height ${lamp_height}c	\
	-relief groove -borderwidth 2 -bg $tkxox(lamp_off)
label $scale_lamp0 -bitmap nix -width ${lamp_width}c -height ${lamp_height}c	\
	-relief groove -borderwidth 2 -bg $tkxox(lamp_on)
pack  $scale_lamp3 -side bottom
pack  $scale_lamp2 -side bottom
pack  $scale_lamp1 -side bottom
pack  $scale_lamp0 -side bottom
set x  0.75
set dy [expr $score_height / 4.0 - 0.04]
set y3 [expr $dy/2 - 0.01];
set y2 [expr $y3 + $dy]
set y1 [expr $y2 + $dy]
set y0 [expr $y1 + $dy]

$scale_lamps create window ${x}c ${y3}c -window $scale_lamp3;
$scale_lamps create window ${x}c ${y2}c -window $scale_lamp2;
$scale_lamps create window ${x}c ${y1}c -window $scale_lamp1;
$scale_lamps create window ${x}c ${y0}c -window $scale_lamp0;

focus ${scale_lamp0}
# ======================================================
# Grid Display Area
# ======================================================
# Vertical lines
set xcoord 0.0
for {set i 0} {$i < 16} {incr i} {
	set xcoord [expr $xcoord + 0.5]
	$grid create line ${xcoord}c 0.5c ${xcoord}c 9.0c -fill #aaaaaa
	set pvalX [tk7_cm2pix $grid ${xcoord}c]
	lappend gridXs $pvalX
	set gridSvals($pvalX) $i
}
# Horizontal lines
set ycoord 0.5
for {set i 0} {$i < 16} {incr i} {
	set ycoord [expr $ycoord + 0.5]
	$grid create line 0.0c ${ycoord}c 8.5c ${ycoord}c -fill #aaaaaa
	set pvalY [tk7_cm2pix $grid ${ycoord}c]
	lappend gridYs $pvalY
	set gridIvals($pvalY) [expr 15 - $i]
}
# -----------------------
# Step markers
# -----------------------
set xcoord 0.0
for {set i 0} {$i < 16} {incr i} {
	set xcoord [expr $xcoord + 0.5]
	$grid create text ${xcoord}c 0.28125c -text [expr $i + 1] -font *-${font12}-*
}
# -----------------------
# Instrument labels
# -----------------------
$gridlabel create text 2.85c 0.28125c -text Step -font *-${font12}-* -anchor e
set xcoord 0.5
set ycoord 0.5625
for {set i 0} {$i < 16} {incr i} {
	set ycoord [expr $ycoord + 0.5]
	$gridlabel create text 2.85c ${ycoord}c -tags ilabel$i	\
		-text $sound([expr 16 - $i],name) -font *-${font12}-* -anchor e
}
$tempoinfo create text 1c 0.5c -text TEMPO -font *-${font12}-* -tags tmtitle
$tempoinfo create text 3.6c 1.5c -text "$mode(tempo)" -tags tempo	\
	-font -${courrier_boldfont_i_50}-* -anchor e
#trace variable mode(tempo) w tempoinfo_update
$tminfo.t create text 0.2c 0.45c -text TRACK -anchor w -font *-${normal_r_14}-*
$tminfo.t create text 3c 0.45c -text "" -tags trackid -font *-${normal_r_14}-*
trace variable mode(current_track) w trackinfo_update
$tminfo.m create text 0.2c 0.4c -text STATUS -anchor w -font *-${font12}-*
# ===================================================================================
# Volume controls
# ===================================================================================
set vol_tics_width 0.25

set title_width  [expr ${title_width_in_inch}  * ${cm_per_inch}];
set title_height [expr ${title_height_in_inch} * ${cm_per_inch}];
set space_height [expr ${title_height}/4.];
set volspacer $vcunit.spacer
canvas $volspacer -width ${title_width}c -height ${space_height}c
pack $volspacer

set cunit $vcunit.u
frame $cunit;
pack $cunit
for {set i 0} {$i<11} {incr i} {
	frame $cunit.$i ;# -relief groove -borderwidth 2
	frame $cunit.$i.sf
	if {$i == 0} {
		canvas $cunit.$i.sf.cl -width 1.2c -height 4c
		$cunit.$i.sf.cl create text 1.2c 0.4c -text MAX -font *-${font12}-* -anchor e
		$cunit.$i.sf.cl create text 1.2c 3.6c -text MIN -font *-${font12}-* -anchor e
		pack $cunit.$i.sf.cl -side left
		set vol_space_width [expr 4*${vol_tics_width}];
	} else {
		set vol_space_width ${vol_tics_width};
	}
	canvas $cunit.$i.sf.c -width 0.25c -height 4c
	for {set j 1} {$j < 10} {incr j} {
		set y [expr 0.4 * $j]
		$cunit.$i.sf.c create line 0c ${y}c ${vol_tics_width}c ${y}c
	}
	$cunit.$i.sf.c create line 0c 0.4c 0.25c 0.4c -width 2
	$cunit.$i.sf.c create line 0c 2.0c 0.25c 2.0c -width 2
	$cunit.$i.sf.c create line 0c 3.6c 0.25c 3.6c -width 2
	scale $cunit.$i.sf.s -orient vertical -from 100 -to 0 -length 4c	\
		-width 0.4c -sliderlength 0.8c \
		-activebackground 	$tkxox(vol_slider_active) \
		-troughcolor 		$tkxox(vol_trough_color) \
		-background 		$tkxox(vol_slider_passive) \
		-highlightbackground 	$tkxox(vol_highlightbackground) \
		-showvalue false -borderwidth 1p \
		-command volset -relief groove

	eval canvas $cunit.$i.sf.spacer -width ${vol_space_width}c -height 4c ${debug_relief};
	pack $cunit.$i.sf.spacer -side right

	pack $cunit.$i -side left
	pack $cunit.$i.sf
	pack $cunit.$i.sf.c -side left
	pack $cunit.$i.sf.s -side left
	frame $cunit.$i.lab

	eval label $cunit.$i.l -height 1 -font *-${font8}-*	\
		-text $volume_label($i) -justify left ${debug_relief}
	pack $cunit.$i.l -expand true -fill x

	# Initialise fader setting
	if {$i == 0} {
	    $cunit.$i.sf.s set 100
	} else {
	    $cunit.$i.sf.s set 66
	}
}
set masterv $cunit.11
frame $masterv
frame  $masterv.sf
pack $masterv -side left
pack  $masterv.sf

set master_width        0.5;
set master_height       5.0;
set master_n_tics       10;
set master_tics_width   0.7;
set master_sliderlength [expr 2.*${master_height}/${master_n_tics}]
set master_incr_height  [expr ${master_height}/(${master_n_tics}+2)];
set vol_space_width     [expr 3*${vol_tics_width}];
eval canvas $masterv.sf.spacer -width ${vol_space_width}c -height ${master_height}c \
	${debug_relief}
pack $masterv.sf.spacer -side left

set master_hi_color #ffff00000000; # red
set master_hibg_color #f332ffff0000; # yellow
set master_acbg_color #000044cffb22; # blue
set master_fg_color #000044440000; # green
	#-background 		$tkxox(but_grey)          \

canvas $masterv.sf.cl -width ${master_tics_width}c -height ${master_height}c
scale $masterv.sf.s -orient vertical -from 100 -to 0 \
	-length ${master_height}c -width ${master_width}c \
	-sliderlength ${master_sliderlength}c	\
	-activebackground 	$tkxox(vol_slider_active) \
	-troughcolor 		$tkxox(vol_trough_color) \
	-background 		$tkxox(vol_slider_passive) \
	-highlightbackground 	$tkxox(vol_highlightbackground) \
	-showvalue false \
	-command volset \
	-borderwidth 1p \
	-relief groove


canvas $masterv.sf.cr -width 2.0c -height ${master_height}c
$masterv.sf.s set 100
for {set i 0} {$i <= ${master_n_tics}} {incr i} {
	if {$i == 0 || 2*$i == ${master_n_tics} || $i == ${master_n_tics} } {
	    set width_in_point 2;
	} else {
	    set width_in_point 1;
	}
	set y [expr ${master_incr_height} * ($i + 1)]
	$masterv.sf.cl create line 0c ${y}c 1.5c ${y}c \
		-width ${width_in_point}p
	$masterv.sf.cr create line 0c ${y}c ${master_tics_width}c ${y}c \
		-width ${width_in_point}p
}
set x [expr ${master_tics_width} * 1.2 ]
set y [expr ${master_incr_height} * (0 + 1)]
$masterv.sf.cr create text ${x}c ${y}c -text MAX -font *-${font12}-* -anchor w
set y [expr ${master_incr_height} * (${master_n_tics} + 1)]
$masterv.sf.cr create text ${x}c ${y}c -text MIN -font *-${font12}-* -anchor w
eval label $masterv.l -text "VOLUME" -justify right -font *-${boldfont12}-* ${debug_relief}

pack  $masterv.sf.cl $masterv.sf.s $masterv.sf.cr -side left
pack $masterv.l -expand true -fill x
$masterv.sf.cl configure

set bypassval 0
set bypass $vcunit.bypass
frame $bypass
pack $bypass
label $bypass.l -text "BYPASS Faders" -font *-${font12}-*
button $bypass.b -bitmap nix -width 3.5c -height 0.75c 	\
	-background $tkxox(but_grey) -activebackground $tkxox(but_grey_active)	\
	-command {vol_bypass [incr bypassval -1]}
pack $bypass.b
pack $bypass.l
set volspacerB $vcunit.spacerB
canvas $volspacerB -width ${title_width}c -height ${space_height}c
pack $volspacerB

proc volset {val} {
	global cunit

	for {set i 0} {$i < 12} {incr i} {
		lappend vals [$cunit.$i.sf.s get]
	}
	eval tk7_set_vols $vals

}
proc vol_bypass {n} {
	global bypassval cunit vcunit masterv
	global font12

	set bypassval [expr abs($n)]	;# Should now be 0 or 1
	if {$bypassval} {
		for {set i 0} {$i < 11} {incr i} {
			$cunit.$i.sf.s configure -state disabled
			$masterv.sf.s configure -state disabled
			$vcunit.bypass.l configure -text "ACTIVATE Faders" -font *-${font12}-*
			tk7_set_vols 100 100 100 100 100 100 100 100 100 100 100 100
		}
	} else {
		for {set i 0} {$i < 11} {incr i} {
			$cunit.$i.sf.s configure -state normal
			$masterv.sf.s configure -state normal
			$vcunit.bypass.l configure -text "BYPASS Faders" -font *-${font12}-*
			volset 0
		}
	}

}
# ======================================================
# small buttons area
# ======================================================

# ------------------------------------------------------
# Clear/Scale/Last Step/Instrument Guide
# ------------------------------------------------------
eval frame $misc.lt1 $debug_relief
pack $misc.lt1
label $misc.lt1.clear -text CLEAR -font *-${boldfont12}-* -anchor c
pack $misc.lt1.clear
button $misc.b1 -bitmap nix -width 0.75c -height 0.75c	\
	-bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)
eval frame $misc.lb1 $debug_relief
pack $misc.lb1
label $misc.lb1.clear -text CLEAR -font *-${boldfont12}-* -anchor c
pack $misc.lb1.clear
$misc create window 0.8c 1.4c  -window $misc.lt1 -anchor s
$misc create window 0.8c 2c    -window $misc.b1  -anchor c
$misc create window 0.8c 2.65c -window $misc.lb1 -anchor n
bind $misc.b1 <ButtonRelease-1>               {ac_clear 0}
bind $misc.b1 <Shift-ButtonRelease-1>         {ac_clear 1}
bind $misc.b1 <Control-ButtonRelease-1>       {ac_clear 2}
bind $misc.b1 <Shift-Control-ButtonRelease-1> {ac_clear 3}

eval frame $misc.lt2 $debug_relief;
pack $misc.lt2
label $misc.lt2.scale -text SCALE -font *-${boldfont12}-* -anchor c
pack $misc.lt2.scale
button $misc.b2 -bitmap nix -width 0.75c -height 0.75c  \
	-bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)
eval frame $misc.lb2 $debug_relief;
pack $misc.lb2
label $misc.lb2.back -text BACK -font *-${boldfont12}-* -anchor c
pack $misc.lb2.back
$misc create window 2.0c 1.4c  -window $misc.lt2 -anchor s
$misc create window 2.0c 2c    -window $misc.b2 -anchor c
$misc create window 2.0c 2.65c -window $misc.lb2 -anchor n
bind $misc.b2 <1> ac_scaleback

eval frame $misc.lt3 $debug_relief;
pack $misc.lt3
label $misc.lt3.last -text LAST -font *-${boldfont12}-* -anchor c
label $misc.lt3.step -text STEP -font *-${boldfont12}-* -anchor c
pack $misc.lt3.last $misc.lt3.step
button $misc.b3 -bitmap nix -width 0.75c -height 0.75c  \
	-bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)
eval frame $misc.lb3 $debug_relief;
pack $misc.lb3
label $misc.lb3.fwd -text FWD -font *-${boldfont12}-* -anchor c
pack $misc.lb3.fwd
$misc create window 3.2c 1.4c  -window $misc.lt3 -anchor s
$misc create window 3.2c 2c    -window $misc.b3 -anchor c
$misc create window 3.2c 2.65c -window $misc.lb3 -anchor n
bind $misc.b3 <1> ac_lastfwd

eval frame $misc.lt4 $debug_relief;
pack $misc.lt4
label $misc.lt4.inst -text INSTR -font *-${boldfont12}-* -anchor c
label $misc.lt4.guide -text /GUIDE -font *-${boldfont12}-* -anchor c
pack $misc.lt4.inst $misc.lt4.guide
button $misc.b4 -bitmap nix -width 0.75c -height 0.75c  \
	-bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)
eval frame $misc.lb4 $debug_relief;
pack $misc.lb4
label $misc.lb4.last -text LAST -font *-${boldfont12}-* -anchor c
label $misc.lb4.meas -text MEAS -font *-${boldfont12}-* -anchor c
pack $misc.lb4.last $misc.lb4.meas
$misc create window 4.4c 1.4c  -window $misc.lt4 -anchor s
$misc create window 4.4c 2c    -window $misc.b4 -anchor c
$misc create window 4.4c 2.65c -window $misc.lb4 -anchor n

bind $misc.b4 <1>                     {ac_lastmeas 0}
bind $misc.b4 <ButtonRelease-1>       {ac_lastmeas 1}
bind $misc.b4 <Shift-1>               {ac_lastmeas 2}
bind $misc.b4 <Shift-ButtonRelease-1> {ac_lastmeas 3}

# ------------------------------------------------------
# Shuffle/Flam & Tempo/Measure controls
# ------------------------------------------------------
#
# shuffle/flam
#
eval frame $st.lt1 $debug_relief;
pack $st.lt1
label $st.lt1.shuff -text SHUFFLE -font *-${boldfont12}-*
label $st.lt1.flam -text /FLAM -font *-${boldfont12}-*
pack $st.lt1.shuff $st.lt1.flam
button $st.b1 -bitmap nix -width 0.75c -height 0.75c  \
	-bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)
eval frame $st.lb1 $debug_relief;
pack $st.lb1
label $st.lb1.midi -text "MIDI CH" -font *-${boldfont12}-* \
	-fg $tkxox(color_fg_shift) -bg $tkxox(color_bg_shift)
pack $st.lb1.midi
$st create window 1c 1.4c  -window $st.lt1 -anchor s
$st create window 1c 2c    -window $st.b1  -anchor c
$st create window 1c 2.65c -window $st.lb1 -anchor n
bind $st.b1 <Button-1> { ac_flam }
bind $st.b1 <Shift-1>  { ac_midi }
#
# tempo/meas area
#
eval frame $st.lt2 $debug_relief;
pack $st.lt2
label $st.lt2.tempo -text TEMPO -font *-${boldfont12}-*
label $st.lt2.meas -text /MEAS  -font *-${boldfont12}-*
pack $st.lt2.tempo $st.lt2.meas
button $st.b2 -bitmap nix -width 0.75c -height 0.75c  \
	-bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)
eval frame $st.lb2 $debug_relief;
pack $st.lb2
label $st.lb2.sync -text "SYNC MODE" -font *-${boldfont12}-* \
	-fg $tkxox(color_fg_shift) -bg $tkxox(color_bg_shift)
pack $st.lb2.sync
$st create window 3c 1.4c  -window $st.lt2 -anchor s
$st create window 3c 2c    -window $st.b2
$st create window 3c 2.65c -window $st.lb2 -anchor n
bind $st.b2 <1> ac_tempomeasure
# ------------------------------------------------------
# Track/Pattern Read/Write control
# ------------------------------------------------------
label $trpa.lt -text PLAY -font *-${boldfont12}-*
label $trpa.lttrack -text TRACK -font *-${boldfont12}-*
label $trpa.ltpattern -text PATTERN -font *-${boldfont12}-*
label $trpa.lbtrack -text TRACK -font *-${boldfont12}-* \
	-fg $tkxox(color_fg_shift) -bg $tkxox(color_bg_shift)
label $trpa.lbstep -text "STEP/TAP" -font *-${boldfont12}-* \
	-fg $tkxox(color_fg_shift) -bg $tkxox(color_bg_shift)
button $trpa.btrk -bitmap nix -width 0.75c -height 0.75c  \
    -bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)
button $trpa.bpat -bitmap nix -width 0.75c -height 0.75c  \
    -bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)
label $trpa.lb -text WRITE -font *-${boldfont12}-*
$trpa create window 1.6c 0.8c  -window $trpa.lt -anchor s
$trpa create window 0.8c 1.4c  -window $trpa.lttrack -anchor s
$trpa create window 0.8c 2c    -window $trpa.btrk -anchor c
$trpa create window 0.8c 2.65c -window $trpa.lbtrack -anchor n
$trpa create window 2.3c 1.4c  -window $trpa.ltpattern -anchor s
$trpa create window 2.3c 2c    -window $trpa.bpat -anchor c
$trpa create window 2.3c 2.65c -window $trpa.lbstep -anchor n
$trpa create window 1.6c 3.30c -window $trpa.lb -anchor n

bind $trpa.btrk <1>        {ac_trackmode $tkxox(READ)}
bind $trpa.btrk <Double-1> {ac_trackmode $tkxox(WRITE)}
bind $trpa.btrk <Shift-1>  {ac_trackmode $tkxox(WRITE)}
bind $trpa.bpat <1>        { ac_patternmode $tkxox(READ); }
bind $trpa.bpat <Double-1> { ac_patternmode $tkxox(WRITE); }
bind $trpa.bpat <Shift-1>  { ac_patternmode $tkxox(WRITE); }
#---------------------------------------
# Pattern Group & Track Number selection
#---------------------------------------
label $grps.lt -text "PATTERN GROUP" -font *-${boldfont12}-*
label $grps.lb -text "TRACK NUMBER"  -font *-${boldfont12}-*
$grps create window 2.5c 0.8c  -window $grps.lt -anchor s
$grps create window 2.5c 3.30c -window $grps.lb -anchor n
eval frame $grps.lt0 $debug_relief;
pack $grps.lt0
label $grps.lt0.lamp -bitmap nix -width 0.4c -height 0.15c	\
	-relief groove -borderwidth 2 -bg $tkxox(lamp_off)
label $grps.lt0.labl -text A -font *-${boldfont12}-*
pack $grps.lt0.lamp $grps.lt0.labl -side left
button $grps.b0 -bitmap nix -width 0.75c -height 0.75c  \
    -bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)
label $grps.lb0 -text I -font *-${boldfont13}-* \
	-fg $tkxox(color_fg_shift) -bg $tkxox(color_bg_shift)
$grps create window 0.8c 1.4c -window $grps.lt0 -anchor s
$grps create window 0.8c 2c -window $grps.b0 -anchor c
$grps create window 0.8c 2.65c -window $grps.lb0 -anchor n

eval frame $grps.lt1 $debug_relief;
pack $grps.lt1
label $grps.lt1.lamp -bitmap nix -width 0.4c -height 0.15c	\
	-relief groove -borderwidth 2 -bg $tkxox(lamp_off)
label $grps.lt1.labl -text B -font *-${boldfont12}-*
pack $grps.lt1.lamp $grps.lt1.labl -side left
button $grps.b1 -bitmap nix -width 0.75c -height 0.75c  \
    -bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)
label $grps.lb1 -text II -font *-${boldfont13}-* \
	-fg $tkxox(color_fg_shift) -bg $tkxox(color_bg_shift)



$grps create window 2c 1.4c -window $grps.lt1 -anchor s
$grps create window 2c 2c -window $grps.b1 -anchor c
$grps create window 2c 2.65c -window $grps.lb1 -anchor n

eval frame $grps.lt2 $debug_relief;
pack $grps.lt2
label $grps.lt2.lamp -bitmap nix -width 0.4c -height 0.15c	\
	-relief groove -borderwidth 2 -bg $tkxox(lamp_off)
label $grps.lt2.labl -text C -font *-${boldfont12}-*
pack $grps.lt2.lamp $grps.lt2.labl -side left
button $grps.b2 -bitmap nix -width 0.75c -height 0.75c  \
    -bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)
label $grps.lb2 -text III -font *-${boldfont13}-* \
	-fg $tkxox(color_fg_shift) -bg $tkxox(color_bg_shift)
$grps create window 3.2c 1.4c -window $grps.lt2 -anchor s
$grps create window 3.2c 2c -window $grps.b2 -anchor c
$grps create window 3.2c 2.65c -window $grps.lb2 -anchor n

eval frame $grps.lt3 $debug_relief;
pack $grps.lt3
label $grps.lt3.lamp -bitmap nix -width 0.4c -height 0.15c	\
	-relief groove -borderwidth 2 -bg $tkxox(lamp_off)
label $grps.lt3.labl -text D -font *-${boldfont12}-*
pack $grps.lt3.lamp $grps.lt3.labl -side left
button $grps.b3 -bitmap nix -width 0.75c -height 0.75c  \
    -bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)
label $grps.lb3 -text IV -font *-${boldfont13}-* \
	-fg $tkxox(color_fg_shift) -bg $tkxox(color_bg_shift)
$grps create window 4.4c 1.4c -window $grps.lt3 -anchor s
$grps create window 4.4c 2c -window $grps.b3 -anchor c
$grps create window 4.4c 2.65c -window $grps.lb3 -anchor n

bind $grps.b0 <1> {ac_group 0}
bind $grps.b1 <1> {ac_group 1}
bind $grps.b2 <1> {ac_group 2}
bind $grps.b3 <1> {ac_group 3}
bind $grps.b0 <Shift-1> {ac_track 0}
bind $grps.b1 <Shift-1> {ac_track 1}
bind $grps.b2 <Shift-1> {ac_track 2}
bind $grps.b3 <Shift-1> {ac_track 3}
# -------------------------------
# Create the note buttons & lamps
# -------------------------------
# add half a button width at left and right of the score alignement
set border_width_in_point 2;
set correction            0.20
set button_width [expr $score_width/17.0 - 2*$border_width_in_point/$point_per_cm - $correction];

set shift_buttons $notes.shift
canvas $shift_buttons -width [expr 0.95*${button_width}]c -height 2.6c;
pack   $shift_buttons -side left;

for {set i 0} {$i<16} {incr i} {
	frame $notes.note$i
	pack $notes.note$i -side left
	label $notes.note$i.l -height 1 -text [expr $i + 1]	\
		-relief groove -borderwidth ${border_width_in_point}p -font *-${font12}-*
	button $notes.note$i.b -bitmap nix -width ${button_width}c -height 2.6c	\
		-bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)
	label $notes.note$i.instr -width 1 \
		-font *-${font12}-* -text $sound([expr $i + 1],shortname);
	pack $notes.note$i.l $notes.note$i.b $notes.note$i.instr \
		-expand true -fill x
	bind $notes.note$i.b <ButtonPress-1>           {ac_note     %W 0}
	bind $notes.note$i.b <ButtonRelease-1>         {ac_note_off %W}
	bind $notes.note$i.b <Control-ButtonPress-1>   {ac_note     %W $tkxox(flam)}
	bind $notes.note$i.b <Control-ButtonRelease-1> {ac_note_off %W}
	bind $notes.note$i.b <Button-3>                {ac_note     %W $tkxox(zero_velocity)}
	bind $notes.note$i.b <Shift-1>                 {ac_newinstr %W}
}
#
# Empty Space : adjust vectical alignment with score
# 	- at the right of the score
# 	- at the right of the instrument buttons
#
set empty_right $note_score.right
set empty_case $notes.right
canvas $empty_right -width ${right_space_width}c -height ${score_height_in_inch}i;
canvas $empty_case  -width ${right_space_width}c -height 2.6c;
pack   $empty_right -side left;
pack   $empty_case -side right;

pattern_setid 0	;	# Initialise pattern number
ac_group $mode(patgroup)
ac_newinstr $notes.note0.b	;	# Initialise current instrument

# Bindings to activate note buttons from keyboard
# 1->10 = buttons 1->10, "q"->"y" = 11->16
#
set k 0
bind . <KeyPress-1> {ac_note $notes.note0.b 0}
bind . <KeyPress-2> {ac_note $notes.note1.b 0}
bind . <KeyPress-3> {ac_note $notes.note2.b 0}
bind . <KeyPress-4> {ac_note $notes.note3.b 0}
bind . <KeyPress-5> {ac_note $notes.note4.b 0}
bind . <KeyPress-6> {ac_note $notes.note5.b 0}
bind . <KeyPress-7> {ac_note $notes.note6.b 0}
bind . <KeyPress-8> {ac_note $notes.note7.b 0}
bind . <KeyPress-9> {ac_note $notes.note8.b 0}
bind . <KeyPress-0> {ac_note $notes.note9.b 0}
bind . <KeyPress-q> {ac_note $notes.note10.b 0}
bind . <KeyPress-w> {ac_note $notes.note11.b 0}
bind . <KeyPress-e> {ac_note $notes.note12.b 0} ;# puts "[incr k]"}
bind . <KeyPress-r> {ac_note $notes.note13.b 0}
bind . <KeyPress-t> {ac_note $notes.note14.b 0}
bind . <KeyPress-y> {ac_note $notes.note15.b 0}

# Bindings for pattern Copy/Paste
#
bind . <Control-c> {
	tk7_set_patbuf $mode(patgroup) $mode(current_pattern)
}
bind . <Control-b> {
	if {($mode(rdrw) == $tkxox(WRITE)) && ($mode(patr) == $tkxox(PATTERN))} {
		tk7_copy_patbuf $mode(patgroup) $mode(current_pattern) 1
		pattern_setid $mode(current_pattern)
	}
}
bind . <Control-v> {
	if {($mode(rdrw) == $tkxox(WRITE)) && ($mode(patr) == $tkxox(PATTERN))} {
		tk7_copy_patbuf $mode(patgroup) $mode(current_pattern) 0
		pattern_setid $mode(current_pattern)
	}
}
#
# Bindings for pattern editing from display grid
#
proc grid_note {x y prop} {
	global notes
	upvar #0 tkxox xox
	upvar #0 mode mo
	if {$mo(patr) == $xox(TRACK) || $mo(rdrw) == $xox(READ)} {
	    return
	}
	if {![have_zero_velocity $prop]} {
	  switch $mo(current_accent) {
	    2       {set prop [add_strong_accent    $prop] }
	    1 	    {set prop [add_weak_accent      $prop] }
	    default {set prop [add_default_velocity $prop] }
	  }
	}
	# Convert x,y position to a grid intersection point
	# and imply step,instrument combination from it.
	if {[locate_gridpos $x $y SIvals] < 0 } {
	    return
	}
	#puts " -> Instrument $SIvals(inst) at step $SIvals(step) with prop $prop"
	ac_newinstr $notes.note$SIvals(inst).b
	step_insert $SIvals(step) $prop
}
bind $grid <Button-1> {
	#puts "Button-1: %x,%y"
}
bind $grid <Double-Button-1> {
	#puts "Double-Button-1: %x,%y"
	grid_note %x %y 0
}
bind $grid <Control-Double-Button-1> {
	#puts "Control-Double-Button-1: %x,%y"
        upvar #0 tkxox xox
	grid_note %x %y $xox(flam)
}
bind $grid <Double-Button-3> {
	#puts "Shift-Double-Button-1: %x,%y"
        upvar #0 tkxox xox
	grid_note %x %y $xox(zero_velocity)
}
# ------------------------------------------------------
# Create Accent/Enter button set
# ------------------------------------------------------
label $accenter.lt -height 1 -text ENTER -font *-${boldfont12}-*
frame $accenter.cart
label $accenter.cart.lamp -bitmap nix -width 0.4c -height 0.15c	\
	-relief groove -borderwidth 2 -bg $tkxox(lamp_off)
label $accenter.cart.labl -text CARTRIDGE -font *-${boldfont12}-* \
	-fg $tkxox(color_fg_shift) -bg $tkxox(color_bg_shift)
pack $accenter.cart.lamp $accenter.cart.labl -side left
button $accenter.b -bitmap nix -width 1.45c -height 2.1c	\
	-bg $tkxox(but_grey) -activebackground $tkxox(but_grey_active)
set accent_label $accenter.lb
label $accent_label -height 1 -text ACCENT -font *-${boldfont12}-*
$accenter create window 1.43c 0.35c -window $accenter.lt
$accenter create window 1.43c 0.8c -window $accenter.cart
$accenter create window 1.43c 2.3c -window $accenter.b
$accenter create window 1.43c 3.8c -window $accent_label -tags accent
bind $accenter.b <1> {ac_accenter 0}		;# Add pattern into track
bind $accenter.b <Shift-1> {ac_accenter 1}	;# Insert pattern into track
bind $accenter.b <Control-1> {ac_cartridge}
# ------------------------------------------------------
# Create the Tempo Dial
# ------------------------------------------------------
set dial_canvas $dial.c
set dial_value  $dial.v

label $dial_value -text "TEMPO $mode(tempo)" -anchor n -font *-${boldr14}-* ;
pack $dial_value -expand true -fill x
canvas $dial_canvas -width 4c -height 3.2c ;#-relief groove -borderwidth 2
pack $dial_canvas -side left
set dial_radius 1.; # in centimeter
$dial_canvas create oval 1c 0.2c 3c 2.2c -width 2p -tags dial	\
	-fill $tkxox(but_grey)
$dial_canvas create line 0c 0c 0c 0c -tags indicator
$dial_canvas create text 0.4c 2.9c -text SLOW -anchor w	\
	-font *-${helvetica_bold_r_12}-*
$dial_canvas create text 3.7c 2.9c -text FAST -anchor e	\
	-font *-${helvetica_bold_r_12}-*
$dial_canvas bind dial <Button-1> {
	upvar #0 mode mo

	# Angular-oriented dial:
	# Note: It would be better to get the center of the
	# dial as origin, instead of the picked point into the dial
	set orig_x %x
	set orig_y %x
	set orig_tempo $mo(tempo)
}
$dial_canvas bind dial <B1-Motion> {
	dial_adjust [expr %x - $orig_x] [expr %y - $orig_y] $orig_tempo
}
# the tempo range is 30-330 on my tk727 (saramito@imag.fr)
# I don't known for the tk707
set tempo_min  30; # points to SLOW
set tempo_max 265; # points to FAST
set tempo_ini 120; # at initialization

proc dial_adjust {x y orig_tempo} {
	global dial_value
	global dial_canvas
	global dial_radius
	global tempo_min; # the arrow points to SLOW
	global tempo_max; # the arrow points to FAST
	upvar #0 mode mo

	set pi          3.14159265358979323846;
	set pi_o4       [expr 0.25*$pi];
	set pi_3o4      [expr 3*$pi_o4];

	# vertical indicator -> medium tempo
	set delta_tempo  [expr 0.5*($tempo_max - $tempo_min)];
	set tempo_med    [expr 0.5*($tempo_max + $tempo_min)];

	if {($x == 0) && ($y == 0)} {

	    # special case: when x = y = 0
	    # i.e. when mouse comes back to origin where we pick the dial
	    #  or also at the initialization call procedure
	    # => angle is not computable with (x,y)	
	    # but by using $orig_tempo :
	    set tempo_val $orig_tempo
	    if {$tempo_val > $tempo_med} {
		# alpha is in the range ( pi/4, pi (
		# ksi                   (  0 ,  1  (
	        set ksi    [expr  ($tempo_max-$tempo_val)/$delta_tempo]
	        set alpha  [expr  $pi/4 + $ksi*(3*$pi/4)]
	    } else {
		# alpha is in the range ) -pi, -pi/4 )
		# ksi                   )  0 ,  1    )
	        set ksi    [expr  ($tempo_val-$tempo_min)/$delta_tempo]
	        set alpha  [expr  - $pi/4 - $ksi*(3*$pi/4)]
	    }
	} else {
	    #  the general case
	    set alpha [expr atan2($x,$y)];
            if {$alpha > 0} {

	        # the mouse is on the right side of the origin -> fast
	        if {$alpha < $pi_o4} {
		    # set to the minimal value
		    set tempo_val $tempo_max
		    set alpha $pi_o4
	        } else {
	  	    # alpha is in the range ( pi/4, pi (
		    # zeta                  ( 0     1  (
	            set zeta  [expr ($alpha-$pi_o4)/$pi_3o4]
		    set tempo_val [expr $tempo_max - $zeta*$delta_tempo]
	        }
	    } else {
	        # alpha < 0

	        # mouse is on the right side of the origin -> fast
	        if {$alpha > [expr -$pi_o4]} {
		    # set tempo the minimal value
		    set tempo_val $tempo_min
		    set alpha -$pi_o4
	        } else {
	  	    # alpha is in the range ) -pi, -pi/4 )
		    # zeta                  ) 0     1    )
		    set zeta  [expr ($alpha+$pi)/$pi_3o4]
		    set tempo_val [expr $tempo_med - $zeta*$delta_tempo ]
	        }
	    }
	}
        # make an integer
	set tempo_val [expr int($tempo_val)]

	# then we apply this :
	set mo(tempo) $tempo_val
	tk7_set_tempo $tempo_val
	${dial_value} configure -text "TEMPO $tempo_val"

	# update the dial indicator
	set sin_alpha [expr sin($alpha)]
	set cos_alpha [expr cos($alpha)]
	set x_indic [expr 2.0 + $dial_radius * $sin_alpha]
	set y_indic [expr 1.2 + $dial_radius * $cos_alpha]
	${dial_canvas} coords indicator ${x_indic}c ${y_indic}c 2c 1.2c
}
# Angular-oriented dial: set initial tempo and vertical direction
dial_adjust 0 0 $tempo_ini

midichan_set [expr $midi_channel + 1]
ac_patternmode $tkxox(READ)
ac_trackmode $tkxox(READ)
ac_track 0
# ======================================================
# Action!
# ======================================================
wm deiconify .;
# after 10 play_loop;
play_loop;


