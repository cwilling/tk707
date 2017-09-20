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
#=====================================================
#	File procs.tcl
#	Procedures for the tcl side of the program
#=====================================================

proc play_pattern {grp pat} {
	upvar #0 tkxox xox
	upvar #0 mode mo
	upvar #0 pattern_list pl

	if {$mo(PATTERN_REPEAT)} {

		#puts "TIMER = [tk7_timer_status]"
		set steps [tk7_get_last_step $grp $pat]
		set dur [tk7_pattern_play $grp $pat]

		cycle_notes 1 [expr 55 * 120 / $mo(tempo)] 0 0 $steps

		# Fudge factor (extra time to change track display) in track play mode
		if {$mo(rdrw) == $xox(READ) || $mo(patr) == $xox(TRACK)} {
			incr dur -160
			if {$dur < 0} {
				set dur 0
			}
			#set mo(REPEAT_INTERVAL) [expr $dur - 160]
			set mo(REPEAT_INTERVAL) $dur
		} else {
			set mo(REPEAT_INTERVAL) $dur
		}
	}
}
proc stop_pattern {} {
	upvar #0 mode mo
	upvar #0 tkxox xox

#puts "do stop_pattern"
	tk7_pattern_stop
	set mo(REPEAT_INTERVAL) 10
}

proc ac_clear {tp} {
	upvar #0 tkxox xox
	upvar #0 mode mo
	upvar #0 track_list tl
	upvar #0 pattern_list pl

	switch $tp {
		0	{
		# CLEAR the current PATTERN
			if {$mo(rdrw) != $xox(WRITE) || $mo(patr) != $xox(PATTERN)} {
				return
			}
			set result [tk_dialog .clr CONFIRM "Clear Pattern [expr $mo(current_pattern) + 1] Group [expr $mo(patgroup) + 1]?" "" 0 Cancel "Delete Pattern"]
			if {$result == 0} {
				return
			}
			set mo(file_status) $xox(FILE_MODIFIED)
			tk7_clear_pattern $mo(patgroup) $mo(current_pattern)
			pattern_setid $mo(current_pattern)
			scale_lamps_update
		}

		1	{
		# CLEAR the current TRACK
			if {$mo(rdrw) != $xox(WRITE) || $mo(patr) != $xox(TRACK)} {
				return
			}
			set result [tk_dialog .clr CONFIRM "Clear Track [expr $mo(current_track) + 1]?" "" 0 Cancel "Delete Track"]
			if {$result == 0} {
				return
			}
			set mo(file_status) $xox(FILE_MODIFIED)
			set tl($mo(current_track)) {}
			set mo(measure) -1
		}
		2 	{
		# CLEAR current track item from current track
			if {$mo(rdrw) != $xox(WRITE) || $mo(patr) != $xox(TRACK)} {
				return
			}
			# Clearing track item has no meaning if we're already past end
			set target $mo(measure)
			if {[lindex $tl($mo(current_track)) $target] == ""} {
				#puts "Already past end"
				return
			}
			set result [tk_dialog .clr CONFIRM "Clear measure [expr $target + 1] from track [expr $mo(current_track) + 1]?" "" 0 Cancel "Delete"]
			if {$result == 0} {
				return
			}
			set mo(file_status) $xox(FILE_MODIFIED)
			set tl($mo(current_track)) [lreplace $tl($mo(current_track)) $target $target]
		}
		3	{
		# CLEAR the rest of current track including current track item
			if {$mo(rdrw) != $xox(WRITE) || $mo(patr) != $xox(TRACK)} {
				return
			}
			# Clearing rest has no meaning if we're already past end of track
			set target $mo(measure)
			if {[lindex $tl($mo(current_track)) $target] == ""} {
				# puts "Already past end"
				return
			}
			set result [tk_dialog .clr CONFIRM "    Clear rest of track [expr $mo(current_track) + 1]?\n(includes current measure)" "" 0 Cancel "Delete"]
			if {$result == 0} {
				return
			}
			set mo(file_status) $xox(FILE_MODIFIED)
			set tl($mo(current_track)) [lreplace $tl($mo(current_track)) $target end]
		}
	}
}
proc ac_scaleback {} {
	upvar #0 tkxox xox
	upvar #0 mode mo
	upvar #0 track_list tl
	global scale_lamps

	if {$mo(patr) == $xox(PATTERN)} {
		set old_scale [tk7_get_scale $mo(patgroup) $mo(current_pattern)]
		set new_scale [expr $old_scale + 1]
		if {$new_scale == 4} {
		    set new_scale 0
		}
		set old_button $scale_lamps.l$old_scale
		set new_button $scale_lamps.l$new_scale
		tk7_set_scale $mo(patgroup) $mo(current_pattern) $new_scale
		$old_button configure -background $xox(lamp_off)
		$new_button configure -background $xox(lamp_on)
	} else {
		set target [expr $mo(measure) - 1]
		set mo(measure) [measure_constrain $target]
		pattern_show
	}
	set mo(file_status) $xox(FILE_MODIFIED)
}
proc ac_lastfwd {} {
	upvar #0 tkxox xox
	upvar #0 mode mo
	upvar #0 track_list tl

	if {$mo(patr) == $xox(PATTERN)} {
		if {$mo(rdrw) == $xox(READ)} {
			return
		}
		select_laststep
		set mo(file_status) $xox(FILE_MODIFIED)
	} else {
		set target  [expr $mo(measure) + 1]
		set mo(measure) [measure_constrain $target]
		pattern_show
	}
}
proc measure_constrain {m} {
	upvar #0 tkxox xox
	upvar #0 mode mo
	upvar #0 track_list tl

	set tracklength [llength $tl($mo(current_track))]

	if {$tracklength < 1} {
		if {$mo(rdrw) == $xox(READ)} {
			set minpos -1
			set maxpos -1
		} else {
			set minpos 0
			set maxpos 0
		}
	} else {
		if {$mo(rdrw) == $xox(READ)} {
			set maxpos [expr $tracklength - 1]
		} else {
			set maxpos $tracklength
		}
		set minpos 0
	}

	# Result
	if {$m <= $minpos} {
		return $minpos
	} elseif {$m >= $maxpos} {
		return $maxpos
	} else {
		return $m
	}
}
# Decide which pattern from a track to display
#
proc pattern_show {} {
	upvar #0 tkxox xox
	upvar #0 mode mo
	upvar #0 track_list tl

	set raw [lindex $tl($mo(current_track)) $mo(measure)]
	if {$raw != ""} {
		set group [expr $raw / 16]
		set pattern [expr $raw % 16]
		ac_group $group
		pattern_setid $pattern
	}
}

