#!/bin/bash
# double comments ## means "not implemented atm"

# cell schema
# db.config {1,1}='packer.db'; {1,2}='database update url'
# db.sfnet
## db.github
## add db.github repo
## - https://github.com/cbm755/octsympy
## - https://github.com/markuman/go-redis
## - https://github.com/markuman/go-sqlite
## - https://github.com/dac922/octave-instrument-control
## - https://github.com/goffioul/QtHandles
## do you know more?

# {1,1}: Driver (e.g. sfnet)
# {1,2}: Package name
# {1,3}: Version number
# {1,4}: Direct download url ( "https://.../%s-%s.tar.gz", package, version )
# {1,5}: Licence
# {1,6}: List of included functions
# {1,7}: List dependencies
## {1,8}: Description


## TODO
## ====
## parse just INDEX file 
##sed '/^[^ \t]\+/d' INDEX

###### BEGIN parsing initial database
###### ==============================

# create temporary dir
tmpdir=$(mktemp -d)
mkdir $tmpdir/pkgs/
echo "Using tmpdir $tmpdir"

wget -qP $tmpdir http://octave.sourceforge.net/packages.php
grep -Po '(?<=(<div class="package" id="))[^"]+' $tmpdir/packages.php > $tmpdir/sfnet_packages

## add db.config

echo -e "d.config={'packer.db' 'https://raw.githubusercontent.com/octave-de/packer-utils/master/sfnet.m'};\n\n" > sfnet.m

## add db.sfnet

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


    if [ -f "$tmpdir"/pkgs/"$extractfolde"/INDEX ]
    then
        ## TODO: REPLACEMENT HERE FOR PARSING INDEX
        ## ==================================
	    ## function list
	    # download package and get functions
	    # sed '/^[^ \t]\+/d' INDEX |sed "s/  /,'/g"|tr "\\n" "'"|cut -c 2-
	    A=$(sed '/^[^ \t]\+/d' $tmpdir/pkgs/$extractfolder/INDEX |sed "s/  /,'/g"|tr "\\n" "'"|cut -c 2-)
	    B="} {..."
	    echo -e "$A$B" >> sfnet.m
	    ## END TODO:
	    ## =========
    else
	    # no INDEX file exist in this package
	    # parse files in folder ... good luck
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
		echo -e "} { ..." >> sfnet.m
	    fi

    fi




	## dep list
	n=$(grep Depends: $tmpdir/pkgs/$extractfolder/DESCRIPTION |awk -F':' '{print $2}'|grep -o "[,]"|wc -l)
        n=$(($n+1))
	for ((i=1; i<=n; i++))
        do
		deps=$(grep Depends: $tmpdir/pkgs/$extractfolder/DESCRIPTION |cut -d: -f2|awk -v i="$i" -F',' '{print$i}')
		echo -e "\t\t'$deps';" >> sfnet.m
        done
	deps=$(grep Depends $tmpdir/pkgs/$extractfolder/DESCRIPTION)
	description=$(grep Description $tmpdir/pkgs/$extractfolder/DESCRIPTION | sed s/'Description: '//)
	echo -e '\t\t} "$description";\n' >> sfnet.m

    ## TODO: Add description

done < $tmpdir/sfnet_packages
echo -e "};" >> sfnet.m



githubarray=("https://github.com/cbm755/octsympy" "https://github.com/markuman/go-sqlite" "https://github.com/dac922/octave-instrument-control")

#echo ${githubarray[0]}
#echo ${#githubarray[@]}

echo -e "d.github={..." > github.m
for n in "${githubarray[@]}"
do
	echo $n
	f=$(echo "$n"|sed 's/https:\/\/github.com\///'|awk -F/ '{print$2}')
	git clone "$n".git "$tmpdir"/"$f"

	name=$(grep Name: $tmpdir/$f/DESCRIPTION |awk '{print$2}')
	version=$(grep Version: $tmpdir/$f/DESCRIPTION |awk '{print$2}')
	license=$(grep License: $tmpdir/$f/DESCRIPTION |awk '{print$2}')
	echo -e "\t'github' '$name' '$version' '$n' '$license' {..." >> github.m

	if [ -f "$tmpdir"/"$f"/INDEX ]
	then
		A=$(sed '/^[^ \t]\+/d' $tmpdir/$f/INDEX |sed "s/  /,'/g"|tr "\\n" "'"|cut -c 2-)
		B="} {..."
		echo -e "$A$B" >> github.m
	else
            if [ -d "$tmpdir"/"$f"/inst/ ]; then
		find $tmpdir/$f/inst/ -maxdepth 1 -type f|sed s,^$tmpdir/$f/inst/,, | tr "\\n" "'"|sed  s/"'"/"' '"/g |rev | cut -c 3-| rev > $tmpdir/fnames
                ls $tmpdir/$f/inst/|grep @| tr "\\n" "'"|sed s/"'"/"' '"/g |rev | cut -c 3-| rev > $tmpdir/fnames2
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
                echo -e "$A$B $C$D$E" >> github.m
            else
                echo -e "} { ..." >> github.m
            fi
	fi

        m=$(grep Depends: $tmpdir/$f/DESCRIPTION |awk -F':' '{print $2}'|grep -o "[,]"|wc -l)
        m=$(($m+1))
        for ((i=1; i<=m; i++))
        do
                deps=$(grep Depends: $tmpdir/$f/DESCRIPTION |cut -d: -f2|awk -v i="$i" -F',' '{print$i}')
                echo -e "\t\t'$deps';" >> github.m
        done
        deps=$(grep Depends $tmpdir/$f/DESCRIPTION)
        description=$(grep Description $tmpdir/$f/DESCRIPTION | sed s/'Description: '//)
        echo -e "\t\t} '$description';\n" >> github.m


done
echo -e '\t};' >> github.m
