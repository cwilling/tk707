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
# =================================================================
# The Help Module
# =================================================================

set HELP(UserGuide) $PKGDATADIR/tk707.help

# ----------------------------------------------------------
# formatText
# ----------------------------------------------------------
# This procedure tags the text in a text widget (if format is true),
# based on the character in "char". 
# Text Marks "first" and "last" need to have been set prior to calling 
# the procedure. These mark the range of characters to be tagged.
# The parameters are as follows:
# w	: is the path of the text widget.
# char  : is the character determining which tag is to be set.
# 	  The current valid characters are:
#		u  : underline
#		i  : italic
#		c  : command
#		Cn : Content item, n is a positive integer. 
#		t  : title
#		h  : highlight
#		@  : keep the @ character.		
# format : is a boolean value, which when true causes the text to be formatted.
#  	   when false it removes all format information from the text
#	   without tagging
proc formatText { w char {format 1} } {
   global HELP

   # Format the text.
   if {$format} {
	switch $char {
		u { 	$w delete last "last + 1 chars"
			$w tag add underline "last" "last wordend"
		  }
		@ { 	$w insert first @ }
		c { 	$w delete last "last + 1 chars"
			$w tag add command "last" "last wordend"
		  }
		C {	
			set tab ""
			set tabs [$w get "last + 1 chars" "last + 2 chars"]
			$w delete last "last + 2 chars"
			while {$tabs} {
			    set tab "$tab      " ;
			    incr tabs -1
			}
			lappend HELP(Contents)\
			 [list "$tab[$w get "first" "first lineend"]" \
				[$w index first]]
		  }
		t { 	$w delete last "last + 1 chars"
			$w tag add title "last" "last lineend"
		  }
		h {	$w delete last "last + 1 chars"
			$w tag add highlight "last" "last wordend"
		  }
		i {	$w delete last "last + 1 chars"
			$w tag add italic "last" "last wordend"
		  }
	default { }
	}

   # Remove all format data without formatting.
   }  else {
	set ok 0
	foreach i {u c C t h i} {
		if {$i==$char} { 
			$w delete last "last + 1 chars"
			set ok 1 
		}
	}
		if {!$ok} { $w insert last @ }
  }
}
# ----------------------------------------------------------
# Set Help globals.
# ----------------------------------------------------------
set HELP(BG) snow2
set HELP(FG) black
set HELP(AFG) grey
set HELP(HIL) red
set HELP(COM) DarkGreen
set HELP(Log) "0"