# For track mode, ordinary click (on LAST MEAS button) shows last measure
# of current track. Releasing button returns to orginal measure.
# Shift click goes to last measure and stays there.
#
proc ac_lastmeas {m} {
	upvar #0 tkxox xox
	upvar #0 mode mo
	upvar #0 track_list tl

	if {$mo(patr) == $xox(PATTERN)} {
	    	#puts "Instrument Guide"
	} else {
		switch $m {
			0	{
				#puts "Show Last Measure"
				set mo(oldmeasure) $mo(measure)
				set target [llength $tl($mo(current_track))]
				set mo(measure) [measure_constrain $target]
				pattern_show
			}
			1	{
				#puts "Restore measure $mo(oldmeasure)"
				set mo(measure) [measure_constrain $mo(oldmeasure)]
				pattern_show
			}
			2	{
				#puts "Go to Last Measure"
				set target [llength $tl($mo(current_track))]
				set mo(measure) [measure_constrain $target]
				pattern_show
			}
			3	{
				return
			}
		}
	}

}
proc select_laststep {} {
	upvar #0 mode mo

	if {[winfo exists .ls]} {
		wm deiconify .ls
	} else {
		toplevel .ls
		wm title .ls "Set last pattern step"
		scale .ls.s -from 1 -to 16 -command laststep_set -orient horizontal	\
			-length 5c -relief groove -borderwidth 2
		button .ls.ok -text OK -font *-${font12}-* -command {wm iconify .ls} -relief groove -borderwidth 2
		pack .ls.s -side top -ipady 6
		pack .ls.ok -side top -expand true -fill x
	}
	.ls.s set [tk7_get_last_step $mo(patgroup) $mo(current_pattern)]
}
proc laststep_set val {
	upvar #0 mode mo

	if {$val < 1 || $val > 16} {
		return
	}
	tk7_set_last_step $mo(patgroup) $mo(current_pattern) $val
}
proc flam_set val {
	upvar #0 mode mo
	if {$val < 0 || $val > 4} {
		return
	}
	tk7_set_flam $mo(patgroup) $mo(current_pattern) $val
}
proc select_flam {} {
	global font12
	upvar #0 mode mo

	set curr [tk7_get_flam $mo(patgroup) $mo(current_pattern)]

	if {[winfo exists .flam]} {
		wm deiconify .flam
	} else {
		toplevel .flam
		wm title .flam "Set pattern flam interval"
		scale .flam.s -from 0 -to 4 -command flam_set -orient horizontal	\
			-length 5c -relief groove -borderwidth 2
		button .flam.ok -text OK -font *-${font12}-* -command {wm iconify .flam} -relief groove -borderwidth 2
		pack .flam.s -side top -ipady 6
		pack .flam.ok -side top -expand true -fill x
	}
	.flam.s set [tk7_get_flam $mo(patgroup) $mo(current_pattern)]
	set curr [tk7_get_flam $mo(patgroup) $mo(current_pattern)]
}
proc ac_flam {} {
	upvar #0 mode mo
	upvar #0 tkxox xox
	if {$mo(patr) != $xox(PATTERN) || $mo(rdrw) != $xox(WRITE)} {
	    return
	}
	select_flam
}
proc ac_midi {} {
	global font12
	upvar #0 mode mo
	if {[winfo exists .ms]} {
		wm deiconify .ms
	} else {
		toplevel .ms
		wm title .ms "MIDI Channel"
		scale .ms.s -from 1 -to 16 -command midichan_set -orient horizontal	\
			-length 5c -relief groove -borderwidth 2 -font *-${font12}-*
		button .ms.ok -text OK -font *-${font12}-* -command {wm iconify .ms} \
			-relief groove -borderwidth 2
		pack .ms.s -side top -ipady 6
		pack .ms.ok -side top -expand true -fill x
		.ms.s set [expr $mo(midi_channel)  + 1]
	}
}
proc midichan_set val {
	upvar #0 mode mo
	global midi_channel

	if {$val < 1 || $val >16} {
		return
	}
	set mo(midi_channel) [expr $val - 1]
	# This is needed for C code to trace midi channel,
	# (I don't know how to make it trace an array variable).
	set midi_channel $mo(midi_channel)
}
proc ac_note {widget prop} {
    global tapwrite
    global notes
    upvar #0 tkxox xox
    upvar #0 mode mo

    # Extract button number from widget path
    # Dependent on prefix path name: $notes.note.b0, $notes.note.b1, ..
    #                                      ^ +5 ^
    set prefix_length [expr [string length $notes] + 5]
    set b [string range [string trimright $widget .b] $prefix_length end]

    if {$mo(patr) == $xox(TRACK)} {
	# TRACK mode
	if {$mo(rdrw) == $xox(READ)} {
		tk7_start_note_play $b $prop
	} else {
		# Just changeing pattern numbers
		pattern_setid $b
	}
	return
    }
    # PATTERN mode
    if {$mo(rdrw) == $xox(READ)} {
    	# PATTERN READ mode
	pattern_setid $b
	if {$mo(stopgo) == $xox(START)} {
	    # If running, wait till current pattern finished before changeing ?
	}
	return
    }
    # PATTERN TAP or WRITE mode
    if {$mo(stopgo) != $xox(START)} {
	# Just changeing pattern numbers
	pattern_setid $b
	return
    }
    # PATTERN TAP or WRITE mode with START
    if {![have_zero_velocity $prop]} {
	switch $mo(current_accent) {
	    2       {set prop [add_strong_accent    $prop] }
	    1 	    {set prop [add_weak_accent      $prop] }
	    default {set prop [add_default_velocity $prop] }
	}
    }
    if {$tapwrite} {
	set step [expr [tk7_get_pat_tick] % 16]
	if {$step < 0} {
	    set step 0
	}
	ac_newinstr $notes.note$b.b
	step_insert $step $prop
	tk7_start_note_play $b $prop
    } else {
	# Recording steps
	step_insert $b $prop
    }
}
proc ac_note_off {widget} {
    global notes
    global tapwrite
    upvar #0 tkxox xox
    upvar #0 mode mo

    # Extract button number from widget path
    # Dependent on prefix path name: $notes.note.b0, $notes.note.b1, ..
    #                                      ^ +5 ^
    set prefix_length [expr [string length $notes] + 5]
    set b [string range [string trimright $widget .b] $prefix_length end]

    if {$mo(patr) == $xox(TRACK) && $mo(rdrw) == $xox(READ)} {
	tk7_stop_note_play $b
	return
    }
    if {$mo(rdrw) == $xox(READ) || $mo(stopgo) != $xox(START)} {
	return
    }
    if {$tapwrite} {
	tk7_stop_note_play $b
	return
    }
}
#
# Accept 0->15 to set new current pattern id.
# Also need to light buttons lamp.
#
proc pattern_setid {id} {
	global grid
	global notes
	upvar #0 pattern_list pl
	upvar #0 mode mo

	lamp_onoff 0 $notes.note$mo(current_pattern).l
	set mo(current_pattern) $id
	lamp_onoff 1 $notes.note$id.l

	# Clear the grid display & redraw for new pattern
	$grid delete stepnode
	set pg $mo(patgroup)
	set cp $mo(current_pattern)
	for {set k 0} {$k < 16} {incr k} {
		set instruments [tk7_pattern_items $pg $cp $k]
		set properties  [tk7_get_pattern_properties $pg $cp $k]
		set idx 0
		foreach instr $instruments {
	                set prop  [lindex $properties $idx]
			step_draw [expr $k + 1] $instr $prop
			set idx [expr $idx + 1]
		}
	}
	scale_lamps_update
	refresh_comment
}
# Turn a "lamp" on or off (1 or 0 for parameter onoff).
# Parameter lamp is a full widget path.
#
proc lamp_onoff {onoff lamp} {
	upvar #0 tkxox xox

	switch $onoff {
		0 {
			$lamp configure -bg $xox(col_def_bg)
		}
		1 {
			$lamp configure -bg $xox(col_on)
		}
	}
}

# Respond to change of Track/Pattern controls
#
proc ac_patternmode {rw} {
	global trpa notes tempoinfo
	upvar #0 mode mo
	upvar #0 tkxox xox

	# Check if running (can't change mode)
	if {$mo(stopgo) == $xox(START)} {
		return
	}

	if {$mo(patr) != $xox(PATTERN)} {
		set mo(patr) $xox(PATTERN)
		$tempoinfo itemconfigure tmtitle  -text TEMPO
		$tempoinfo coords tmtitle 1c 0.5c
		trace vdelete mo(current_track) w trackinfo_update
		trace vdelete mo(measure) w measureinfo_update
		$tempoinfo itemconfigure tempo -text $mo(tempo)
		trace variable mo(tempo) w tempoinfo_update
	}

	if {$rw == $xox(WRITE)} {
		set mo(rdrw) $xox(WRITE)
		$trpa.lt configure -text PLAY
		$trpa.lb configure -text "-> WRITE <-"
		modeinfo_update 3
	} else {
		set mo(rdrw) [expr $xox(WRITE) - 1]
		$trpa.lt configure -text "-> PLAY <-"
		$trpa.lb configure -text "WRITE"
		modeinfo_update 2
	}

	# Show current instrument
	ac_newinstr $notes.note[expr $mo(current_instr) - 1].b
}
proc ac_trackmode {rw} {
	global trpa notes tempoinfo
	upvar #0 mode mo
	upvar #0 tkxox xox
	upvar #0 track_list tl

	# Check if running (can't change mode)
	if {$mo(stopgo) == $xox(START)} {
		return
	}

	if {$mo(patr) != $xox(TRACK)} {
		set mo(patr) $xox(TRACK)
		$tempoinfo itemconfigure tmtitle -text MEASURE
		$tempoinfo coords tmtitle 2.7c 0.5c
		# Go to 1st pattern of new track
		# Trace current measure in track
		trace vdelete mo(tempo) w tempoinfo_update
		trace variable mo(measure) w measureinfo_update
		trace variable mo(current_track) w trackinfo_update
	}

	if {$rw == $xox(WRITE)} {
		set mo(rdrw) $xox(WRITE)
		$trpa.lt configure -text PLAY
		$trpa.lb configure -text "-> WRITE <-"
		modeinfo_update 1
	} else {
		set mo(rdrw) $xox(READ)
		$trpa.lt configure -text "-> PLAY <-"
		$trpa.lb configure -text WRITE
		modeinfo_update 0
	}
	set mo(measure) [measure_constrain -1]
	pattern_show

	# Hide current instrument
	ac_newinstr $notes.note[expr $mo(current_instr) - 1].b
}
# Toggle display to show tempo or measure
#
proc ac_tempomeasure {} {
	global tempoinfo
	upvar #0 mode mo
	upvar #0 tkxox xox

	if {$mo(patr) == $xox(PATTERN)} {
		return
	}

	if {$mo(showtrack)} {
		set mo(showtrack) false
		$tempoinfo itemconfigure tmtitle  -text TEMPO
		$tempoinfo coords tmtitle 1c 0.5c
#		trace vdelete mo(measure) w trackinfo_update
		trace vdelete mo(measure) w measureinfo_update
		$tempoinfo itemconfigure tempo -text $mo(tempo)
		trace variable mo(tempo) w tempoinfo_update
set mo(tempo) $mo(tempo)
	} else {
		set mo(showtrack) true
		$tempoinfo itemconfigure tmtitle -text MEASURE
		$tempoinfo coords tmtitle 2.7c 0.5c
		# Trace current measure in track
		trace vdelete mo(tempo) w tempoinfo_update
		trace variable mo(measure) w measureinfo_update
		trace variable mo(current_track) w trackinfo_update
set mo(measure) $mo(measure)
set mo(current_track) $mo(current_track)
	}

}

