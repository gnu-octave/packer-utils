#!/bin/bash

## update packages
#printf "Updating hg.octave.de repository...\n"
#cd ~/mercurial/forge/
#hg pull
#hg update
#cd ~/github/fs/

#printf "Updating github repository...\n"
#cd ~/github/test/octave-hub
#git pull
#cd ~/github/fs/

## create database
sqlite3 fs.sql "create table fs (id INTEGER PRIMARY KEY, package TEXT, host TEXT, func TEXT)"
sqlite3 fs.sql "create table date (id INTEGER PRIMARY KEY, date TEXT)"
d=$(date +"%d.%B.%Y")
sqlite3 fs.sql "insert into date (date) values ('"$d"')"


HOST=forge
## update functions from hg.octave.de main
for p in `ls -1d ~/mercurial/forge/main/*`; do
  NAME=$(echo "$p"| sed s,'/home/markuman/mercurial/forge/main/','',)
  FOLDER="$p"
  echo "$NAME"
  I="$FOLDER"/INDEX
  # parse INDEX file if exist
  if [ -f "$FOLDER"/INDEX ]; then
    cat "$FOLDER"/INDEX |sed '/^[^ \t]\+/d'| sed "s/  //g"| sed "s/ /\n/g"> /tmp/INDEX
    while read f; do
      sqlite3 fs.sql "insert into fs (package, host, func) values ('"$NAME"', '"$HOST"', '"$f"')"
    done </tmp/INDEX

  fi
done

## update functions from hg.octave.de extra
for p in `ls -1d ~/mercurial/forge/extra/*`; do
  NAME=$(echo "$p"| sed s,'/home/markuman/mercurial/forge/extra/','',)
  FOLDER="$p"
  echo "$NAME"
  if [ "$NAME" != "Makefile" ] && [ "$NAME" != "CONTENTS" ]; then
    I="$FOLDER"/INDEX
    # parse INDEX file if exist
    if [ -f "$FOLDER"/INDEX ]; then
      cat "$FOLDER"/INDEX |sed '/^[^ \t]\+/d'| sed "s/  //g"| sed "s/ /\n/g"> /tmp/INDEX
      while read f; do
        sqlite3 fs.sql "insert into fs (package, host, func) values ('"$NAME"', '"$HOST"', '"$f"')"
      done </tmp/INDEX
    fi
  fi
done

HOST=github
## update functions from github
for p in `ls -1d ~/github/test/octave-hub/*`; do
  NAME=$(echo "$p"| sed s,'/home/markuman/github/test/octave-hub/','',)
  FOLDER="$p"
  echo "$NAME"
  I="$FOLDER"/INDEX
  # parse INDEX file if exist
  if [ -f "$FOLDER"/INDEX ]; then
    cat "$FOLDER"/INDEX |sed '/^[^ \t]\+/d'| sed "s/  //g"| sed "s/ /\n/g"> /tmp/INDEX
    while read f; do
      sqlite3 fs.sql "insert into fs (package, host, func) values ('"$NAME"', '"$HOST"', '"$f"')"
    done </tmp/INDEX
  else
##    find "$FOLDER"/inst/ -maxdepth 1 -type f|sed s,^$FOLDER/inst/,,|sed '/^[private/]\+/d'  > /tmp/INDEX
      find "$FOLDER"/inst/ -maxdepth 2 -type f > /tmp/INDEX
    while read f; do
      y=${f%.m}
      sqlite3 fs.sql "insert into fs (package, host, func) values ('"$NAME"', '"$HOST"', '"${y##*/}"')"
    done </tmp/INDEX
  fi
done