# ----------------------------------------------------------
# about
# ----------------------------------------------------------
proc about {} {
  global VERSION
  if {[winfo exists .about]} {
    wm deiconify .about
  } else {
    toplevel .about
    wm title .about "About tk707..."
    label    .about.label -text "
TK 707\n
version $VERSION\n

Copyright(C) 2000, 2001\n
Chris Willing <chris@vislab.usyd.edu.au>,\n
Pierre Saramito <pierre.saramito@imag.fr>.\n

Go to the Help menu for the complete documentation.
This documentation is available in HTML and INFO formats.
Type `man tk707` to access the on-line reference manual.

The tk707 documentation is also available in html, pdf, postscript and
dvi formats from\n
http://www-lmc.imag.fr/lmc-edp/Pierre.Saramito/tk707
http://www.vislab.usyd.edu.au/staff/chris/tk707

Send comments and requests, bugs, suggestions and mods 
to the both authors."

    frame    .about.sep -width 100p -height 2p -borderwidth 1p -relief sunken
    button   .about.dismiss -text "Dissmiss" -command {wm iconify .about}
    pack     .about.label
    pack     .about.dismiss -side bottom -pady 4p
    pack     .about.sep     -side bottom -fill x -pady 4p
  }
}
# ----------------------------------------------------------
# UserManual
# ----------------------------------------------------------
# This procedure is the callback to to the Help-User's Manual menu item.
# It creates a pop-up window containing the user's manual, with a few 
# basic highlighting and goto features.
proc UserManual {} {
   global HELP FILE

   # Only procede if the help window is non-existant.	
   if {![winfo exists .help]} {
	set HELP(Contents) ""

	# Create the toplevel window.
	toplevel .help -bg $HELP(BG)
	# Set the geometry
	wm geometry .help 80x25
	wm title .help "Tk-707 User's Guide"
	# Set the Icon information.
	wm iconname .help Help

	# Create the buttons panel (Contents, Back, Exit)
	frame .help.buttons -bg $HELP(BG) -relief ridge -bd 4
	# Create the Contents button.
	button .help.buttons.contents\
			-text Contents\
			-bg $HELP(AFG)\
			-fg $HELP(FG)\
			-activeforeground $HELP(FG)\
			-activebackground $HELP(AFG)\
			-width 10\
			-command {.help.help.text yview 0}
	# Create the Back button.
	button .help.buttons.prev\
			-text Back\
			-bg $HELP(AFG)\
			-fg $HELP(FG)\
			-width 10\
			-activebackground $HELP(AFG)\
			-command {
 				set end [expr [llength $HELP(Log)]-1]
				set value [lindex $HELP(Log) [expr $end-1]]
				.help.help.text yview $value
				set HELP(Log) [lreplace $HELP(Log) $end $end]
			        }
	# Create the Exit button.
	button .help.buttons.exit\
			-text Exit\
			-bg $HELP(AFG)\
			-fg $HELP(FG)\
			-activeforeground $HELP(FG)\
			-activebackground $HELP(AFG)\
			-width 10\
			-command {destroy .help}

        # Procedure to call when HELP(Log) is written
        proc setlog {nm1 nm2 op} {
	  global HELP
	  if {$HELP(Log)==0} {
	    .help.buttons.prev config -state disabled 
	  } else {
	    .help.buttons.prev config -state normal
	  }
	}

	# Set a variable trace on the Help(Log) variable to ensure that
	# the Back button is disabled when the log is empty.
        trace variable HELP(Log) w setlog

	# Set the current state of the Back button.
	set HELP(Log) $HELP(Log)

	# Pack the buttons.
	pack 	.help.buttons.contents \
		.help.buttons.prev\
		.help.buttons.exit\
		-side left -anchor w

	pack .help.buttons  -anchor w -fill x

	# Create and pack the text widget (with scrollbar)
	setupText .help.help

	# Load the User's Guide into widget and generate contents list.
	loadFile .help.help.text $HELP(UserGuide)

	# Insert the contents list.
	set i 1
	foreach item $HELP(Contents) {
		.help.help.text insert $i.0 [format "[lindex $item 0]\n"]
		.help.help.text tag add content $i.0 "$i.0 lineend"
		incr i
	}
	incr i 2
	# Insert the "Contents" title.
	.help.help.text insert 1.0 [format "Contents\n\n"]
	# Give it the format of a title.
	.help.help.text tag add title 1.0 "1.0 lineend"
	# Store the number of lines added after Contents line.
	set xtraLinesBefore 2
	
	# Add 3 blank lines after contents.
	# This has to be stored for later
	set xtraLinesAfter 3
	.help.help.text insert $i.0 [format "\n\n\n"]
	# Strip the Format code from the Contents list
	forAllMatches .help.help.text @ {
		.help.help.text delete first last
		set char [.help.help.text get last "last+ 1 chars"]
		formatText .help.help.text $char 0
	}
	# Configure and Bind content list.
	# A different cursor when above the item
	.help.help.text tag bind content <Any-Enter> \
		".help.help.text configure -cursor arrow"
	.help.help.text tag bind content <Any-Leave> \
		".help.help.text configure -cursor {}"
	# Skip to the relevant line.
	.help.help.text tag bind content <Button-1>\
	  "set index \[ expr \[lindex \[split \[%W index @%x,%y\] .\] 0\]\
			-(1 +$xtraLinesBefore)\]
	   set goto \[expr \[lindex \[lindex \$HELP(Contents) \$index\] 1\] +2\
	   		+$xtraLinesAfter +\[llength \$HELP(Contents)\]\]

 	   # Store in the log.
	   lappend HELP(Log) \$goto

	   # Adjust the view to the selected line.
	   %W yview \$goto"
   } else {
	# Bring  the user manual to the front.
	# I am not using raise since it doesn't generally work for olwm.
	wm withdraw .help
	wm deiconify .help
   }
}

