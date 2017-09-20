dnl
dnl    This file is part of tk707.
dnl
dnl    Copyright (C) 2000, 2001, 2002, 2003, 2004 Chris Willing and Pierre Saramito 
dnl
dnl    tk707 is free software; you can redistribute it and/or modify
dnl    it under the terms of the GNU General Public License as published by
dnl    the Free Software Foundation; either version 2 of the License, or
dnl    (at your option) any later version.
dnl
dnl    Foobar is distributed in the hope that it will be useful,
dnl    but WITHOUT ANY WARRANTY; without even the implied warranty of
dnl    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
dnl    GNU General Public License for more details.
dnl
dnl    You should have received a copy of the GNU General Public License
dnl    along with Foobar; if not, write to the Free Software
dnl    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
dnl
dnl-------------------------------------------------------------------------
dnl
dnl configure.in: script source file for configure
dnl
dnl author: Pierre.Saramito@imag.fr
dnl
dnl date: 2 september 2000
dnl
dnl-------------------------------------------------------------------------


dnl init autoconf without caches
define([AC_CACHE_LOAD], )
define([AC_CACHE_SAVE], )

AC_INIT(README)
AC_PREREQ(2.53)

dnl-------------------------------------------------------------------------
dnl   package and version definition
dnl-------------------------------------------------------------------------

PACKAGE=tk707

dnl the version is defined in the VERSION file: example:
dnl		0.6.17
dnl     - all but the last are the MAJOR_VERSION used for
dnl       official releases: 0.6
dnl	  and is propagated in the .tcl file and the config.h file
dnl	  => you can change the last number
dnl     - the last number (17) is handled automatically by CVS, for tags
dnl	  => do not change the last number, except when increasing
dnl	     the major version number; then reset it in the VERSION file:
dnl		0.7.0

AC_VERSION_FROM_FILE
VERSION=$MAJOR_VERSION

echo "configuring $PACKAGE $VERSION..."

dnl-------------------------------------------------------------------------
dnl   init automake
dnl-------------------------------------------------------------------------

AM_INIT_AUTOMAKE($PACKAGE,$VERSION)
dnl AC_ARG_PROGRAM
AM_CONFIG_HEADER(config.h)

dnl-------------------------------------------------------------------------
dnl   check some commands
dnl-------------------------------------------------------------------------

USER_CFLAGS=$CFLAGS
AC_PROG_CC
if test x"$GCC" = x"yes" -a x"$USER_CFLAGS" = x""; then
    CFLAGS="-O9 -Wall -Wno-unused"
fi
dnl-------------------------------------------------------------------------
dnl   check for maintainers tools (not requiered for build)
dnl-------------------------------------------------------------------------

AC_CHECK_PROGS(LEX, flex lex)
if test x"$LEX" != x""; then
  AC_DECL_YYTEXT
else
  LEX="${srcdir}/missing lex"
fi
AC_CHECK_PROGS(MAKEINFO, makeinfo, makeinfo)
AC_CHECK_PROGS(TEXI2HTML, texi2html, texi2html)
AC_CHECK_PROGS(TEXI2DVI, texi2dvi)
AC_CHECK_PROGS(FIG2DEV, fig2dev)

dnl-------------------------------------------------------------------------
dnl   check for run-time environment
dnl-------------------------------------------------------------------------

AC_CHECK_PROGS(TIMIDITY, timidity)
AC_CHECK_PROGS(LAME, lame)
AC_CHECK_PROGS(MIDIDUMP, mididump)

dnl-------------------------------------------------------------------------
dnl   check for libraries: dl, m
dnl-------------------------------------------------------------------------

AC_CHECK_LIB(dl,dlopen)
AC_CHECK_LIB(m,sqrt)

dnl-------------------------------------------------------------------------
dnl   check for library: alsa
dnl-------------------------------------------------------------------------

PREV_LIBS=$LIBS
PREV_LDFLAGS=$LDFLAGS
PREV_CFLAGS=$CFLAGS
PREV_CPPFLAGS=$CPPFLAGS

AM_PATH_ALSA_LOCAL
AH_TEMPLATE([HAVE_ALSA_ASOUNDLIB_H], Defines if you have alsa/asoundlib.h)
AC_SUBST(HAVE_ALSA_ASOUNDLIB_H)
AC_CHECK_HEADER(alsa/asoundlib.h, [AC_DEFINE(HAVE_ALSA_ASOUNDLIB_H)])

LIBS=$PREV_LIBS
LDFLAGS=$PREV_LDFLAGS
CFLAGS=$PREV_CFLAGS
CPPFLAGS=$PREV_CPPFLAGS

dnl-------------------------------------------------------------------------
dnl   check for library X
dnl-------------------------------------------------------------------------

AC_PATH_XTRA

if test "x$have_x" = xno; then
      AC_MSG_ERROR(Could not configure X)
fi
if test "x$x_libraries" != x; then
    ldflags_x_opt="-L$x_libraries"
    LDFLAGS="$LDFLAGS $ldflags_x_opt"
    SHLDFLAGS="$SHLDFLAGS $ldflags_x_opt"
