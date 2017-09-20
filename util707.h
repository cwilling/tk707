/*
 *   This file is part of tk707.
 *
 *   Copyright (C) 2000, 2001, 2002, 2003, 2004 Chris Willing and Pierre Saramito 
 *
 *   tk707 is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   Foobar is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with Foobar; if not, write to the Free Software
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
#ifndef __UTIL707_H_
#define __UTIL707_H_

#include <stdio.h>
#include <errno.h>
#include <stdlib.h>

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

#ifdef HAVE_ALSA_ASOUNDLIB_H
#include <alsa/asoundlib.h>
#elif HAVE_LIBASOUND
#include <sys/asoundlib.h>
#endif

#if (SND_LIB_MAJOR == 0) && (SND_LIB_MINOR >= 9)
#define HAVE_ALSA9
#endif

#if (SND_LIB_MAJOR > 0)
#define HAVE_ALSA9
#endif

#ifndef HAVE_BOOL
typedef int bool;
static const bool false = 0;
static const bool true  = 1;
#endif


extern int usage(void);

#ifdef TRY_NEW_DEFINITION
/* The discrete time grid admits an unique 
 * parameter: the ratio note-on / note-off per a thirty-second.
 * Since the note-on is a hit in with percussions, the rest of
 * the grid is determined.
 */
#define thirty_second_note_on_ratio   5        /* customize the ratio !
						* ex1: ratio=3
						* => 1/3 note-on
						*    2/3 note-off, for a thirty-second
						* ex2: ratio=16
						* => 1/16 note-on, 15/16 note-off
						* ex3: ratio=1
						* => 100 % note-on; not for percussions...
						*/

#define tick_per_note_on   	      3          /* how long, in ticks, the note is on.
						* DO NOT change ! because we may divide 
						* a quarter by 4, 8, 3 and 6...
						*/

#define tick_per_thirty_second   thirty_second_note_on_ratio*tick_per_note_on
#define tick_per_sixtennth       2*tick_per_thirty_second
#define tick_per_eighth          4*tick_per_thirty_second
#define tick_per_quarter         8*tick_per_thirty_second

/*
 * steps are in two parts:
 * - a note-on part, which have a duration independant of the scale (a hit)
 * - a note-off part, which depend on the scale:
 */

static const int tick_per_step_off_scale [4] = {

	/* scale(0): 1 step = quarter/4 		*/
        tick_per_quarter/4 - tick_per_note_on,

	/* scale(1): 1 step = quarter/8 		*/
        tick_per_quarter/8 - tick_per_note_on,

	/* scale(2): 1 step = quarter/3 		*/
        tick_per_quarter/3 - tick_per_note_on,

	/* scale(3): 1 step = quarter/6			*/
        tick_per_quarter/6 - tick_per_note_on
};
#define old_tick_per_quarter        tick_per_quarter
#define old_tick_per_sixtennth      tick_per_sixtennth
#define old_tick_per_step_off_scale tick_per_step_off_scale
#define old_tick_per_note_on        tick_per_note_on

#else
static const int old_tick_per_quarter   = 120; /* ak ratio = 5 */
static const int old_tick_per_sixtennth =  30;
static const int old_tick_per_note_on   =   8;
static const int old_tick_per_step_off_scale [4] = { 22, 7, 32, 12 };
#endif /* TRY_NEW_DEFINITION */

#define tick_flam_duration 1 /* approximatively 1/(3*4) of a thirty_second 
			      * tick duration on a Roland 727
			      */

#define ADDR_PARTS 4 /* Number of part in a port description addr 1:2:3:4 */
#define SEP ", \t"      /* Separators for port description */
/* event pool size */
#define WRITE_POOL_SIZE         200
#define WRITE_POOL_SPACE        10
#define READ_POOL_SIZE          10      /* we need read pool only for echoing */
#define PPQ	120
#define DEF_MIDICHANNEL			9

struct seq707_context {
	snd_seq_t *handle; /* The snd_seq handle to /dev/snd/seq */
	int ppq;
	int local_port; /*, ctrl_port;*/
	int dest_queue; /*, ctrl_queue;*/
	int dest_client;
	int dest_port;
	unsigned int currticktime;
	unsigned int tempo;
	int	midichannel;
	char *portdesc;	/* Later, input may differ from ouput portdesc? */

} ;
typedef struct seq707_context seq707_context_t;

