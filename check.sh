#!/bin/sh
if test x"$MIDIDUMP" = x""; then
    echo "      mididump: program not found -- test skiped" 
    exit 0
fi
status=0

L="binaire-tk triolet-tk tst_scale"

have_not_found=no
for x in $L; do
  if test -f $x.mid; then
    echo "$MIDIDUMP $x.mid | diff $x.valid-dump -"
    $MIDIDUMP $x.mid | diff $x.valid-dump -
    if test $? = 0; then
	echo "$x.mid: ok"
    else
	echo "$x.mid: *NO*"
	status=1
    fi
  else
    echo "$x.mid: file not found -- test skiped"
    have_not_found=yes
  fi
done

if test $have_not_found = yes; then
    echo "HINT: you should use tk707 midi output for creating missing files." 
fi
exit $status