proc ac_stopgo {new} {
	upvar #0 tkxox xox
	upvar #0 mode mo
	upvar #0 track_list tl

	switch $new {
		0 {
			set mo(stopgo) $xox(STOP)
			set mo(PATTERN_REPEAT) false
			stop_pattern
			set stepcount [tk7_get_last_step $grp $pat]
			cycle_notes 1 0 0 0 $stepcount
		}
		1 {
			if {$new == $mo(stopgo)} {
				return
			}
			if {$mo(patr) == $xox(TRACK)} {
				set mo(TRACK_START) true
			}

			set mo(stopgo) $xox(START)


			# This starts the player!
			set mo(PATTERN_REPEAT) true
		}
		2 {
			if {$mo(patr) == $xox(PATTERN)} {
				set mo(PATTERN_REPEAT) false
				stop_pattern
				set mo(stopgo) $xox(STOP)
			} else {
				if {$mo(stopgo) == $xox(CONT)} {
					set mo(stopgo) $xox(START)
				} else {
					set mo(stopgo) $xox(CONT)
					set mo(PATTERN_REPEAT) false
					stop_pattern
				}
			}
		}
	}
}

# For patterns,
# i = 0->3 Groups
# j = 0->15 Patterns
# k = 0->15 Step divisions, each is a list of note events
#
# For tracks,
# i = 0->3 Tracks, each is a list patterns (16*Group + Pattern)
#
proc mem_init {} {
	upvar #0 pattern_list pl
	upvar #0 track_list tl

	# Patterns
#	for {set i 0} {$i <4} {incr i} {
#		for {set j 0} {$j <16 } {incr j} {
#			for {set k 0} {$k < 16} {incr k} {
#				set pl($i,$j,$k) {}
#			}
#		}
#	}

	# Tracks
	for {set i 0} {$i <4} {incr i} {
		set tl($i) {}
	}
	
}

proc ac_group {b} {
	global grps

	upvar #0 mode mo
	upvar #0 tkxox xox
	global comment

	if {$mo(rdrw) == $xox(WRITE) && $mo(stopgo) == $xox(START)} {
		return
	} else {
		set but_old ${grps}.lt$mo(patgroup).lamp
		set but_new ${grps}.lt${b}.lamp
		$but_old configure -background $xox(lamp_off)
		$but_new configure -background $xox(lamp_on)
		set mo(patgroup) $b
		if {$mo(patr) == $xox(TRACK)} {
			return
		}
		pattern_setid $mo(current_pattern)
	}
}

proc ac_track {b} {
	global tminfo
	upvar #0 mode mo
	upvar #0 tkxox xox

	if {$mo(patr) != $xox(TRACK) || $mo(stopgo) == $xox(START)} {
		return
	}
	set mo(current_track) $b
	set mo(measure) [measure_constrain -1]
	pattern_show
}

proc ac_newinstr {widget} {
	global gridlabel
	global notes
	global font12
	global boldfont13
	upvar #0 tkxox xox
	upvar #0 mode mo

	# Check first that we're in PATTERN:WRITE mode
	if {$mo(patr) == $xox(TRACK) || $mo(rdrw) == $xox(READ)} {
		set w $notes.note[expr $mo(current_instr) - 1].instr
		if {[winfo exists $w]} {
			lamp_onoff 0 $w
		}
		return
	}
	# Extract button number from widget path
	# Dependent on prefix path name: $notes.note.b0, $notes.note.b1, ..
	#                                      ^ +5 ^
	set prefix_length [expr [string length $notes] + 5]
	set b [string range [string trimright $widget .b] $prefix_length end]
	lamp_onoff 0 $notes.note[expr $mo(current_instr) - 1].instr
	set mo(current_instr) [expr $b + 1]
	lamp_onoff 1 $notes.note$b.instr

	$gridlabel itemconfigure selectinstr -font *-${font12}-*
	$gridlabel dtag selectinstr
	$gridlabel itemconfigure ilabel[expr 15 - $b] -font *-${boldfont13}-*
	$gridlabel addtag selectinstr withtag ilabel[expr 15 - $b]
}

# Change memory cartridge being used
#
proc ac_cartridge {} {
	global accenter
	upvar #0 mode mo
	upvar #0 tkxox xox

	if {$mo(patr) != $xox(TRACK)} {
		return
	}

	set mo(cartridge) [tk7_cartridge_incr]
	#puts "Cartridge $mo(cartridge)"
	switch $mo(cartridge) {
		2	{
			$accenter.cart.lamp configure -bg #00ff00
		}
		1	{
			$accenter.cart.lamp configure -bg $xox(lamp_on)
		}
		0	-
		default	{
			$accenter.cart.lamp configure -bg $xox(lamp_off)
		}
	}

}

# Process Enter button
#
proc ac_accenter {addmode} {
	global accent_label
	upvar #0 mode mo
	upvar #0 tkxox xox
	upvar #0 track_list tl

	if {$mo(patr) == $xox(PATTERN) && $mo(rdrw) == $xox(WRITE)} {
		set mo(current_accent) [expr ($mo(current_accent)+1) % 3]
		switch $mo(current_accent) {
		    2       {set color $xox(col_strong_accent) }
		    1 	    {set color $xox(col_weak_accent) }
		    default {set color $xox(col_def_bg) }
		}
		$accent_label configure -bg $color
		return
	}
	if {$mo(patr) != $xox(TRACK) || $mo(rdrw) != $xox(WRITE)} {
		return
	}
	# Track Write
	switch $addmode {
		0	{
			# Add/replace current pattern in current track
			#puts "ADD pattern"
			set target $mo(measure)
			#puts "Target measure is $target"
			set pat [expr [expr 16 * $mo(patgroup)] + $mo(current_pattern)]
			if {[lindex $tl($mo(current_track)) $target] == ""} {
				#puts "Adding $pat to Track $mo(current_track)"
				lappend tl($mo(current_track)) $pat
			} else {
				set tl($mo(current_track)) [lreplace $tl($mo(current_track)) $target $target $pat]
				#puts "Inserting $pat to Track $mo(current_track)"
			}
		}
		1	{
			# Insert pattern before current position in track
			#puts "INSERT pattern"
			set target $mo(measure)
			#puts "Target measure is $target"
			set pat [expr [expr 16 * $mo(patgroup)] + $mo(current_pattern)]
			if {[lindex $tl($mo(current_track)) $target] == ""} {
			#puts "Adding $pat to Track $mo(current_track)"
				lappend tl($mo(current_track)) $pat
			} else {
				set tl($mo(current_track)) [linsert $tl($mo(current_track)) $target $pat]
				#puts "Inserting $pat to Track $mo(current_track)"
			}
		}
	}
	# Go to next step
	ac_lastfwd
}