/* Properties of a note */
typedef enum note_properties_tag {

	null_property    	= 0,

	fla_property    	= 1 << 0,

	/* control the velocity */
	weak_accent_velocity	= 1 << 1,	/* increases weakly velocity */
	strong_accent_velocity	= 1 << 2,	/* increases strongly velocity */
	zero_velocity		= 1 << 3,

	/* defines the set
         * of bits related to
	 * the velocity control
         */
        velocity_field 		=  zero_velocity | weak_accent_velocity | strong_accent_velocity,

        _last_property  	= 1 << (sizeof(int)*8-1)

} note_properties_t;

typedef struct mel_tag {
	int               dur;
	unsigned short    type;
	unsigned short    vol;
	int               note;
	note_properties_t prop;

	struct mel_tag    *next;
} MidiElement;

extern void el_set_note     (MidiElement*, int);
extern int  el_get_note     (MidiElement*);

extern void el_set_properties (MidiElement*, int);
extern int  el_get_properties (MidiElement*);

/* get/set/unset fla */
extern bool have_fla     (MidiElement*);
extern void el_set_fla   (MidiElement*);
extern void el_unset_fla (MidiElement*);

/* get/set velocity */
extern bool have_weak_accent    (MidiElement*);
extern bool have_strong_accent  (MidiElement*);
extern bool have_zero_velocity  (MidiElement*);

extern void el_set_default_velocity       (MidiElement*); /* unset zero or accents */
extern void el_set_weak_accent_velocity   (MidiElement*);
extern void el_set_strong_accent_velocity (MidiElement*);
extern void el_set_zero_velocity          (MidiElement*);

typedef struct pattern_tag {
	MidiElement	**mel;
	int	        length;		/* Number of steps in pattern */
	int	        scale;		/* Scale for pattern */
	int	        shuffle;	/* Flam interval, in range 0..4 */
	int	        flam;		/* Shuffle interval, in range 0..4 */
	char*	        comment;	/* string comment */
} PatternElement;

void pattern_set_length (PatternElement *pat, int value);
int  pattern_get_length (PatternElement *pat);
void pattern_set_scale  (PatternElement *pat, int value);
int  pattern_get_scale  (PatternElement *pat);
void pattern_set_flam   (PatternElement *pat, int value);
int  pattern_get_flam   (PatternElement *pat);
void pattern_set_shuffle(PatternElement *pat, int value);
int  pattern_get_shuffle(PatternElement *pat);
void pattern_set_comment(PatternElement *pat, char* comment);
char* pattern_get_comment(PatternElement *pat);

typedef struct {
	PatternElement *ptree[3];
	int		mbank;
	PatternElement *patbuf;

	int  volumes[12];	/* Current volume fader settings */
	int  volmap [16];	/* Map of instruments to their volume levels */
	int  sounds [16];	/* Map of instruments to their midi sounds */
	bool have_delay [16];	/* Sound property: note is shortly off */

	seq707_context_t *ctxp_p;	/* Pattern output context */
	seq707_context_t *ctxp_c;	/* Control output context */
	seq707_context_t *ctxp_i;	/* Control input context */

} TK707;
extern TK707 *tk707;

extern int pattern_el_init(PatternElement**);
extern int pattern_el_clearall(PatternElement*);
extern int pattern_el_clear(int,int);
extern void step_el_clear(MidiElement**);
extern MidiElement* step_get_el(PatternElement *tree, int bank_id, int pattern_id, 
		int step, int note);
extern MidiElement *step_add_el(PatternElement*,int,int,int,int);
extern MidiElement *step_new_el(void);
extern MidiElement *el_get_el_by_note(MidiElement*,int);
extern int el_remove_listel(MidiElement**,MidiElement*);
extern int el_delete_listel(MidiElement**,MidiElement*);
extern void el_get_step_elements(MidiElement**,int instrs[17]);
extern void el_get_step_properties(MidiElement**, int props[17]);
extern void pattern_display_els(PatternElement*,int,int);
extern int el_copy_pattern(PatternElement*,PatternElement*,int);


extern int seq707_context_init(seq707_context_t**);
extern int set_client_port(char*,int*,int*);
extern void alsa_timer_start(seq707_context_t*);
extern void alsa_timer_stop(seq707_context_t*);
extern void alsa_timer_cont(seq707_context_t*);
extern void set_event_header(seq707_context_t*,snd_seq_event_t*);
extern void do_noteon_rt(seq707_context_t*,int,int,int);
extern void do_noteoff_rt(seq707_context_t*,int,int,int);
extern void do_noteon(seq707_context_t*,int,int,int);
extern void do_noteoff(seq707_context_t*,int,int,int);
extern int do_tempo_set(seq707_context_t*,unsigned int);
extern void alsa_sync(seq707_context_t*);
extern snd_seq_event_t *wait_for_event(seq707_context_t*);
extern void set_event_time(seq707_context_t*,snd_seq_event_t*,unsigned int);
extern int alsa_setup(TK707*,char*,char*);
extern int get_clientsports(char ***cpinfo);

