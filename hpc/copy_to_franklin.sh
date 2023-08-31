#!/bin/bash

# check if the variable $FRANKLIN_USERNAME is set
if [ -z "$FRANKLIN_USERNAME" ]
then
		echo "Please set the FRANKLIN_USERNAME environment variable with your Franklin username."
		exit 1
fi

FILES_TO_COPY="configs models utils train_AutoEncoder_lightning.py train_Predictor_lightning.py"

# check the command line arguments:
# if -d is passed, then add "data" to FILES_TO_COPY
# if -m is passed, then add "dmbn-train.sif" to FILES_TO_COPY
while getopts ":dm" opt; do
	case ${opt} in
		d )
			FILES_TO_COPY="$FILES_TO_COPY data"
			;;
		m )
			FILES_TO_COPY="$FILES_TO_COPY npvp-ae.sif"
			;;
		\? )
			echo "Usage: hpc/copy_to_franklin.sh [-d] [-m]"
			echo "  -d: copy the data folder"
			echo "  -m: copy the npvp-ae.sif file"
			exit 1
			;;
	esac
done

#scp -r $FILES_TO_COPY $FRANKLIN_USERNAME@fe01.franklin.iit.local:/work/$FRANKLIN_USERNAME/npvp
tar -C .  -cf - $FILES_TO_COPY | ssh $FRANKLIN_USERNAME@fe01.franklin.iit.local tar -C /work/$FRANKLIN_USERNAME/npvp -xvf -