proc have_fla {prop} {
    upvar #0 tkxox xox
    return [expr $prop & $xox(flam)];
}
proc have_weak_accent {prop} {
    upvar #0 tkxox xox
    return [expr $prop & $xox(weak_accent)];
}
proc have_strong_accent {prop} {
    upvar #0 tkxox xox
    return [expr $prop & $xox(strong_accent)];
}
proc have_zero_velocity {prop} {
    upvar #0 tkxox xox
    return [expr $prop & $xox(zero_velocity)];
}
proc set_velocity_flag {prop flag} {
    upvar #0 tkxox xox
    return [expr $prop & (~$xox(velocity_field)) | ($flag & $xox(velocity_field))]
}
proc add_weak_accent {prop} {
    upvar #0 tkxox xox
    return [set_velocity_flag $prop $xox(weak_accent)]
}
proc add_strong_accent {prop} {
    upvar #0 tkxox xox
    return [set_velocity_flag $prop $xox(strong_accent)]
}
proc add_zero_velocity {prop} {
    upvar #0 tkxox xox
    return [set_velocity_flag $prop $xox(zero_velocity)]
}
proc add_default_velocity {prop} {
    upvar #0 tkxox xox
    return [expr $prop & (~$xox(velocity_field))]
}
#
# Draw a step node in the grid canvas.
# Parameters step & inst are expected in 1->16 format (not 0->15).
#
proc step_draw {step inst prop} {
	global grid
    	upvar #0 tkxox xox

	set x [expr $step / 2.0]
	set y [expr 9.0 - [expr $inst / 2.0]]
	if {[have_strong_accent $prop]} {
	    set color $xox(col_strong_accent)
	} elseif {[have_weak_accent $prop]} {
	    set color $xox(col_weak_accent)
	} elseif {[have_zero_velocity $prop]} {
	    set color $xox(col_zero_velocity)
	} else {
	    set color $xox(col_default_velocity)
	}
	if {[have_fla $prop]} {
	  # draw a star
	  set new [$grid create polygon \
		 [expr $x - (0)]c           [expr $y - (0.1875)]c \
		 [expr $x - (-0.0681818)]c  [expr $y - (0.0681818)]c \
		 [expr $x - (-0.1875)]c     [expr $y - (0.0681818)]c \
		 [expr $x - (-0.102273)]c   [expr $y - (-0.0426136)]c \
		 [expr $x - (-0.127841)]c   [expr $y - (-0.1875)]c \
		 [expr $x - (-0.00852273)]c [expr $y - (-0.127841)]c \
		 [expr $x - (0.119318)]c    [expr $y - (-0.1875)]c \
		 [expr $x - (0.102273)]c    [expr $y - (-0.0511364)]c \
		 [expr $x - (0.1875)]c      [expr $y - (0.0681818)]c \
		 [expr $x - (0.0681818)]c   [expr $y - (0.0681818)]c \
		 [expr $x - (0)]c           [expr $y - (0.1875)]c \
		-outline $color \
		-fill    $color \
		-tags stepnode]
	} else {
	  # draw a circle
	    set new [$grid create oval \
		[expr $x - 0.1875]c [expr $y - 0.1875]c	\
		[expr $x + 0.1875]c [expr $y + 0.1875]c \
		-outline black \
		-fill    $color \
		-tags stepnode]
	}
	$grid addtag ${step}_instr$inst withtag $new
}
#
# Insert given step into current pattern with specified properties
#
proc step_insert {step prop} {
	global grid
	global tapwrite

	upvar #0 mode mo
	upvar #0 tkxox xox
	upvar #0 pattern_list pl

	#puts "Inserting $mo(current_instr) at step $step into bank $mo(patgroup), pattern $mo(current_pattern)"
	# First check for duplicates (=> remove)
	set pg   $mo(patgroup)
	set cp   $mo(current_pattern)
	set note $mo(current_instr)
	if {[tk7_add_note $pg $cp $step $note]} {
		tk7_set_properties $pg $cp $step $note $prop
		step_draw [expr $step + 1] $mo(current_instr) $prop
		#puts "added note"
	} else {
		$grid delete [expr $step + 1]_instr$mo(current_instr)
		#puts "deleted note"
	}
}
#
# ClearGrid Display Area
#
proc grid_clear {} {
	global grid

	# Vertical lines
	set xcoord 0.0
	for {set i 0} {$i < 16} {incr i} {
		set xcoord [expr $xcoord + 0.5]
		$grid create line ${xcoord}c 0.5c ${xcoord}c 9.0c -fill #aaaaaa
	}
	# Horizontal lines
	set ycoord 0.5
	for {set i 0} {$i < 16} {incr i} {
		set ycoord [expr $ycoord + 0.5]
		$grid create line 0.0c ${ycoord}c 8.5c ${ycoord}c -fill #aaaaaa
	}
}
# -----------------------------------------------------------------------------
# Load sound map
# -----------------------------------------------------------------------------
set last_map_file_name "";

proc load_sound_map {initialdir} {

	# From TK-707 version 0.6, the format of .map files is changed
	#	(they now include also abbreviation information, for volume labels).
	# New format is recognized by number of saved data segments (4 rather than 3).

	upvar #0 sound snd
	upvar #0 last_map_file_name last_map_file_name

	set ftypes	{
		{{TK707 Sound Map} {.map}}
		{{All types} {.*}}
	}
	set fname [tk_getOpenFile -filetypes $ftypes -initialdir $initialdir ]

	if {$fname == ""} {
		return
	}
	set last_map_file_name [lindex [split $fname /] end];

	set f [open $fname r]
	set data ""
	set i 1
	while {[gets $f line] >= 0} {
		if {[string index $line 0] == "#"} {
			continue
		}
		set data [lindex $line 0]
		set datasegs [llength $data]
		set snd($i,name) [lindex $data 0]
		set snd($i,shortname) [lindex $data 1]
		if {$datasegs == 4} {
		    set snd($i,abbrev) [lindex $data 2]
		    set snd($i,note) [lindex $data 3]
		} else {
		    # we could set a better algo to abbrev
		    set snd($i,abbrev) $snd($i,shortname)
		    set snd($i,note) [lindex $data 2]
		}
		incr i
	}
	close $f

	# Reset Name Displays
	instrument_label_reset
	tk7_set_sounds
}
# -----------------------------------------------------------------------------
# Save sound map
# -----------------------------------------------------------------------------
proc save_sound_map {} {

	upvar #0 tkxox xox
	upvar #0 sound snd
	upvar #0 last_map_file_name last_map_file_name

	set ftypes	{
		{{TK707 Sound Map} {.map}}
		{{All types} {.*}}
	}
	#puts "last_map_file_name before: $last_map_file_name"
	set fname [tk_getSaveFile -filetypes $ftypes -initialfile $last_map_file_name]
	if {$fname == ""} {
		return
	}
	set last_map_file_name [lindex [split $fname /] end];

	set f [open $fname w]
	puts $f "#################  TK707 Sound Map generated by $xox(VERSION)  #################"
	puts $f "# Format is 16 entries of { {Long name} {Short name} {Abbrev} {Midi key value} }"
	puts $f "############################################################################"
	for {set i 1} {$i < 17} {incr i} {
		puts $f "{ {$snd($i,name)} {$snd($i,shortname)} {$snd($i,abbrev)} {$snd($i,note)} }"
	}
	close $f
}
# -----------------------------------------------------------------------------
# Load data file
# -----------------------------------------------------------------------------
set last_data_file_name "";

