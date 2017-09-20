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
dnl --------------------------------------------------------------
AC_DEFUN([AC_VERSION_FROM_FILE],
[
  if test -f $srcdir/VERSION; then
   [MINOR_VERSION=`cat $srcdir/VERSION | awk -F "." '{print $NF}'`]
   [MAJOR_VERSION=`cat $srcdir/VERSION | \
        awk -F "." '{
                i=1; printf("%s", $i);
                for(i=2;i<NF;i++) {
                        printf(".%s", $i);
                }
                printf("\n");
        }' `]
  else
   AC_MSG_WARN(file $srcdir/VERSION not defined)
   [MAJOR_VERSION=1]
   [MINOR_VERSION=0]
  fi
])
dnl --------------------------------------------------------------
dnl MY_DEFINE(VARIABLE)
AC_DEFUN([MY_DEFINE],
[cat >> confdefs.h <<EOF
[#define] $1 1
EOF
])

dnl --------------------------------------------------------------
dnl CONFIG_INTERFACE(package,macro_name,interface_id,help
dnl                  $1      $2         $3           $4
dnl                  action-if-yes-or-dynamic,
dnl		     $5
dnl		     action-if-yes,action-if-dynamic,action-if-no)
dnl		     $6            $7                $8
AC_DEFUN([CONFIG_INTERFACE],
[AC_ARG_ENABLE($1,[$4],
[case "x$enable_$1" in xyes|xdynamic) $5 ;; esac])
case "x$enable_$1" in
xyes)
  MY_DEFINE(IA_$2)
  AM_CONDITIONAL(ENABLE_$2, true)
  $6
  ;;
xdynamic)
  dynamic_targets="$dynamic_targets interface_$3.\$(so)"
  $7
  ;;
*)
  $8
  ;;
esac
AC_SUBST($3_so_libs)
])
dnl --------------------------------------------------------------
AC_DEFUN([AM_CHECK_ALSA9],
    [AC_MSG_CHECKING(for alsa-0.9.x)]
    [AH_TEMPLATE([HAVE_ALSA9], Defines if you have alsa-0.9.x)]
    [AC_TRY_RUN(
        changequote(%%, %%)dnl
        %%
		#include <alsa/asoundlib.h>
		int main() {
		#if (SND_LIB_MAJOR == 0) && (SND_LIB_MINOR >= 9)
    			return 0;
		#else
    			return 1;
		#endif
		}
        %%,
        changequote([, ])dnl
        [AC_DEFINE(HAVE_ALSA9)]
        have_alsa9=yes,
        have_alsa9=no,
        have_alsa9=undef
        false
    )]
    [AC_MSG_RESULT(${have_alsa9})]
)
dnl --------------------------------------------------------------
dnl alsa.m4 starts form here
dnl Configure Paths for Alsa
dnl Christopher Lansdown (lansdoct@cs.alfred.edu)
dnl 29/10/1998
dnl modified for TiMidity++ by Isaku Yamahata(yamahata@kusm.kyoto-u.ac.jp)
dnl 16/12/1998
dnl AM_PATH_ALSA_LOCAL(MINIMUM-VERSION)
dnl Test for libasound, and define ALSA_CFLAGS and ALSA_LIBS as appropriate.
dnl if there exit ALSA, define have_alsa=yes, otherwise no.
dnl enables arguments --with-alsa-prefix= --with-alsa-enc-prefix= --disable-alsatest
dnl
AC_DEFUN([AM_PATH_ALSA_LOCAL],
[dnl
dnl Get the clfags and libraries for alsa
dnl
have_alsa=no
AC_ARG_WITH(alsa-prefix,[  --with-alsa-prefix=PFX  Prefix where Alsa library is installed(optional)],
	[alsa_prefix="$withval"], [alsa_prefix=""])
AC_ARG_WITH(alsa-inc-prefix, [  --with-alsa-inc-prefix=PFX  Prefix where include libraries are (optional)],
	[alsa_inc_prefix="$withval"], [alsa_inc_prefix=""])
AC_ARG_ENABLE(alsatest, [  --disable-alsatest      Do not try to compile and run a test Alsa program], [enable_alsatest=no], [enable_alsatest=yes])

dnl Add any special include directories
AC_MSG_CHECKING(for ALSA CFLAGS)
if test "$alsa_inc_prefix" != "" ; then
	ALSA_CFLAGS="$ALSA_CFLAGS -I$alsa_inc_prefix"
        CFLAGS="$CFLAGS -I$alsa_inc_prefix"
fi
AC_MSG_RESULT($ALSA_CFLAGS)

dnl add any special lib dirs
AC_MSG_CHECKING(for ALSA LDFLAGS)
if test "$alsa_prefix" != "" ; then
	ALSA_LIBS="$ALSA_LIBS -L$alsa_prefix"
	LIBS="-L$alsa_prefix"
fi

dnl add the alsa library
ALSA_LIBS="$ALSA_LIBS -lasound"
AC_MSG_RESULT($ALSA_LIBS)

dnl Check for a working version of libasound that is of the right version.
min_alsa_version=ifelse([$1], ,0.1.1,$1)
AC_MSG_CHECKING(for libasound headers version >= $min_alsa_version)
no_alsa=""
    alsa_min_major_version=`echo $min_alsa_version | \
           sed 's/\([[0-9]]*\).\([[0-9]]*\).\([[0-9]]*\)/\1/'`
    alsa_min_minor_version=`echo $min_alsa_version | \
           sed 's/\([[0-9]]*\).\([[0-9]]*\).\([[0-9]]*\)/\2/'`
    alsa_min_micro_version=`echo $min_alsa_version | \
           sed 's/\([[0-9]]*\).\([[0-9]]*\).\([[0-9]]*\)/\3/'`

AC_TRY_COMPILE([
#include <sys/asoundlib.h>
], [
/* ensure backward compatibility */
#if !defined(SND_LIB_MAJOR) && defined(SOUNDLIB_VERSION_MAJOR)
#define SND_LIB_MAJOR SOUNDLIB_VERSION_MAJOR
#endif
#if !defined(SND_LIB_MINOR) && defined(SOUNDLIB_VERSION_MINOR)
#define SND_LIB_MINOR SOUNDLIB_VERSION_MINOR
#endif
#if !defined(SND_LIB_SUBMINOR) && defined(SOUNDLIB_VERSION_SUBMINOR)
#define SND_LIB_SUBMINOR SOUNDLIB_VERSION_SUBMINOR
#endif

#  if(SND_LIB_MAJOR > $alsa_min_major_version)
  exit(0);
#  else
#    if(SND_LIB_MAJOR < $alsa_min_major_version)
#       error not present
#    endif

#   if(SND_LIB_MINOR > $alsa_min_minor_version)
  exit(0);
#   else
#     if(SND_LIB_MINOR < $alsa_min_minor_version)
#          error not present
#      endif

#      if(SND_LIB_SUBMINOR < $alsa_min_micro_version)
#        error not present
#      endif
#    endif
#  endif
exit(0);
],
  [AC_MSG_RESULT(found.)
   have_alsa=yes],
  [AC_MSG_RESULT(not present.)]
)

dnl Now that we know that we have the right version, let's see if we have the library and not just the headers.
AC_CHECK_LIB([asound], [snd_ctl_open],,
	[AC_MSG_RESULT(No linkable libasound was found.)]
)

dnl That should be it.  Now just export out symbols:
AC_SUBST(ALSA_CFLAGS)
AC_SUBST(ALSA_LIBS)
])
dnl alsa.m4 ends here
