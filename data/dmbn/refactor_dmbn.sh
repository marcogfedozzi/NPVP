#!/bin/bash

# Take a directory path from command line (DIR_OOT)
# Parse all the folders in DIR_ROOT directory, each of which contains 2 folders: 'grasp', 'move'
# in all the subfolders of 'grasp' and 'move' add a .txt. file named 'lable.txt' with the content 'grasp' or 'move' depending on the folder name
# then move all the folders in 'grasp' and 'move' to the parent directory

# Example of current structure:
# - train
#  - grasp
#   - 1
#    - img0.png
#    - img1.png
#   - 2
#    - img0.png
#    - ...
#  - move
#   - 3
#    - img0.png
#    - ...

# Example of desired structure:
# - train
#  - 1
#   - img0.png
#   - img1.png
#   - label.txt
#  - 2
#   - img0.png
#   - ...
#
# Finally, merge valid and train datasets (split them later from code)


if [ -z "$1" ] || [ "$1" == " " ]; then
    DIR_ROOT=$(pwd)
else
    DIR_ROOT=$1
fi


for folder in $DIR_ROOT/*; do
    if [ -d "$folder" ]; then
        for subfolder in $folder/*; do
            if [ -d "$subfolder" ]; then
                for subsubfolder in $subfolder/*; do
                    if [ -d "$subsubfolder" ]; then
                        #echo $folder
                        #echo $subfolder
                        #echo $subsubfolder
                        ACTION=$(basename $subfolder)
                        # get NUM of folder, cast it to INT and then add 50 if ACTION
                        NUM=$(basename $subsubfolder)
                        if [ "$ACTION" == "grasp" ]; then
                            NUM=$((NUM+50))
                        fi
                        echo $ACTION > $subsubfolder/label.txt
                        mogrify -resize 64x64 $subsubfolder/*.jpeg
                        mogrify -format png $subsubfolder/*.jpeg
                        rm -rf $subsubfolder/*.jpeg
                        mv $subsubfolder $folder/$NUM
                    fi
                done
            fi
            rm -r $subfolder
        done
    fi
done

mv valid/* train/
rm -r valid