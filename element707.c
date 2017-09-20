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
#include "util707.h"
#include <string.h> /* strdup() */

/* 
 * get/set pattern properties
 */
void pattern_set_length(PatternElement *pat, int value) {
	pat -> length = value; }
int pattern_get_length(PatternElement *pat) {
	return pat -> length; }
void pattern_set_scale(PatternElement *pat, int value) {
	pat -> scale = value; }
int pattern_get_scale(PatternElement *pat) {
	return pat -> scale; }
void pattern_set_flam(PatternElement *pat, int value) {
	pat -> flam = value; }
int pattern_get_flam(PatternElement *pat) {
	return pat -> flam; }
void pattern_set_shuffle(PatternElement *pat, int value) {
	pat -> shuffle = value; }
int pattern_get_shuffle(PatternElement *pat) {
	return pat -> shuffle; }
void pattern_set_comment(PatternElement *pat, char *comment) {
	if (pat -> comment) { 
	    free(pat -> comment);
	}
	pat -> comment = strdup(comment); }
char* pattern_get_comment(PatternElement *pat) {
	return pat -> comment; }

int
pattern_el_init(PatternElement **tree)
{
	MidiElement **temp;
	int i, j, patterns;

	patterns = 4*16;	/* 4 banks of 16 patterns */
	if( (*tree=(PatternElement*)calloc(patterns, sizeof(PatternElement))) == NULL )
	{
		return -1;
	}
	for(j=0;j<patterns;j++)
	{
		if( (temp=(MidiElement**)calloc(16, sizeof(MidiElement*))) == NULL )
		{
			return -1;
		}
		for(i=0;i<16;i++) {
			*(temp + i) = NULL;
		}
		(*tree + j)->mel    = temp;
		pattern_set_length (*tree + j, 16);
		pattern_set_scale  (*tree + j, 0);
		pattern_set_flam   (*tree + j, 2);
		pattern_set_shuffle(*tree + j, 0);
		pattern_set_comment(*tree + j, "");
	}
	return 0;
}

/*
 *	Clear out all MidiElements in patterns from an existing pattern tree.
 */
int
pattern_el_clearall(PatternElement *tree)
{
	int i, j, patterns;

	patterns = 4*16;	/* 4 banks of 16 patterns */
	if( !tree )
		return -1;

	for(j=0;j<patterns;j++)
	{
		for(i=0;i<16;i++)
		{
			step_el_clear( ((tree+j)->mel + i) );
		}
		pattern_set_length (tree + j, 16);
		pattern_set_scale  (tree + j, 0);
		pattern_set_flam   (tree + j, 2);
		pattern_set_shuffle(tree + j, 0);
		pattern_set_comment(tree + j, "");
	}
	return 0;
}

void
step_el_clear(MidiElement **base)
{
	MidiElement *temp, *next;

	if( ! *base )
		return;

	next = *base;
	while( next->next != NULL )
	{
		temp = next;
		next = next->next;
		free(temp);
	}
	if( next )
	{
		free(next);
	}
	*base = NULL;
	
return;
}


MidiElement *
step_new_el(void)
{
	MidiElement *temp;

	if( (temp=(MidiElement*)calloc(1, sizeof(MidiElement))) == NULL )
	{
		return NULL;
	}
	/* Any default step settings here */
	temp->next = NULL;
	temp->vol = 127;	/* Maybe 0? */
	temp->prop = 0;

	return temp;
}

MidiElement *
step_get_el(PatternElement *tree, int bank_id, int pattern_id, int step, int note)
{
	int patloc = bank_id*16 + pattern_id;
	PatternElement *pattern = (tree + patloc);
	MidiElement *first = *(pattern->mel + step);
	return el_get_el_by_note(first, note);
}
MidiElement *
step_add_el(PatternElement *tree, int bank_id, int pattern_id, int step, int note)
{
	PatternElement *pattern;
	MidiElement *temp, *next;
	int patloc;

	patloc = bank_id*16 + pattern_id;
	pattern = (tree + patloc);
	next = *(pattern->mel + step);

/* First search for an element with the same note value and delete if found */
/*
printf("Adding %d\n", note);
*/
	if( (temp=el_get_el_by_note(next, note)) != NULL )
	{
		el_delete_listel((pattern->mel + step), temp);
		return NULL;
	}

/* Otherwise create and add a new MidiElement */
	if( (temp=step_new_el()) == NULL )
		return NULL;
	temp->note = note;

	if( ! next )
	{
		*(pattern->mel + step) = temp;
	}
	else /* add to existing element(s) at this step */
	{
		temp->next = next;
		*(pattern->mel + step) = temp;
	}
        return temp;
}

MidiElement *
el_get_el_by_note(MidiElement *base, int note)
{
	MidiElement *temp = base;

	if( ! temp )
		return NULL;

	do
	{
		if( temp->note == note )
			return temp;

		temp = temp->next;
	} while( temp != NULL );

	return NULL;
}

/*
 *	Delete a MidiElement (el) from a list (base)
 */