proc load_data_file {initialdir} {

	# From TK-707 version 0.7, the format of .dat files is changed
	#	(they now include also note properties information).
	# New format is recognized by number of saved data segments (5 rather than 2, 3 or 4).
	# They are:
	#	segment 0: pattern note data
	#	segment 1: pattern note properties
	#	segment 2: pattern {length,scale,flam,shuffle} properties
	#	segment 3: track data

	# From TK-707 version 0.6, the format of .dat files is changed
	#	(they now include also pattern scale information).
	# New format is recognized by number of saved data segments (4 rather than 2 or 3).
	# They are:
	#	segment 0: pattern note data
	#	segment 1: pattern length data
	#	segment 2: pattern scale data
	#	segment 3: track data

	# From TK-707 version 0.5, the format of .dat files is changed
	#	(they now include pattern length information).
	# New format is recognized by number of saved data segments (3 rather than 2).
	# They are:
	#	segment 0: pattern note data
	#	segment 1: pattern length data
	#	segment 2: track data

	upvar #0 track_list tl
	upvar #0 mode mo
	upvar #0 last_data_file_name last_data_file_name

	set ftypes	{
		{{TK-707 Data} {.dat}}
		{{All types} {.*}}
	}
	set fname [tk_getOpenFile -filetypes $ftypes -initialdir $initialdir]
	if {$fname == ""} {
		return
	}
	set last_data_file_name [lindex [split $fname /] end];
	#puts "LOAD last_data_file_name $last_data_file_name"

	set f [open $fname r]
	set data ""
	while {[gets $f line] >= 0} {
		if {[string index $line 0] == "#"} {
			continue
		}
		set data "$data [string trim $line]"
	}
	close $f

	# ----------------------------------
	# find format version from structure
	# ----------------------------------
	set datasegs [llength [lindex $data 0]]
	set data_version "unknown";
	if {$datasegs == 2} {
	    set data_version 2;
	} elseif {$datasegs == 3} {
	    set data_version 5;
	} elseif {$datasegs == 4} {
	    set segment2 [lindex [lindex $data 0] 2]
	    set n_seg2_level2 [llength [lindex [lindex $segment2 0] 0]]
	    if {$n_seg2_level2 == 1} {
	        set data_version 6;
	    } elseif {$n_seg2_level2 >= 4} {
	        set data_version 7;
	    }
	}
	#puts "data_version $data_version"
	if {$data_version == "unknown"} {
	    puts "ERROR: ${fname}: unexpected data format";
	    return;
	}
	# ----------------------------------
	# load segments
	# ----------------------------------
	set loadsegment 0
	tk7_clear_tree
	set pdata [lindex [lindex $data 0] $loadsegment]	;	#Pattern data
	set i 0
	foreach bankdata $pdata {
		set j 0
		foreach patterndata $bankdata {
			set k 0
			foreach stepdata $patterndata {
				if {[llength $stepdata] > 0} {
					foreach n $stepdata {
						tk7_add_note $i $j $k $n
					}
				}
				incr k
			}
			incr j
		}
		incr i
	}
	incr loadsegment

	if {$data_version >= 7} {
	    # format version 0.7 includes note properties: flam, accents, etc...
	    set p_prop [lindex [lindex $data 0] $loadsegment]	;	#Pattern note properties
	    set p_data [lindex [lindex $data 0] 0]
	    set i 0
	    foreach bank_prop $p_prop {
	        set bank_data [lindex $p_data $i]
		set j 0
		foreach pattern_prop $bank_prop {
	            set pattern_data [lindex $bank_data $j]
		    set k 0
		    foreach step_prop $pattern_prop {
	                set step_data [lindex $pattern_data $k]
			if {[llength $step_prop] > 0} {
			    set idx_n 0
			    foreach p $step_prop {
	                        set n [lindex $step_data $idx_n]
			        tk7_set_properties $i $j $k $n $p
		        	incr idx_n
			    }
			}
		        incr k
		    }
		    incr j
		}
		incr i
	    }
	    incr loadsegment
	}
	pattern_setid $mo(current_pattern)

	if {$data_version >= 5} {
		# format version 0.5 and 0.6 includes length info.
	    	# format version 0.7 includes {length,scale,flam,shuffle} infos.
		set pdata [lindex [lindex $data 0] $loadsegment] ; #Step length data
		set grp 0
		foreach grpdata $pdata {
			set pat 0
			foreach pldata $grpdata {
				if {$data_version >= 7} {
				    # from TK-707 version 0.7: {length,scale,flam,shuffle} infos.
				    tk7_set_last_step $grp $pat [lindex $pldata 0]
				    tk7_set_scale     $grp $pat [lindex $pldata 1]
				    tk7_set_flam      $grp $pat [lindex $pldata 2]
				    tk7_set_shuffle   $grp $pat [lindex $pldata 3]
				    if {[llength $pldata] >= 5} {
				      tk7_set_pattern_comment  $grp $pat [lindex $pldata 4]
				    }
				} else {
				    # TK-707 version 0.5 and 0.6: step length info.
				    tk7_set_last_step $grp $pat $pldata
				}
				incr pat
			}
			incr grp
		}
		incr loadsegment
	}
	if {$data_version == 6} {
		# format version 0.6 includes step scale info.
		set pdata [lindex [lindex $data 0] $loadsegment] ; #Step scale data
		set grp 0
		foreach grpdata $pdata {
			set pat 0
			foreach pldata $grpdata {
				set scaleresult  [tk7_set_scale $grp $pat $pldata]
				incr pat
			}
			incr grp
		}
		incr loadsegment
	}
	set pdata [lindex [lindex $data 0] $loadsegment]	;	#Track data
	set i 0
	foreach trackdata $pdata {
		#puts $trackdata
		set tl($i) [join $trackdata]
		incr i
	}
	ac_track 0
	pattern_show
}
# -----------------------------------------------------------------------------
# Save data file
# -----------------------------------------------------------------------------
proc reverse {l1} {
    set n  [llength $l1]
    set l2 {}
    for {set i [expr $n - 1]} {$i >= 0} {set i [expr $i - 1]} {
        lappend l2 [lindex $l1 $i]
    }
    return $l2
}
proc save_data_file {} {

	upvar #0 pattern_list pl
	upvar #0 track_list tl
	upvar #0 tkxox xox
	upvar #0 mode mo
	upvar #0 last_data_file_name last_data_file_name

	set ftypes	{
		{{TK-707 Data} {.dat}}
		{{All types} {.*}}
	}
	#puts "PREV last_data_file_name $last_data_file_name"
	set fname [tk_getSaveFile -filetypes $ftypes -initialfile $last_data_file_name]
	if {$fname == ""} {
		return
	}
	set last_data_file_name [lindex [split $fname /] end];
	#puts "NEW last_data_file_name $last_data_file_name"

	set f [open $fname w]
	puts $f "####################### MACHINE GENERATED - DO NOT EDIT #######################"
	puts $f "####   TK707 Data file generated by $xox(VERSION)"
	puts $f "###############################################################################"
	puts $f "{"							;	# Begin DATA

	# PATTERN NOTES. Four groups of 16 patterns each with 16 steps.
	puts $f " {"							;	# Begin PATTERNS
	for {set i 0} {$i<4} {incr i} {
	    puts $f "  {"						;	# Begin GROUP i
	    for {set j 0} {$j<16} {incr j} {
		puts $f "   {"						;	# Begin PATTERN j
		for {set k 0} {$k<16} {incr k} {
		    set instruments [tk7_pattern_items $i $j $k]
		    set instruments [reverse $instruments]
		    puts $f "    { $instruments }"
		}
		puts $f "   }"						;	# End PATTERN j
	    }
	    puts $f "  }"						;	# End GROUP i
	}
	puts $f " }"							;	# End PATTERNS

	# PATTERN NOTES PROPERTIES. Four groups of 16 patterns each with 16 steps.
	puts $f " {"							;	# Begin PATTERNS
	for {set i 0} {$i<4} {incr i} {
	    puts $f "  {"						;	# Begin GROUP i
	    for {set j 0} {$j<16} {incr j} {
		puts $f "   {"						;	# Begin PATTERN j
		for {set k 0} {$k<16} {incr k} {
		    set properties [tk7_get_pattern_properties $i $j $k]
		    set properties [reverse $properties]
		    puts $f "    { $properties }"
		}
		puts $f "   }"						;	# End PATTERN j
	    }
	    puts $f "  }"						;	# End GROUP i
	}
	puts $f " }"							;	# End PATTERNS

	# PATTERN PROPERTIES. Four lots of sixteen 4-lists. New from TK-707 version 0.7
	puts $f  " {"							;	# Begin PATTERN PROPERTIES
	for {set i 0} {$i<4} {incr i} {
		set pat_props [tk7_group_pattern_properties $i]		; 	# Group step lengths 
		puts $f "  { $pat_props }"				; 	# Group step lengths 
	}
	puts $f  " }"							;	# End PATTERN PROPERTIES

	# TRACK DATA. Four tracks of arbitrary length.
	puts $f " {"							;	# Begin TRACKS
	for {set i 0} {$i<4} {incr i} {
		puts $f "  { $tl($i) }"					;	# TRACK i data
	}
	puts $f " }"							;	# End TRACKS
	puts $f "}"							;	# End DATA
	close $f
}
# --------------------
# compute the velocity
# --------------------
# velocity range is 0..127 as integer
# volume   range is 0..1   as float
proc compute_velocity {prop volume_master volume_accent volume_instr} {

    if {[have_zero_velocity $prop]} {
	set velocity_factor 0
    } else {
    	set velocity_factor 1
    }
    if {[have_strong_accent $prop]} {
	set accent_factor 1
    } elseif {[have_weak_accent $prop]} {
	set accent_factor 2/3.0
    } else {
	set accent_factor 1/3.0
    }
    set volume_note [expr  $volume_master \
	     	     	  *$velocity_factor*$volume_instr \
		      	  *$accent_factor*$volume_accent]
    set velocity [expr int(127 * $volume_note + 0.5)]
    return $velocity
}
# -----------------------------------------------------------------------------
# Save midi file - current track
# -----------------------------------------------------------------------------

set last_midi_file_name "";
set prev_data_file_name "";

