#!/bin/bash

# check if the variable $FRANKLIN_USERNAME is set
if [ -z "$FRANKLIN_USERNAME" ]
then
	echo "Please set the FRANKLIN_USERNAME environment variable with your Franklin username."
	exit 1
fi

DIR_SUFFIX=""
LEN_FTC=0

set_file_names () {
	# a function that reads all the trailing command line arguments and adds them to the FILES_TO_COPY array

	# loop over all the arguments
	for arg in "$@"
	do
		# if the argument starts with a dash, add it to the FILES_TO_EXCLUDE array
		if [[ $arg == "-h" ]]
		then
			echo "Usage: hpc/results_from_franklin.sh <files to copy> <-files to ignore>"
			echo "  NOTE: prefix a file with a dash to ignore it"
			exit 0
		elif [[ $arg == -* ]]
		then
			# remove the dash from the argument
			FILES_TO_EXCLUDE+=(${arg:1})

		# otherwise, add it to the FILES_TO_COPY array
		else
			# add the first name in args to the FILES_TO_COPY array prefixed with '--name '
			# if more files are present in arg then parse them with a for, adding them to the FILES_TO_COPY array
			# prefixed with '-o --name '
			LEN_FTC=$((LEN_FTC+1))

			if [ -z "$FILES_TO_COPY" ]; then
				FILES_TO_COPY+="-name '$arg'"
			else
				FILES_TO_COPY+=" -o -name '$arg'"
			fi

		fi
	done
}


set_file_names "$@"

# get the location of this bash script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SAVE_DIR=$SCRIPT_DIR/../NPVP_ckpts

FILES_TO_COPY="\( $FILES_TO_COPY \)"
echo "FILES_TO_COPY: ${FILES_TO_COPY}"


STR="donwloading files "${FILES[@]}" from Franklin"


# check if FILES_TO_EXCLUDE is not empty	

if [ ${#FILES_TO_EXCLUDE[@]} -ne 0 ]
then
	# if it is not empty, print the files to exclude
	STR+=" ,ignoring "${FILES_TO_EXCLUDE[@]}
	EXC=--exclude=${FILES_TO_EXCLUDE[@]}
fi

echo $STR" and saving them to $SAVE_DIR"

PATH_TO_RESULTS="/work/$FRANKLIN_USERNAME/npvp/NPVP_ckpts"

ssh $FRANKLIN_USERNAME@fe01.franklin.iit.local "find $PATH_TO_RESULTS -maxdepth 1 $FILES_TO_COPY -fprintf $PATH_TO_RESULTS/.findout '%P\0' ; tar --null -C $PATH_TO_RESULTS --files-from=$PATH_TO_RESULTS/.findout -cf - ${EXC}" | tar -C $SAVE_DIR -xvf -