/*
 * macros for reducing the code size
 */
#define tk707_get_int1_macro(interp,objc,objv,x1) \
    { \
	if( (objc) != 2 ) { \
		Tcl_SetResult((interp), "Wrong #args", TCL_VOLATILE); \
		return TCL_ERROR; \
	} \
	if( Tcl_GetIntFromObj((interp), (objv)[1], &(x1)) != TCL_OK ) \
		return TCL_ERROR; \
    }
#define tk707_get_int2_macro(interp,objc,objv,x1,x2) \
    { \
	if( (objc) != 3 ) { \
		Tcl_SetResult((interp), "Wrong #args", TCL_VOLATILE); \
		return TCL_ERROR; \
	} \
	if( Tcl_GetIntFromObj((interp), (objv)[1], &(x1)) != TCL_OK ) \
		return TCL_ERROR; \
	if( Tcl_GetIntFromObj((interp), (objv)[2], &(x2)) != TCL_OK ) \
		return TCL_ERROR; \
    }
#define tk707_get_int3_macro(interp,objc,objv,x1,x2,x3) \
    { \
	if( (objc) != 4 ) { \
		Tcl_SetResult((interp), "Wrong #args", TCL_VOLATILE); \
		return TCL_ERROR; \
	} \
	if( Tcl_GetIntFromObj((interp), (objv)[1], &(x1)) != TCL_OK ) \
		return TCL_ERROR; \
	if( Tcl_GetIntFromObj((interp), (objv)[2], &(x2)) != TCL_OK ) \
		return TCL_ERROR; \
	if( Tcl_GetIntFromObj((interp), (objv)[3], &(x3)) != TCL_OK ) \
		return TCL_ERROR; \
    }
#define tk707_get_int4_macro(interp,objc,objv,x1,x2,x3,x4) \
    { \
	if( (objc) != 5 ) { \
		Tcl_SetResult((interp), "Wrong #args", TCL_VOLATILE); \
		return TCL_ERROR; \
	} \
	if( Tcl_GetIntFromObj((interp), (objv)[1], &(x1)) != TCL_OK ) \
		return TCL_ERROR; \
	if( Tcl_GetIntFromObj((interp), (objv)[2], &(x2)) != TCL_OK ) \
		return TCL_ERROR; \
	if( Tcl_GetIntFromObj((interp), (objv)[3], &(x3)) != TCL_OK ) \
		return TCL_ERROR; \
	if( Tcl_GetIntFromObj((interp), (objv)[4], &(x4)) != TCL_OK ) \
		return TCL_ERROR; \
    }
#define tk707_get_int5_macro(interp,objc,objv,x1,x2,x3,x4,x5) \
    { \
	if( (objc) != 6 ) { \
		Tcl_SetResult((interp), "Wrong #args", TCL_VOLATILE); \
		return TCL_ERROR; \
	} \
	if( Tcl_GetIntFromObj((interp), (objv)[1], &(x1)) != TCL_OK ) \
		return TCL_ERROR; \
	if( Tcl_GetIntFromObj((interp), (objv)[2], &(x2)) != TCL_OK ) \
		return TCL_ERROR; \
	if( Tcl_GetIntFromObj((interp), (objv)[3], &(x3)) != TCL_OK ) \
		return TCL_ERROR; \
	if( Tcl_GetIntFromObj((interp), (objv)[4], &(x4)) != TCL_OK ) \
		return TCL_ERROR; \
	if( Tcl_GetIntFromObj((interp), (objv)[5], &(x5)) != TCL_OK ) \
		return TCL_ERROR; \
    }
#define tk707_get_int2str1_macro(interp,objc,objv,x1,x2,x3) \
    { \
	if( (objc) != 4 ) { \
		Tcl_SetResult((interp), "Wrong #args", TCL_VOLATILE); \
		return TCL_ERROR; \
	} \
	if( Tcl_GetIntFromObj((interp), (objv)[1], &(x1)) != TCL_OK ) \
		return TCL_ERROR; \
	if( Tcl_GetIntFromObj((interp), (objv)[2], &(x2)) != TCL_OK ) \
		return TCL_ERROR; \
        if( ((x3)=Tcl_GetStringFromObj((objv)[3], NULL)) == NULL ) \
                return TCL_ERROR; \
    }

#endif	/* __UTIL707_H_ */

