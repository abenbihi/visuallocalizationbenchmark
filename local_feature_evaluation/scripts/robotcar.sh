#!/bin/sh
. ./scripts/export_path.sh

if [ "$#" -ne 1 ]; then
  echo "Error: wrong number of arguments"
  echo "1. machine_id"
  exit 1
fi

machine_id="$1"

feat_name=sift # 99
#feat_name=superpoint # 100
feat_name=d2net # 101

method=sift
match_trial=100
match_iter=0
loc_iter=0
survey_id=0
use_extra_matches=0

method=horus
match_trial=14
match_iter=0
loc_iter=2
use_extra_matches=1


res_dir=res/robotcar/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/

#slice_id=2
#while [ "$slice_id" -le 2 ];
#do
#  slice_id="$((slice_id+1))"

while read -r slice_id
do
  #if [ "$slice_id" = 44 ] || [ "$slice_id" -eq 26 ]; then
  #  continue
  #fi

  if [ "$slice_id" -eq 1 ] || [ "$slice_id" -eq 7 ] || [ "$slice_id" -eq 8 ] || [ "$slice_id" -eq 43 ]; then
    continue
  fi

  for cam_id in left rear right
  do
    echo "\n\n"$slice_id" "$cam_id" "$survey_id""
    eval_fn="$res_dir""$slice_id"_"$cam_id"_"$survey_id"/Aachen_eval_"$method".txt
    if [ -f "$eval_fn" ]; then
      echo "Evaluation file already exists at "$eval_fn"\n"
      continue
    fi

    ##if [ -d res/robotcar/db_with_imported_features_superpoint/"$slice_id"_"$cam_id"_0 ]; then
    #if [ -d res/robotcar/db_with_imported_features_d2net/"$slice_id"_"$cam_id"_0 ]; then
    #  echo "Init db already exists, skip."
    #  continue
    #fi

    ./scripts/colmap_loc_import_py_robotcar.sh \
      "$slice_id" \
      "$cam_id" \
      "$survey_id" \
      "$method" \
      "$match_trial" \
      "$match_iter" \
      "$loc_iter" \
      "$use_extra_matches" \
      "$feat_name"

    if [ "$?" -ne 0 ]; then
      echo "Error when loc on "$slice_id" "$cam_id" "$survey_id""
      exit 1
    fi
    echo "... "$slice_id" "$cam_id" "$survey_id" done"
  done
#done < "$ROBOT_META_DIR"/debug_locations.txt
#done < "$ROBOT_META_DIR"/all_locations_with_queries.txt
done < "$ROBOT_META_DIR"/all_locations_with_queries_"$machine_id".txt