proc put_note {f tick_shift midinote velocity} {
    if {$tick_shift > 127} {
        varlen_short shortres $tick_shift
	puts -nonewline $f [binary format c2 [list $shortres(high) $shortres(low)]]
	set size 2
    } else {
        puts -nonewline $f [binary format c1 $tick_shift]
	set size 1
    }
    puts -nonewline $f [binary format c2 [list $midinote $velocity]]
    return [expr $size + 2]
}
proc put_note_off {f tick_shift midinote} {
    return [put_note $f $tick_shift $midinote 0]
}
proc save_midi_file {} {
	global cunit
	global masterv

	upvar #0 mode mo
	upvar #0 tkxox xox
	upvar #0 sound snd
	upvar #0 track_list tl
	upvar #0 has_delay has_delay
	upvar #0 last_midi_file_name last_midi_file_name
	upvar #0 last_data_file_name last_data_file_name
	upvar #0 prev_data_file_name prev_data_file_name
	upvar #0 instrument_to_volume instrument_to_volume

	if {    ($last_data_file_name != "")
	    && (($prev_data_file_name == "") ||
	        ($prev_data_file_name != $last_data_file_name)) } {

	    # build a predefined name:
	    set x [lindex [split $last_data_file_name .] 0];
	    set t $mo(current_track)
	    set last_midi_file_name "${x}-track${t}.mid"
	}
	set ftypes	{
		{{Midi File Format} {.mid}}
		{{All types} {.*}}
	}
	set fname [tk_getSaveFile -filetypes $ftypes -initialfile $last_midi_file_name]
	if {$fname == ""} {
	    return
	}
	set last_midi_file_name [lindex [split $fname /] end];
	set prev_data_file_name $last_data_file_name

	set thirty_second_note_on_ratio 5; 	# customize the ratio !
						# ex1: ratio=3
						# => 1/3 note-on
						#    2/3 note-off, for a thirty-second 
						# ex2: ratio=16
						# => 1/16 note-on, 15/16 note-off
						# ex3: ratio=1
						# => 100 % note-on; not for percussions...

	set tick_per_note_on            3; 	# how long, in ticks, the note is on
						# DO NOT change ! because we may divide 
						# it per 3 quarters and eigth later...

	set tick_per_thirty_second      [expr  $thirty_second_note_on_ratio*$tick_per_note_on];
	set tick_per_quarter            [expr  8*$tick_per_thirty_second];

	# steps are in two parts:
	#	a note-on part, which have a duration independant of the scale (a hit)
	#	a note-off part, which depend on the scale:

	# scale(0): 1 step = quarter/4
        set tick_per_step_off_scale(0) [expr $tick_per_quarter/4 - $tick_per_note_on];

	# scale(1): 1 step = quarter/8
        set tick_per_step_off_scale(1) [expr $tick_per_quarter/8 - $tick_per_note_on];

	# scale(2): 1 step = quarter/3
        set tick_per_step_off_scale(2) [expr $tick_per_quarter/3 - $tick_per_note_on];

	# scale(3): 1 step = quarter/6
        set tick_per_step_off_scale(3) [expr $tick_per_quarter/6 - $tick_per_note_on];

	# ex1: ratio=3
	#     => tick_per_step_off_scale = {15   6  21   9}
	# ex1: ratio=16
	#     => tick_per_step_off_scale = {93   45  125   61}
	#        the grid is finer and the result is better
	# ex3: ratio=1
	#     => tick_per_step_off_scale = {3, 0, 5, 1}, as expected.
	#	 as expected, the thirty-second has no note-off part...

	#
	# get volumes:
	#
	set volume_master [expr [$masterv.sf.s get] / 100.0]
	#puts "volume_master $volume_master"
	set volume_accent [expr [$cunit.0.sf.s get] / 100.0]
	#puts "volume_accent $volume_accent"
	set volume_set {}
	for {set instrument 1} {$instrument <= 16} {incr instrument} {
	    set i_vol $instrument_to_volume($instrument)
	    set volume($instrument) [expr [$cunit.${i_vol}.sf.s get] / 100.0]
	    #puts "volume($instrument) $volume($instrument)"
	}
	for {set instrument 1} {$instrument <= 16} {incr instrument} {
	    set in_note($instrument) 0;
	}
	set f [open $fname w]
	puts -nonewline $f MThd
	puts -nonewline $f [binary format I 6]
	puts -nonewline $f [binary format S 0]
	puts -nonewline $f [binary format S 1]
	puts -nonewline $f [binary format S $tick_per_quarter]
	puts -nonewline $f MTrk
	set loc_tracksize 18
	puts -nonewline $f [binary format I 0]	; # Dummy tracksize

	# Meta Event to set track tempo
	set micro_tempo [expr 60000000 / $mo(tempo)]
	puts -nonewline $f [binary format c7 [list 0 255 81 3 [expr $micro_tempo >> 16] [expr $micro_tempo >> 8] $micro_tempo]]
	set tracksize 7

	# Establish running status with a zero volume note
	puts -nonewline $f [binary format c4 [list 0 [expr 144 + $mo(midi_channel)] 17 0]]
	incr tracksize 4

	set track $tl($mo(current_track))
	set tick_shift 0
	foreach patid $track {
	    set group     [expr $patid / 16]
	    set pattern   [expr $patid % 16]
	    set last_step [tk7_get_last_step $group $pattern]
	    set scale     [tk7_get_scale $group $pattern]
	    set step 0
	    while {$step < $last_step} {
		set instrument_set [tk7_pattern_items          $group $pattern $step]
		set property_set   [tk7_get_pattern_properties $group $pattern $step]
		set idx 0
		foreach instrument $instrument_set {
		    if {$instrument == ""} {
			#puts "EMPTY instrument ?? idx = $idx"
		        incr idx
			continue;
		    }
		    # ------------
		    # start a note
		    # ------------
		    set midinote $snd($instrument,note)
    		    set prop [lindex $property_set $idx]
		    set velocity [compute_velocity $prop $volume_master $volume_accent $volume($instrument)]
		    incr tracksize [put_note $f $tick_shift $midinote $velocity]
		    set tick_shift 0
		    if {! $has_delay($instrument) && ! [have_zero_velocity $prop]} {
			# start a note without delay
		        set in_note($instrument) 1
		    }
		    incr idx
		}
		set flam_interval [tk7_get_flam $group $pattern]
		set tick_per_flam [expr $xox(tick_flam_duration) * $flam_interval]
		incr tick_shift $tick_per_flam
		if {$flam_interval != 0} {
		    set idx 0
		    foreach instrument $instrument_set {
		        if {$instrument == ""} {
			    continue;
		        }
	  	        set prop [lindex $property_set $idx]
		        if {! [have_fla $prop]} {
			    continue;
		        }
		        # ----------------------
		        # write a fla note
		        # ----------------------
		        set midinote $snd($instrument,note)
    		        set prop [lindex $property_set $idx]
		        set velocity [compute_velocity $prop $volume_master $volume_accent $volume($instrument)]
		        incr tracksize [put_note $f $tick_shift $midinote $velocity]
		        set tick_shift 0
		        incr idx
		    }
		}
		incr tick_shift [expr $tick_per_note_on - $tick_per_flam]
		foreach instrument $instrument_set {
		    if {$instrument == ""} {
			continue;
		    }
		    if {! $has_delay($instrument)} {
			continue;
		    }
		    # ----------------------
		    # stop a note with delay
		    # ----------------------
		    set midinote $snd($instrument,note)
		    incr tracksize [put_note_off $f $tick_shift $midinote]
		    set tick_shift 0
		}
		incr tick_shift $tick_per_step_off_scale($scale)

		incr step
	    }
	}
	# stop current long notes on (whistle, etc...)
	for {set instrument 1} {$instrument <= 16} {incr instrument} {

		if {$in_note($instrument)} {

		 #puts "stop instrument $instrument";

		 set midinote $snd($instrument,note)
		 incr tracksize [put_note_off $f $tick_shift $midinote]
		 set tick_shift 0
	    }
	}
	# End of track
	puts -nonewline $f [binary format c 0]
	puts -nonewline $f [binary format c3 {255 47 0}]
	incr tracksize 4

	# Go back and insert tracksize
	flush $f
	seek $f $loc_tracksize
	puts -nonewline $f [binary format I $tracksize]
	close $f
}
# -----------------------------------------------------------------------------
# fileMidi - TEST area
# -----------------------------------------------------------------------------
proc fileAction {a} {
	upvar #0 pattern_list pl
	upvar #0 track_list tl
	upvar #0 tkxox xox
	upvar #0 mode mo

	if {$a == 99} {
		set ftypes	{
			{{Midi File Format} {.mid}}
			{{All types} {.*}}
		}
		set fname [tk_getSaveFile -filetypes $ftypes]
		if {$fname == ""} {
			return
		}
		set f [open $fname w]

		puts -nonewline $f MThd
		puts -nonewline $f [binary format I 6]
		puts -nonewline $f [binary format S 0]
		puts -nonewline $f [binary format S 1]
		puts -nonewline $f [binary format S 7]
		puts -nonewline $f MTrk
		set loc_tracksize 18
		puts -nonewline $f [binary format I 0]	; # Dummy tracksize

		puts -nonewline $f [binary format c2 [list 0 [expr 144 + $mo(midi_channel)]]]

		# Once running status is established, format is
		# {note onlevel pause note offlevel pause}
		puts -nonewline $f [binary format c12 {35 127 0 51 127 2 35 0 0 51 0 4}]
		puts -nonewline $f [binary format c6 {48 127 2 48 0 4}]
		puts -nonewline $f [binary format c6 {38 127 2 38 0 4}]
		puts -nonewline $f [binary format c6 {51 127 2 51 0 4}]

		# End of track
		puts -nonewline $f [binary format c3 {255 47 0}]

		set tracksize 35
		# Go back and insert tracksize
		flush $f
		seek $f $loc_tracksize
		puts -nonewline $f [binary format I $tracksize]
		close $f
	} else {
		puts "INTERNAL ERROR: Unexected file action: $a"
	}
}
proc varlen_short {result value} {
	upvar $result res

	if {$value < 128} {
		set res(high) 0
		set res(low) $value
	} else {
		set res(high) [expr 128 + [expr $value / 128]]
#		set res(high) [expr 65536 + [expr $value / 128]]
		set res(low) [expr $value % 128]
	}
}

