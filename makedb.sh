#!/bin/bash
# parsing sf.net for initial database
# TODO: initialize all C/C++ files too!!

# create temporary dir
tmpdir=$(mktemp -d)
mkdir $tmpdir/pkgs/
echo "Using tmpdir $tmpdir"

wget -qP $tmpdir http://octave.sourceforge.net/packages.php
grep -Po '(?<=(<div class="package" id="))[^"]+' $tmpdir/packages.php > $tmpdir/sfnet_packages

echo -e "d.config={'packer.db' 'https://raw.githubusercontent.com/octave-de/packer-utils/master/sfnet.m'};\n\n" > sfnet.m
echo -e "d.sfnet={..." >> sfnet.m

while read -r line
do
	name=$line
	wget -qP $tmpdir http://octave.sourceforge.net/$name/index.html
	version=$(grep -Po '(?<=(<tr><td class="package_table">Package Version:</td><td>))[^</td></tr>]+' $tmpdir/index.html)
	license=$(grep -Po '(?<=(<tr><td class="package_table">License:</td><td><a href="COPYING.html">))[^</a></td></tr>]+' $tmpdir/index.html)
	rm $tmpdir/index.html

	wget -qP $tmpdir/pkgs/ http://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/$name-$version.tar.gz
	tar -C $tmpdir/pkgs/ -xf $tmpdir/pkgs/$name-$version.tar.gz
	extractfolder=$(tar tfz $tmpdir/pkgs/$name-$version.tar.gz |head -n1| cut -d/ -f1)
	echo -e "\n\n$extractfolder\n"
	echo -e "\t'sf.net' '$name' '$version' 'http://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/' '$license' {..." >> sfnet.m

	## function list
	# download package and get functions
	if [ -d $tmpdir/pkgs/$extractfolder/inst/ ]; then
		find $tmpdir/pkgs/$extractfolder/inst/ -maxdepth 1 -type f|sed s,^$tmpdir/pkgs/$extractfolder/inst/,, | tr "\\n" "'"|sed s/"'"/"' '"/g |rev | cut -c 3-| rev > $tmpdir/fnames
		ls $tmpdir/pkgs/$extractfolder/inst/|grep @| tr "\\n" "'"|sed s/"'"/"' '"/g |rev | cut -c 3-| rev > $tmpdir/fnames2
                sed -i s/".m'"/"'"/g "$tmpdir"/fnames
                sed -i s/".m'"/"'"/g "$tmpdir"/fnames2
		B=$(cat $tmpdir/fnames)
		D=$(cat $tmpdir/fnames2)
		if (( ${#B} > 0 )); then
			A="\t\t'"
		else
			A=""
		fi
		if (( ${#D} > 0 )); then
			C="'"
		else
			C=""
		fi
		E="} {..."
		echo -e "$A$B $C$D$E" >> sfnet.m
	else
		echo -e "\n\n} {..." >> sfnet.m
	fi
	## TODO
	# parse src/Makefile for .oct and .mex files!!


	## dep list
	n=$(grep Depends: $tmpdir/pkgs/$extractfolder/DESCRIPTION |awk -F':' '{print $2}'|grep -o "[,]"|wc -l)
        n=$(($n+1))
	for ((i=1; i<=n; i++))
        do
		deps=$(grep Depends: $tmpdir/pkgs/$extractfolder/DESCRIPTION |cut -d: -f2|awk -v i="$i" -F',' '{print$i}')
		echo -e "\t\t'$deps';" >> sfnet.m
        done
	deps=$(grep Depends $tmpdir/pkgs/$extractfolder/DESCRIPTION)
	echo -e "\t\t};\n\n" >> sfnet.m # list dependencies

done < $tmpdir/sfnet_packages
echo -e "};" >> sfnet.m

