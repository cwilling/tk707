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

/*
	Netvideo version 3.2
	Written by Ron Frederick <frederick@parc.xerox.com>

	Simple hack to translate a Tcl/Tk init file into a C string constant
	Extra hacks added by mhandley based on idea from vic
*/

/*
 * Copyright (c) Xerox Corporation 1992. All rights reserved.
 *  
 * License is granted to copy, to use, and to make and to use derivative
 * works for research and evaluation purposes, provided that Xerox is
 * acknowledged in all documentation pertaining to any such copy or derivative
 * work. Xerox grants no other licenses expressed or implied. The Xerox trade
 * name should not be used in any advertising without its written permission.
 *  
 * XEROX CORPORATION MAKES NO REPRESENTATIONS CONCERNING EITHER THE
 * MERCHANTABILITY OF THIS SOFTWARE OR THE SUITABILITY OF THIS SOFTWARE
 * FOR ANY PARTICULAR PURPOSE.  The software is provided "as is" without
 * express or implied warranty of any kind.
 *  
 * These notices must be retained in any copies of any part of this software.
 */

#include <stdio.h>

int
main(int argc, char **argv)
{
    int c, n;
    FILE* in = stdin;
    FILE* out = stdout;
    int genstrings = 1;
    const char* prog = argv[0];

    if (argc > 1 && strcmp(argv[1], "-c") == 0) {
	--argc;
	++argv;
	genstrings = 0;
    }
    if (argc < 2) {
	fprintf(stderr, "Usage: %s [-c] stringname\n", prog);
	exit(1);
    }

    if (genstrings) {
	fprintf(out, "char %s[] = \"", argv[1]);
	while ((c = getc(in)) != EOF) {
	    switch (c) {
	    case '\n':
		fprintf(out, "\\n");
		break;
	    case '\"':
		fprintf(out, "\\\"");
		break;
	    case '\\':
		fprintf(out, "\\\\");
		break;
	    default:
		putc(c, out);
		break;
	    }
	}
	fprintf(out, "\";\n");
    } else {
	fprintf(out, "static char %s[] = {\n", argv[1]);
	for (n = 0; (c = getc(in)) != EOF;)
	   fprintf(out, "%u,%c", c, ((++n & 0xf) == 0) ? '\n' : ' ');
	fprintf(out, "0\n};\n");
    }
    fclose(out);
    exit(0);
    /*NOTREACHED*/
}
