#!/bin/sh
#PBS -N dmbn-training
#PBS -l select=4:ncpus=8:mpiprocs=8:ngpus=4:scratch=8gb
#PBS -q gpu
#PBS -M marco.fedozzi@iit.it
#PBS -m abe
#PBS -j oe

WORKDIR=/work/$USER
FASTWORK=/fastwork/$USER # highly volatile memory, data is copied there
DATADIR=/scratch # location of the data from *within* the container

# check if folder USER exists in /fastwork
if [ -d "$FASTWORK/data" ]
	then
		echo "$FASTWORK already exists, avoid copying data"
	else
		echo "Copying data to $FASTWORK"
		cp -r $PBS_O_WORKDIR/data $FASTWORK
fi

BIND="./:/home/$USER,$FASTWORK:$DATADIR" # bind scratchdir to container

cd $WORKDIR/npvp
module load go-1.19.4/apptainer-1.1.8 # the "new singularity"

apptainer run -c --nv --bind $BIND npvp-ae.sif config_BAIR_Autoencoder.yaml
# notice that the container will read/write from files that, from the point of view of the container, are in $DATADIR
# but that for the host are located in $FASTWORK (if set) or in $PBS_O_WORKDIR (if not set)

#cp -r $FASTWORK/results_@MODEL_SUFFIX@/$MODEL_NAME $PBS_O_WORKDIR/results_@MODEL_SUFFIX@ # copy results in non-volatile memory