# ----------------------------------------------------------
# setupText
# ----------------------------------------------------------
# This procedure creates a text widget and scroll bar.
# The parameter "w" is a path for the combined widget.
proc setupText {w} {
   global HELP

   #Create Widgets if the path name is valid.
   if {![winfo exists $w]} {
	# Create the general frame.
	frame $w

	# Create the text widget.
	# The configuration option "setgrid" sets up gridded 
	# window management.
	text $w.text 	-yscrollcommand "$w.scroll set"\
			-setgrid 1 \
			-wrap word
	# Create the scrollbar.
	scrollbar $w.scroll -command "$w.text yview"

	# Pack the widget.
	pack $w.text  -fill both -expand 1 -side left
	pack $w.scroll -side left -fill y -expand 1
	pack $w -fill both -expand 1
   }

   # Configure the Widgets.
   $w config -bg $HELP(BG)
   $w.text config\
		-background $HELP(BG)\
		-foreground $HELP(FG)\
		-cursor {}\
		-font -adobe-helvetica-medium-r-normal--12-120-*\
		-exportselection 0

   $w.scroll config -background $HELP(BG)

   # Remove the default bindings that make the text widget editable.
   bind $w.text <Any-KeyPress> { }
   bind $w.text <Any-Button> { }
   bind $w.text <Any-B1-Motion> { }

   # Set the configuration for text tags.
   # Underline.
   $w.text tag configure underline -underline 1
   # Command
   $w.text tag configure command \
		-foreground DarkGreen\
		-font -adobe-helvetica-medium-r-normal--14-140-*
   $w.text tag bind command <Button-1> { 
		puts [%W get "@%x,%y wordstart" "@%x,%y wordend"] }
   $w.text tag bind command <Any-Enter> "$w.text configure -cursor arrow"
   $w.text tag bind command <Any-Leave> "$w.text configure -cursor {}"
   # Content
   $w.text tag configure content \
		-foreground DarkGreen \
		-font -adobe-helvetica-medium-r-normal--14-140-*
   # Title.
   $w.text tag configure title -font -adobe-helvetica-medium-r-normal--24-240-*
   # Italic
   $w.text tag configure italic -font -adobe-helvetica-medium-o-normal--12-120-*
   # Highlight.
   $w.text tag configure highlight -foreground red
}


# ----------------------------------------------------------
# loadFile
# ----------------------------------------------------------
# This procedure load a text file given by "file" formatted with a 
# simple form of hyper-text into the text widget given by "w". And
# format it.
proc loadFile {w file} {
   # Delete all previous text in the text widget.
   $w delete 1.0 end

   # Open the text file.
   set f [open $file]

   # Insert the text into the text widget.
   while {![eof $f]} {
	$w insert end [read $f 1000]
   }
	
   # Close the text file.
   close $f

   # Format the text. This is done by looking for all the "@" in the
   # text widget, deleting it and sending the following character to
   # the procedure formaText, which tags the text appropriately.
	forAllMatches $w @ {
		$w delete first last
		set char [$w get last "last+ 1 chars"]
		formatText $w $char
	}
}

# ----------------------------------------------------------
# forAllMatches
# ----------------------------------------------------------
# This procedure takes three arguments: the name of a text widget, 
# a regular expression pattern and a script. 
# It finds all of the ranges of characters that match the pattern. 
# For each matching range forAllMatches sets the marks first and last 
# to the beginning and end of the of the range, then it invokes the 
# script.
# This procedure has been taken from John K. Ousterhout's book,
# Tcl and the Tk Toolkit (1994) p.219. 
proc forAllMatches {w pattern script} {
	scan [$w index end] %d numLines
	for {set i 1} {$i<=$numLines} {incr i } {
	   $w mark set last $i.0
	   while {[regexp -indices $pattern \
		  [$w get last "last lineend" ] indices ] } {
		$w mark set first "last + [lindex $indices 0] chars"
		$w mark set last "last + 1 chars +[lindex $indices 1] chars"
		uplevel $script
	   }
	}
}
