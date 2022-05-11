#!/bin/bash -e
cd "$(dirname "$0")"

if [[ $# -ne 0 ]]; then
	for sourcefile in "$@"
	do
		smxfile="`echo $sourcefile | sed -e 's/\.sp$/\.smx/'`"
		echo -e "\nCompiling $sourcefile..."
		spcomp $sourcefile -E -w234 -O2 -v2 -i"include" -i"../../core/scripting/include" -o"../plugins/$smxfile"
	done
else
	for sourcefile in *.sp
	do
		smxfile="`echo $sourcefile | sed -e 's/\.sp$/\.smx/'`"
		echo -e "\nCompiling $sourcefile ..."
		spcomp $sourcefile -E -w234 -O2 -v2 -i"include" -i"../../core/scripting/include" -o"../plugins/$smxfile"
	done
fi