#=============================================================
# These procs to edit mapping of note keys to midi note values
#
proc map_edit {} {
	global font12
	global boldfont12
	upvar #0 sound snd
	upvar #0 soundbuf sbuf
	upvar #0 tkxox xox

	if {[winfo exists .edit]} {
		wm deiconify .edit
	} else {
		toplevel .edit
		wm title .edit "Edit Sound Map"

		set m_titles .edit.t
		canvas $m_titles -height 0.75c -width 13.5c -relief raised -borderwidth 2
		pack $m_titles
		set m_maps .edit.m
		frame $m_maps
		pack $m_maps
		set m_opts	.edit.o
		canvas $m_opts -height 1.5c -width 13.5c
		pack $m_opts

		label $m_titles.key    -text "Key"        -font *-${boldfont12}-*
		label $m_titles.long   -text "Long Name"  -font *-${boldfont12}-*
		label $m_titles.short  -text "Short Name" -font *-${boldfont12}-*
		label $m_titles.abbrev -text "Abbrev"     -font *-${boldfont12}-*
		label $m_titles.note   -text "Note"       -font *-${boldfont12}-*
		label $m_titles.test   -text "Test"       -font *-${boldfont12}-*
		$m_titles create window  0c   0.45c -window $m_titles.key    -anchor w -width 1c
		$m_titles create window  1c   0.45c -window $m_titles.long   -anchor w -width 4c
		$m_titles create window  5.3c 0.45c -window $m_titles.short  -anchor w -width 2c
		$m_titles create window  7.5c 0.45c -window $m_titles.abbrev -anchor w -width 2c
		$m_titles create window 10.0c 0.45c -window $m_titles.note   -anchor w -width 1c
		$m_titles create window 11.7c 0.45c -window $m_titles.test   -anchor w -width 1c

		# Name, Shortname, Midi note entries
		#
		for {set i 0} {$i < 16} {incr i} {
			canvas $m_maps.$i -height 1c -width 13.5c
			label $m_maps.$i.l -text [expr $i + 1] -font *-${font12}-*
			entry $m_maps.$i.long  -font *-${font12}-*
			entry $m_maps.$i.short  -font *-${font12}-*
			entry $m_maps.$i.abbrev  -font *-${font12}-*
			entry $m_maps.$i.note  -font *-${font12}-*
			button $m_maps.$i.test \
				-bitmap nix \
				-bg $xox(but_grey) \
				-activebackground $xox(but_grey_active) \
				-width 1.0c -height 0.7c

			$m_maps.$i create window 0c   0.5c -window $m_maps.$i.l 	 -anchor w -width 1c
			$m_maps.$i create window 1c   0.5c -window $m_maps.$i.long -anchor w -width 4c
			$m_maps.$i create window 5c   0.5c -window $m_maps.$i.short -anchor w -width 2.5c
			$m_maps.$i create window 7.5c 0.5c -window $m_maps.$i.abbrev -anchor w -width 2.5c
			$m_maps.$i create window 10c  0.5c -window $m_maps.$i.note -anchor w -width 1c
			$m_maps.$i create window 11.2c 0.5c -window $m_maps.$i.test -anchor w -width 2.1c

			set j [expr $i + 1]
			$m_maps.$i.long insert 0 $snd($j,name)
			set sbuf($j,name) $snd($j,name)
			$m_maps.$i.short insert 0 $snd($j,shortname)
			set sbuf($j,shortname) $snd($j,shortname)
			$m_maps.$i.abbrev insert 0 $snd($j,abbrev)
			set sbuf($j,abbrev) $snd($j,abbrev)
			$m_maps.$i.note insert 0 $snd($j,note)
			set sbuf($j,note) $snd($j,note)
			pack $m_maps.$i

			bind $m_maps.$i.test <ButtonPress-1>    {map_start_test_note %W}
			bind $m_maps.$i.test <ButtonRelease-1>  {map_stop_test_note %W}

			bind $m_maps.$i.note <Shift-ButtonPress-1>   {map_start_set_note %W 1}
			bind $m_maps.$i.note <Shift-ButtonRelease-1> {map_stop_set_note %W}

			bind $m_maps.$i.note <Control-ButtonPress-1>   {map_start_set_note %W -1}
			bind $m_maps.$i.note <Control-ButtonRelease-1> {map_stop_set_note %W}

			bind $m_maps.$i.note <Button-2>  {
				set noteY %y
			}
			bind $m_maps.$i.note <B2-Motion> {
				set direction [expr %y - $noteY]
				if {$direction >= 0} {
				    set diff 1
				} else {
				    set diff -1
				}
				map_start_set_note %W $diff
				after 500;
				map_stop_set_note  %W
			}
		}

		# Cancel, Apply, OK buttons
		#
		button $m_opts.cancel -text Cancel -font *-${font12}-* -command {
			upvar #0 soundbuf buf
			for {set i 0} {$i < 16} {incr i} {
				set j [expr $i + 1]
				.edit.m.$i.long delete 0 100
				.edit.m.$i.long insert 0 $buf($j,name)
				set snd($j,name) $buf($j,name)

				.edit.m.$i.short delete 0 100
				.edit.m.$i.short insert 0 $buf($j,shortname)
				set snd($j,shortname) $buf($j,shortname)

				.edit.m.$i.abbrev delete 0 100
				.edit.m.$i.abbrev insert 0 $buf($j,abbrev)
				set snd($j,abbrev) $buf($j,abbrev)

				.edit.m.$i.note delete 0 end
				.edit.m.$i.note insert 0 $buf($j,note)
				set snd($j,note) $buf($j,note)
			}
			instrument_label_reset
			tk7_set_sounds
			destroy .edit
		}
		button $m_opts.apply -text Apply -font *-${font12}-* -command {
			map_set_new_sounds
		}
		button $m_opts.ok -text OK -font *-${font12}-* -command {
			map_set_new_sounds
			destroy .edit
		}
		$m_opts create window 1c 0.75c -window $m_opts.cancel -anchor w -width 2.5c
		$m_opts create window 4c 0.75c -window $m_opts.apply -anchor w -width 2.5c
		$m_opts create window 7c 0.75c -window $m_opts.ok -anchor w -width 2.5c
	}
}

proc map_set_new_sounds {} {
	global .edit
	upvar #0 sound snd
	upvar #0 soundbuf sbuf

	for {set i 0} {$i < 16} {incr i} {
		set j [expr $i + 1]
		set snd($j,name) [.edit.m.$i.long get]
		set snd($j,shortname) [.edit.m.$i.short get]
		set snd($j,abbrev) [.edit.m.$i.abbrev get]
		set snd($j,note) [.edit.m.$i.note get]
	}
	instrument_label_reset
	tk7_set_sounds
}

proc map_start_test_note widget {
	global .edit
	set k [string range [string trimright $widget .test] 8 end]
	set n [.edit.m.$k.note get]
	tk7_start_note_test $k $n
}
proc map_stop_test_note widget {
	global .edit
	set k [string range [string trimright $widget .test] 8 end]
	set n [.edit.m.$k.note get]
	tk7_stop_note_test $k $n
}
proc map_start_set_note {widget diff} {
	set newval [expr [$widget get] + $diff]
	set newval [expr $newval % 128]
	$widget delete 0 end
	$widget insert 0 $newval
	set k [string range [string trimright $widget .note] 8 end]
	tk7_start_note_test $k $newval
}
proc map_stop_set_note {widget} {
	set keynum    [string range [string trimright $widget .note] 8 end]
	set midi_note [$widget get]
	tk7_stop_note_test $keynum $midi_note
}
#=============================================================

