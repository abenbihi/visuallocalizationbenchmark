#!/bin/sh

for slice_id in 3 #3 4 6
do
  for cam_id in 0 1
  do
    for survey_id in 0 1 2 3 4 5 6 7 8 9 10
    do
      if [ -d res/cmu/elf/"$slice_id"_c"$cam_id"_"$survey_id"/ ]; then
        continue
      fi
      echo "Run slice "$slice_id" "$cam_id" "$survey_id""
      ./scripts/colmap_loc_import_py.sh "$slice_id" "$cam_id" "$survey_id"
      if [ "$?" -ne 0 ]; then
        echo "Error in loc "$slice_id" "$cam_id" "$survey_id""
        exit 1
      fi
    done
  done
done
