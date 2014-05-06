#!/bin/bash

#tmpdir=$(mktemp -d)
#echo "Using tmpdir $tmpdir"

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