else
    ldflags_x_opt=
fi
if test "x$x_includes" != x; then
    CPPFLAGS="$CPPFLAGS -I$x_includes"
fi

AC_CHECK_LIB(X11,XOpenDisplay)

dnl-------------------------------------------------------------------------
dnl   get libraries by options: tcl tk
dnl-------------------------------------------------------------------------

AC_ARG_WITH(tcl-includes,
  [  --with-tcl-includes=DIR Tcl include file path ],
  [ if test ! -d $withval; then
      AC_MSG_WARN($withval is not found.)
    fi
    tcl_include_dir="-I$withval"
  ])
AC_ARG_WITH(tcl-libs,
  [  --with-tcl-libs=DIR     Tcl library file path ],
  [ if test ! -d $withval; then
      AC_MSG_WARN($withval is not found.)
    fi
    tcl_libdir="-L$withval" ])
AC_ARG_WITH(tk-includes,
  [  --with-tk-includes=DIR  Tk include file path ],
  [ if test ! -d $withval; then
      AC_MSG_WARN($withval is not found.)
    fi
    tk_includes="-I$withval" ])
AC_ARG_WITH(tk-libs,
  [  --with-tk-libs=DIR      Tk library file path ],
  [ if test ! -d $withval; then
      AC_MSG_WARN($withval is not found.)
    fi
    tk_libdir="-L$withval" ])

dnl-------------------------------------------------------------------------
dnl   check for libraries: tcl tk
dnl-------------------------------------------------------------------------


    dnl save flags
    KEEPCPPFLAGS=$CPPFLAGS
    KEEPLDFLAGS=$LDFLAGS
    KEEPLIBS=$LIBS

    CPPFLAGS="$tcl_include_dir $tk_includes $CPPFLAGS"
    LDFLAGS="$tcl_libdir $tk_libdir $LDFLAGS"
    LIBS="$LIBS $lib_dl_opt"

    tcl_lib=
    tk_lib=
    tcl_prefix=no
    for l in tcl8.4 tcl8.3 tcl8.2 tcl8.1 tcl8.0 tcl8.0jp tcl7.6jp tcl80jp tcl76jp tcl7.6 tcl80 tcl76 tcl; do
      case "x$tcl_prefix" in x"no") AC_CHECK_LIB($l,Tcl_Init,tcl_prefix=$l);; esac
    done
    tcl_lib="-l${tcl_prefix}"
    LIBS="$LIBS $tcl_lib"
    for l in tk8.4 tk8.3 tk8.2 tk8.1 tk8.0 tk8.0jp tk4.2jp tk80jp tk42jp tk4.2 tk80 tk42 tk; do
      case "x$tk_lib" in x) AC_CHECK_LIB($l,Tk_Init,tk_lib=-l$l);; esac
    done
    have_tcltk_header=yes
    if test ! -d /usr/include/$tcl_prefix; then
        # not debian style
        AC_CHECK_HEADER(tcl.h,,have_tcltk_header=no)
        AC_CHECK_HEADER(tk.h,,have_tcltk_header=no)
    else
        # debian style detection :
	echo "looking in /usr/include/$tcl_prefix for tcl-tk headers"
        CPPFLAGS="-I/usr/include/$tcl_prefix $CPPFLAGS"
	TCLTK_CFLAGS="-I/usr/include/$tcl_prefix $TCLTK_CFLAGS"
        AC_CHECK_HEADER(tcl.h,,have_tcltk_header=no)
        AC_CHECK_HEADER(tk.h,,have_tcltk_header=no)
    fi
    if test $have_tcltk_header = no; then
      AC_MSG_ERROR([need tcl.h and tk.h header files])
    fi
    LIBS=$KEEPLIBS
    if test "x$tcl_lib" = x -o "x$tk_lib" = x; then
      CPPFLAGS=$KEEPCPPFLAGS
      LDFLAGS=$KEEPLDFLAGS
      enable_tcltk=no
      AC_MSG_WARN(tcl/tk is not enable)
    else
      tcltk_dep='tclIndex'

      TCLTK_CFLAGS="$tcl_include_dir $tk_includes $TCLTK_CFLAGS"
      AC_SUBST(TCLTK_CFLAGS)

      TCLTK_LDFLAGS="$tk_lib $tcl_lib $lib_dl_opt"
      AC_SUBST(TCLTK_LDFLAGS)


      TCLTK_LIBS=`echo $LIBS | sed "s/-lX11/$tk_lib $tcl_lib -lX11/"`
      AC_SUBST(TCLTK_LIBS)
      case "$target" in
        *-*-bsdi*)
          TCLTK_LIBS="$TCLTK_LIBS -lipc"
          ;;
      esac
    fi

LIBS=$PREV_LIBS
LDFLAGS=$PREV_LDFLAGS
CFLAGS=$PREV_CFLAGS
CPPFLAGS=$PREV_CPPFLAGS

dnl-------------------------------------------------------------------------
dnl   Output
dnl-------------------------------------------------------------------------

AC_OUTPUT(Makefile tk707.sh)