int
el_delete_listel(MidiElement **base, MidiElement *el)
{
	MidiElement *temp=*base;
	int found=0;

	if( ! temp )
		return found;
	else if( *base == el )
	{
		if( (*base)->next == NULL )
			*base = NULL;
		else
			*base = (*base)->next;
		free(el);
		return (found=1);
	}

	do
	{
		if( temp->next == el )
		{
			found = 1;
			temp->next = temp->next->next;
			free(el);
			break;
		}
		temp = (temp)->next;
	} while( (!found) && (temp != NULL));
	
	return found;
}

/*
 *	Remove MidiElement (el) from a list (base).
 */
int
el_remove_listel(MidiElement **base, MidiElement *el)
{
	MidiElement *temp=*base;
	int found=0;

	if( ! temp )
		return found;
	else if( *base == el )
	{
		found = 1;
		if( (*base)->next == NULL )
			*base = NULL;
		else
			*base = (*base)->next;
		return found;
	}

	do
	{
		if( temp->next == el )
		{
			found = 1;
			temp->next = temp->next->next;
			return found;
		}
		temp = (temp)->next;
	} while( temp != NULL );
	
	return found;
}

void
el_set_note(MidiElement *el, int note)
{
	el->note = note;
}
int
el_get_note(MidiElement *el)
{
	return el->note;
}

void
pattern_display_els(PatternElement *tree, int bank_id, int pattern_id)
{
	PatternElement *pattern;
	MidiElement *temp;
	int i, step;

	pattern = tree + (bank_id*16 + pattern_id);
	for(step=0;step<16;step++)
	{
		temp = *(pattern->mel + step);
		if( ! temp )
		{
			printf("Nothing at step %d\n", step);
			continue;
		}
		do
		{
			printf("    NOTE at step %d = %d\n", step, (temp)->note);
			temp = (temp)->next;
		} while( temp != NULL);
			
	}

}
void
el_get_step_elements(MidiElement **base, int inst[17])
{
	int i = 0;
	MidiElement *el;
	for (el = *base; el && i < 16; el = el->next) {
		inst[i++] = el_get_note(el);
	}
	inst[i] = -1;
}
void
el_get_step_properties(MidiElement **base, int props[17])
{
	int i = 0;
	MidiElement *el;
	for (el = *base; el && i < 16; el = el->next) {
		props[i++] = el_get_properties(el);
	}
	props[i] = -1;
}
int
el_copy_pattern(PatternElement *dest, PatternElement *src, int merge)
{
	int instruments[17];
	int properties [17];
	int step;

	pattern_set_length (dest, pattern_get_length (src));
	pattern_set_scale  (dest, pattern_get_scale  (src));
	pattern_set_flam   (dest, pattern_get_flam   (src));
	pattern_set_shuffle(dest, pattern_get_shuffle(src));
	pattern_set_comment(dest, pattern_get_comment(src));
	for(step=0; step < 16; step++) {
		int inst;
		el_get_step_elements  (src->mel + step, instruments);
		el_get_step_properties(src->mel + step, properties);

		if( !merge ) {
			step_el_clear(dest->mel + step);
		}
		for (inst = 0; inst < 16 && instruments[inst] != -1; inst++) {
			MidiElement* el   = *(dest->mel + step);
			MidiElement* temp = el_get_el_by_note(el, instruments[inst]);
			if( !temp ) {
				temp = step_new_el();
				if( !temp ) {
				    return -1;
				}
				el_set_note       (temp, instruments[inst]);
				el_set_properties (temp, properties [inst]);
				if( ! el ) {
					*(dest->mel + step) = temp;
				} else {
					/* add to existing element(s) at this step */
					temp->next = el;
					*(dest->mel + step) = temp;
				}
			}
		}
	}
	return 0;
}

void el_set_properties (MidiElement* el, int prop) {
        el->prop = prop; }
int el_get_properties (MidiElement* el) {
        return el->prop; }
/*
 * get/set/unset fla property
 */
bool have_fla (MidiElement* el) {
        return ((el->prop & fla_property) != 0); }
void el_unset_fla (MidiElement* el) {
        el->prop = (el->prop & ~fla_property); }
void el_set_fla (MidiElement* el) {
        el->prop = (el->prop | fla_property); }
/*
 * get/set/unset velocity properties
 */
bool have_weak_accent (MidiElement* el) {
        return ((el->prop & weak_accent_velocity) != 0); }
bool have_strong_accent (MidiElement* el) {
        return ((el->prop & strong_accent_velocity) != 0); }
bool have_zero_velocity (MidiElement* el) {
        return ((el->prop & zero_velocity) != 0); }
void el_set_default_velocity (MidiElement* el) {
        el->prop =  (el->prop & (~velocity_field)); }

static void el_set_velocity_flag (MidiElement* el, int flag) {
        el->prop = (el->prop & (~velocity_field)) | (flag & velocity_field); }

void el_set_weak_accent_velocity (MidiElement* el) {
    	el_set_velocity_flag (el, weak_accent_velocity); }
void el_set_strong_accent_velocity (MidiElement* el) {
    	el_set_velocity_flag (el, strong_accent_velocity); }
void el_set_zero_velocity (MidiElement* el) {
    	el_set_velocity_flag (el, zero_velocity); }

