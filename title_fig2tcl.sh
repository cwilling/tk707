# -----------------------------------------------------
# fig2tcl wrapper fot tk707 title map
# -----------------------------------------------------

# -----------------------------------------------------
# files
# -----------------------------------------------------
arg=$1
dirname=` expr $arg : '\(.*\)/.*' \| \. `
#echo "! \"$dirname\" as dirname."
basename=`expr $arg : '.*/\(.*\)' \| $arg `
#echo "! \"$basename\" as basename."
name=`    expr $basename : '\(.*\).fig' \| $basename`
#echo "! \"$name\" as name."
fig_input="${dirname}/${name}.fig"
#echo "! \"$fig_input\" as input."
tcl_defs_output="${dirname}/${name}_defs.tcl"
tcl_output="${dirname}/${name}.tcl"
tmp="${name}_tmp$$.out"
/bin/rm -f $tcl_defs_output $tcl_output
# -----------------------------------------------------
# parameters
# -----------------------------------------------------
#magnification=1.23; #ok pour scaling=1
#magnification=1.25; #ok pour scaling=0.75
magnification=1.0; #ok pour scaling=0.5
window_hierarchy='$vcunit.title'
side="top"
color_bg='$tkxox(col_def_bg)'
# -----------------------------------------------------
# convert .fig in tcl/tk
# -----------------------------------------------------
fig2dev -L tk -m $magnification < $fig_input > $tmp
status=$?
if test $status -ne 0; then
    echo "fig2dev: command failed."
    /bin/rm -f $tmp
    exit $status
fi
# -----------------------------------------------------
# get size from line such as:
#	canvas .c -width 9.43i -height 1.00i -bg ivory
# -----------------------------------------------------
width_in_inch=` grep "^canvas" $tmp | awk '{print $4}' | sed -e 's/i//' `
height_in_inch=`grep "^canvas" $tmp | awk '{print $6}' | sed -e 's/i//' `
# -----------------------------------------------------
# if failed, try the new fig2dev output :
#   set xfigCanvas [canvas .c -width 6.90i -height 0.82i]
# -----------------------------------------------------
if test x"$width_in_inch" = x"" -o x"$height_in_inch" = x""; then
  width_in_inch=` grep "^set xfigCanvas" $tmp | awk '{print $6}' | sed -e 's/i//' `
  height_in_inch=`grep "^set xfigCanvas" $tmp | awk '{print $8}' | sed -e 's/i//' -e 's/\]//' `
fi
#echo "width_in_inch $width_in_inch"
#echo "height_in_inch $height_in_inch"
if test x"$width_in_inch" = x"" -o x"$height_in_inch" = x""; then
    echo "title_fig2tcl: failed to catch bounding box" >&2
    exit 1
fi
#
# get bounding box such that
#	$xfigCanvas config -xscrollincrement 1p -yscrollincrement 1p
#	$xfigCanvas xview scroll 22 u
#	$xfigCanvas yview scroll 28 u
scroll_x_in_point=` grep "xview" $tmp | awk '{print $4}' | sed -e 's/i//' `
scroll_y_in_point=` grep "yview" $tmp | awk '{print $4}' | sed -e 's/i//' `
# ----------------------------------------------------------------------
# generates the defs output
# ----------------------------------------------------------------------
echo "# do not edit." > $tcl_output
echo "# file automatically generated by:" >> $tcl_defs_output
echo "#		$0 $*" >> $tcl_defs_output
echo "set ${name}_width_in_inch  ${width_in_inch}"  >> $tcl_defs_output
echo "set ${name}_height_in_inch ${height_in_inch}" >> $tcl_defs_output
echo "set ${name}_scroll_x_in_point ${scroll_x_in_point}"  >> $tcl_defs_output
echo "set ${name}_scroll_y_in_point ${scroll_y_in_point}" >> $tcl_defs_output
echo "! \"$tcl_defs_output\" created."
# ----------------------------------------------------------------------
# generates the fig output
# ----------------------------------------------------------------------
echo "# do not edit." > $tcl_output
echo "# file automatically generated by:" >> $tcl_output
echo "#		$0 $*" >> $tcl_output
echo "" >> $tcl_output
echo "set ${name} ${window_hierarchy}"  >> $tcl_output
echo "" >> $tcl_output
echo "canvas \${${name}} -width \${${name}_width_in_inch}i -height \${${name}_height_in_inch}i \\" >> $tcl_output
echo "	-bg                 ${color_bg} \\" >> $tcl_output
echo "	-highlightthickness 0" >> $tcl_output
echo "" >> $tcl_output
echo "\${${name}} config -xscrollincrement 1p -yscrollincrement 1p" >> $tcl_output
echo "\${${name}} xview scroll \${${name}_scroll_x_in_point} u" >> $tcl_output
echo "\${${name}} yview scroll \${${name}_scroll_y_in_point} u" >> $tcl_output
echo "" >> $tcl_output
echo "pack \${${name}} -side ${side}" >> $tcl_output
echo "" >> $tcl_output
echo "# The xfig objects begin here" >> $tcl_output

cat $tmp | \
sed \
   -e '1,/# The xfig objects begin here/d' \
   -e "s/xfigCanvas/\{${name}\}/g" \
   -e '/focus/d' \
   -e 's/#0000ff/$tkxox(color_title_fg)/g' \
   -e 's/#ff0000/$tkxox(color_title_fg)/g' \
   -e 's/#ffff00/$tkxox(color_title_logo_fg)/g' \
   -e 's/#ff00ff/$tkxox(color_title_logo_fg)/g' \
   -e 's/#00ff00/$tkxox(color_title_bg)/g' \
 >> $tcl_output
 
echo "! \"$tcl_output\" created."

/bin/rm -f $tmp
