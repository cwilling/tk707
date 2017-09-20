%{
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

/* compile commands:

 	flex texi2help.flex 
 	gcc lex.yy.c -o texi2help -lfl

  usage:
        texi2help < tk707.texi > tk707.help

  NOTE:
	translate only a SUBSET of texinfo files 
	into tcl/tk help pages.
	See texinfo documentation for the input format.
	See at top of help.tcl for the output format.
*/
#include <stdio.h>
#define no_font '%';
int font = no_font;
int arg_previous_state = 0;
int quote = '\'';
#define put(c) printf ("%c", c);
%}
ID		[a-zA-Z_][a-zA-Z_\-0-9]*
%x arg skip_bloc skip_braces example format item
%%
%{
/* --------------------------------------------------------------
 * 	specials
 * --------------------------------------------------------------*/
%}
<INITIAL,arg>"@@" { printf ("@@ "); }
<INITIAL,arg>"@{" { printf ("{"); }
<INITIAL,arg>"@}" { printf ("}"); }
%{
/* --------------------------------------------------------------
 * titles
 * --------------------------------------------------------------*/
%}
"@settitle".* 		{ printf ("@C0@t%s@t\n", yytext+10); }
"@chapter"[ \t][ \t]*"Install".*	{}
"@chapter".* 		{ printf ("@C1@t%s@t\n", yytext+9); }
"@appendix".* 		{ printf ("@C1@t%s@t\n", yytext+10); }
"@section".* 		{ printf ("@C2@t%s@t\n", yytext+9); }
"@subsection".* 	{ printf ("@C2@t%s@t\n", yytext+12); }
%{
/* --------------------------------------------------------------
 * @code{...}, @strong{}, @var{}, @math{}, @cite{}, @dfn{}, 
 * @url{}, @email{}, @samp{}, @file{}
 * @pxref{...}
 * --------------------------------------------------------------*/
%}
<INITIAL,arg>"@"("key"|"code"|"samp"|"url"|"email"|"strong")"{"	{ /* in bold */
			  font = 'c';
                          arg_previous_state = YYSTATE;
			  BEGIN(format);
			}
<INITIAL,arg>"@"("emph"|"var"|"cite"|"dfn")"{"	{ /* highlight */
			  font = 'h';
                          arg_previous_state = YYSTATE;
			  BEGIN(format);
			}
<INITIAL,arg>"@"("math")"{"	{ /* in italic */
			  font = 'i';
                          arg_previous_state = YYSTATE;
			  BEGIN(format);
			}
<format>"}"		{ /* end of arg */
			  font = no_font;
			  BEGIN(arg_previous_state);
			}
<format>[a-zA-Z][a-zA-Z]*	{ printf("@%c%s", font, yytext_ptr); }
<format>[ \t][ \t]*		{ printf("%s", yytext_ptr); }
<format>\n			{ put('\n'); }
<format>.			{ printf("@%c%c", font, *yytext_ptr); }
%{
/* --------------------------------------------------------------
 * @code{...}, @strong{}, @var{}, @math{}, @cite{}, @dfn{}, 
 * @url{}, @email{}, @samp{}, @file{}
 * @pxref{...}
 * --------------------------------------------------------------*/
%}
<INITIAL,arg>"@file{"	{ /* in quotes */
			  font = quote; printf("`");
                          arg_previous_state = YYSTATE;
			  BEGIN(arg);
			}
<INITIAL,arg>"@footnote{"	{ /* in (...) */
			  font = ')'; printf (" (");
                          arg_previous_state = YYSTATE;
			  BEGIN(arg);
			}
<arg>"}"		{ /* end of arg */
			  printf("'");
			  font = no_font;
			  BEGIN(arg_previous_state);
			}
<arg>[^}]		{ printf("%s", yytext_ptr); }
%{
/* --------------------------------------------------------------
 * 	example
 * --------------------------------------------------------------*/
%}
<INITIAL>"@example".*\n		{ 
				  arg_previous_state = YYSTATE; 
				  BEGIN(example);
				  font = 'c';
			        }
<example>"@end"[ \t]([ \t]*)"example".*		{ BEGIN(arg_previous_state); }
<example>[a-zA-Z][a-zA-Z]*	{ printf("@%c%s", font, yytext_ptr); }
<example>[ \t][ \t]*		{ printf("%s", yytext_ptr); }
<example>\n			{ put('\n'); }
<example>.			{ printf("@%c%c", font, *yytext_ptr); }
%{
/* --------------------------------------------------------------
 * 	itemize and table
 * --------------------------------------------------------------*/
%}
<INITIAL>"@item"[ \t]*\n	{ printf ("\n\t* "); }
<INITIAL>"@item"[ \t].*\n	{ printf ("\n\t%s", yytext_ptr+6); }
<INITIAL>"@"("itemize"|"table").*\n			{}
<INITIAL>"@end"[ \t]([ \t]*)("itemize"|"table").*\n	{}
%{
/* --------------------------------------------------------------
 * 	skip
 * --------------------------------------------------------------*/
%}
<INITIAL>"@c"\n	{}
<INITIAL>"\\input"[ \t]([ \t]*)"texinfo".*\n {}
<INITIAL>"@"("c"|"cindex"|"setfilename"|"setchapternewpage"|"include")" ".*\n {}
<INITIAL>"@"("finalout"|"node"|"unnumbered"|"printindex"|"shortcontents"|"contents"|"bye").*\n	{}

<INITIAL>"@"("ifinfo"|"titlepage"|"menu").*\n { arg_previous_state = YYSTATE; BEGIN(skip_bloc); }
<skip_bloc>"@end"[ \t]([ \t]*)("ifinfo"|"titlepage"|"menu").*\n { BEGIN(arg_previous_state); }
<skip_bloc>.			{}
<skip_bloc>\n			{}

<INITIAL>"@"("xref"|"pxref")"{"	{ arg_previous_state = YYSTATE; BEGIN(skip_braces); }
<skip_braces>[^}]*		{}
<skip_braces>"}" 		{ BEGIN(arg_previous_state); }
%%
/* --------------------------------------------------------------
 * 	main
 * --------------------------------------------------------------*/
int yywrap () { return 1; }
int main() { yyin = stdin; yylex(); return 0; }