#=====================================================
# These procs to edit mapping of instruments to faders
#
proc fader_edit {} {
	if {[winfo exists .fadermap]} {
		wm deiconify .fadermap
	} else {
		toplevel .fadermap
		wm title .fadermap "Edit Fader Map"

		text .fadermap.intro -width 64 -height 16
		.fadermap.intro insert end	\
"Editing of the Instrument to Fader map is not implemented yet.
The default mapping being used is:

Vol 0 (the first fader ) - unused
Vol 1	- Bass drums 1 & 2
Vol 2	- Snare drums 1 & 2
Vol 3	- Low Tom
Vol 4	- Mid Tom
Vol 5	- High Tom
Vol 6	- Rimshot & Cowbell
Vol 7	- Handclap & Tambourine
Vol 8	- Highhats (all)
Vol 9	- Crash cymbal
Vol 10	- Ride cymbal
VOLUME	- Master volume over all instruments
"

		button .fadermap.ok -text OK -command {destroy .fadermap}

		pack .fadermap.intro
		pack .fadermap.ok -expand true -fill x
	}

}
#=====================================================
#
# Flash the lamps for each of the 16 steps in 1 pattern
# (fix later for patterns with fewer steps)
#
#ex: cycle_notes 1 [expr 55 * 120 / $mo(tempo)] 0 0 $steps
proc cycle_notes {on dur w saved steps} {
	global notes
	upvar #0 tkxox xox
	upvar #0 mode mo
	upvar #0 flash fl

	if {$on == 1} {
		switch $mo(stopgo) {
		0	{
			#puts "stopgo = STOP"
			set fl(count) -1
			}
		1	{
			incr fl(count)
			if {$fl(count) > [expr $steps - 1]} {
				set fl(count) -1
				return
			}
			set savecolour [lindex [$notes.note$fl(count).l configure -bg] 4]
			set savedwin $notes.note$fl(count).l
			#puts "cycle $fl(count) ON "
			$savedwin configure -bg $xox(col_on)
			after $dur [list cycle_notes 0 $dur $savedwin $savecolour $steps]
			}
		2	{
			#puts "stopgo = CONT"
			}
		}
	} else {
#		#puts "cycle $fl(count) OFF"
		$w configure -bg $saved
		if {$mo(stopgo) != $xox(START)} {
			set fl(count) 15
			return
		}

		if {$fl(count) < $steps} {
			after $dur [list cycle_notes 1 $dur 0 0 $steps]
		} else {
			set fl(count) -1
			return
		}
	}

}
proc gridlabels_reset {} {
	global gridlabel
	global font12
	upvar #0 sound so
	for {set i 0} {$i < 16} {incr i} {
		$gridlabel itemconfigure ilabel$i -text $so([expr 16 - $i],name)	\
			-font *-${font12}-* -anchor e
	}
}
proc key_labels_reset {} {
	global notes
	upvar #0 sound so

	for {set i 0} {$i < 16} {incr i} {
		$notes.note$i.instr configure -text $so([expr $i + 1],shortname)
	}
}
proc volume_labels_reset {} {
	global cunit
	upvar #0 sound so
	upvar #0 volume_label vo

	if {$so(2,abbrev) != ""} {
	    set vo(1)  "$so(1,abbrev)/$so(2,abbrev)"
	} else {
	    set vo(1)  "$so(1,abbrev)"
	}
	if {$so(4,abbrev) != ""} {
	    set vo(2)  "$so(3,abbrev)/$so(4,abbrev)"
	} else {
	    set vo(2)  "$so(3,abbrev)"
	}
	set vo(3)  "$so(5,abbrev)"
	set vo(4)  "$so(6,abbrev)"
	set vo(5)  "$so(7,abbrev)"
	if {$so(9,abbrev) != ""} {
	    set vo(6)  "$so(8,abbrev)/$so(9,abbrev)"
	} else {
	    set vo(6)  "$so(8,abbrev)"
	}
	if {$so(11,abbrev) != ""} {
	    set vo(7)  "$so(10,abbrev)/$so(11,abbrev)"
	} else {
	    set vo(7)  "$so(10,abbrev)"
	}
	if {($so(13,abbrev) != "") && ($so(14,abbrev) != "")} {
	    set vo(8)  "$so(12,abbrev)/$so(13,abbrev)/$so(14,abbrev)"
	} elseif {$so(13,abbrev) != ""} {
	    set vo(8)  "$so(12,abbrev)/$so(13,abbrev)"
	} elseif {$so(14,abbrev) != ""} {
	    set vo(8)  "$so(12,abbrev)/$so(14,abbrev)"
	} else {
	    set vo(8)  "$so(12,abbrev)"
	}
	set vo(9)  "$so(15,abbrev)"
	set vo(10) "$so(16,abbrev)"

	for {set i 1} {$i < 11} {incr i} {
		$cunit.$i.l configure -text $vo($i)
	}
}
proc instrument_label_reset {} {
	gridlabels_reset
	key_labels_reset
	volume_labels_reset
}
proc tempoinfo_update {a b c} {
	global tempoinfo
	upvar $a mo
	$tempoinfo itemconfigure tempo -text $mo(tempo)
}
proc measureinfo_update {a b c} {
	global tempoinfo
	upvar $a mo
	upvar #0 tkxox xox
	upvar #0 track_list tl

	if {$mo(measure) == -1} {
		$tempoinfo itemconfigure tempo -text ""
	} else {
		$tempoinfo itemconfigure tempo -text [expr $mo(measure) + 1]
	}
}
proc trackinfo_update {a b c} {
	global tminfo
	upvar $a mo

	switch $mo(current_track) {
		0	{
			$tminfo.t coords trackid 3c 0.45c
			$tminfo.t itemconfigure trackid -text I
		}
		1	{
			$tminfo.t coords trackid 4c 0.45c
			$tminfo.t itemconfigure trackid -text II
		}
		2	{
			$tminfo.t coords trackid 5c 0.45c
			$tminfo.t itemconfigure trackid -text III
		}
		3	{
			$tminfo.t coords trackid 6c 0.45c
			$tminfo.t itemconfigure trackid -text IV
		}
	}
}
proc modeinfo_update {m} {
	global tminfo
	global tapwrite
	global font12

	$tminfo.m delete modetext
	switch $m {
		0	{
			set tapwrite 1
			$tminfo.m create text 1.2c 0.8c -text "TRACK PLAY"	\
				-tags modetext -anchor w -font *-${font12}-*
		}
		1	{
			set tapwrite 1
			$tminfo.m create text 1.2c 1.1c -text "TRACK WRITE"	\
				-tags modetext -anchor w -font *-${font12}-*
		}
		2	{
			set tapwrite 1
			$tminfo.m create text 4.2c 0.4c -text "PATTERN PLAY"	\
				-tags modetext -anchor w -font *-${font12}-*
		}
		3	{
			if {$tapwrite} {
				incr tapwrite -1
				$tminfo.m create text 4.2c 0.8c -text "PATTERN WRITE"	\
					-tags modetext -anchor w -font *-${font12}-*
			} else {
				incr tapwrite
				$tminfo.m create text 4.2c 1.2c -text "TAP WRITE"	\
					-tags modetext -anchor w -font *-${font12}-*
			}
		}
	}
}
proc scale_lamps_update {} {
	global scale_lamps
	upvar #0 mode mo
	upvar #0 tkxox xox

	set scale [tk7_get_scale $mo(patgroup) $mo(current_pattern)]
	for {set i 0} {$i < 4} {incr i} {
	    set button ${scale_lamps}.l${i}
	    if {$i == $scale} {
		$button configure -background $xox(lamp_on)
	    } else {
		$button configure -background $xox(lamp_off)
	    }
	}
}
proc locate_gridpos {x y result} {
	global gridXs gridYs gridSvals gridIvals
	upvar $result res

	#puts "locate_gridpos $x,$y"
	set halo 7

	set resX -1
	foreach i $gridXs {
		if {($i > [expr $x - $halo]) && ($i < [expr $x + $halo])} {
			set resX $i
			break
		}
	}
	if {$resX < 0} {
		return $resX
	}
	#puts "resX = $resX"

	set resY -1
	foreach i $gridYs {
		if {($i > [expr $y - $halo]) && ($i < [expr $y + $halo])} {
			set resY $i
			break
		}
	}
	if {$resY < 0} {
		return $resY
	}
#puts "resY = $resY"

	set res(step) $gridSvals($resX)
	set res(inst) $gridIvals($resY)

	return 0
}

proc play_loop {} {
	upvar #0 mode mo
	upvar #0 tkxox xox
	upvar #0 track_list tl
	global button_stop	;# to invoke stop button
	if {$mo(stopgo) == $xox(START) && $mo(patr) == $xox(TRACK) && $mo(rdrw) == $xox(READ)} {
	
		# Playing a track
		if {$mo(TRACK_START)} {
			set xox(play_list) $tl($mo(current_track))

			# Prepare to display pattern contents
			set mo(measure) -1

			set mo(TRACK_START) 0
		}

		if {[llength $xox(play_list)] > 0} {
			set target  [lindex $xox(play_list) 0]
			set group [expr $target / 16]
			set pat [expr $target % 16]
			set xox(play_list) [lreplace $xox(play_list) 0 0]

			# Prepare to display pattern contents
			set target  [expr $mo(measure) + 1]
			set mo(measure) [measure_constrain $target]
		} else {
			$button_stop invoke
		}

		if {$mo(PATTERN_REPEAT)} {
			play_pattern $group $pat
		}

		# Update pattern display
		pattern_show

	} else { # Not playing a track

		if {$mo(PATTERN_REPEAT)} {
			play_pattern $mo(patgroup) $mo(current_pattern)
		}
	}
	after $mo(REPEAT_INTERVAL) play_loop
}
# ----------------------------------------------------------------------------
# Edit Pattern Comment
# ----------------------------------------------------------------------------

proc get_current_pattern_name {} {
    upvar #0 mode mo
    switch $mo(patgroup) {
	0 { set g "A"; }
	1 { set g "B"; }
	2 { set g "C"; }
	3 { set g "D"; }
    }
    set name "$g[expr $mo(current_pattern)+1]";
    return $name;
}
set comment .pattern_comment;

proc  refresh_comment {} {
    upvar #0 mode mo
    global comment;
    if {[winfo exists $comment]} {
    	set name [get_current_pattern_name];
    	wm title $comment "$name pattern comment"
        set old_comment [$comment.string get]
        $comment.string delete 0 [expr [string length $old_comment] ]
        set current_comment [tk7_get_pattern_comment $mo(patgroup) $mo(current_pattern)]
        $comment.string insert 0 "$current_comment"
    }
}
proc edit_pattern_comment {} {
    upvar #0 mode mo
    upvar #0 tkxox xox
    global comment

    if {[winfo exists $comment]} {
	wm deiconify $comment
    } else {
	toplevel $comment

	button $comment.quit -text quit -command {wm iconify $comment}
	button $comment.ok -text ok -command comment_ok
	pack $comment.quit $comment.ok -side right

	# label $comment.label -text Comment: -padx 0
	entry $comment.string -width 20 -relief sunken
	# pack $comment.label -side left
	pack $comment.string -side left -fill x -expand true

	bind $comment.string <Return> comment_ok
	bind $comment.string <Control-c> {wm iconify $comment}
	focus $comment.string 
    }
    refresh_comment;
}
proc comment_ok {} {
    upvar #0 mode mo;
    global comment;
    set stringval [$comment.string get];
    set name [get_current_pattern_name];
    puts "set $name comment to \"$stringval\"";
    tk7_set_pattern_comment $mo(patgroup) $mo(current_pattern) $stringval;
    # wm iconify $comment;
}
