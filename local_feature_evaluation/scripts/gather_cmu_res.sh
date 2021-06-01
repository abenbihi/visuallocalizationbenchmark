#!/bin/sh

method=sift
match_trial=9

method=horus
match_trial=0

match_iter=0
loc_iter=0

res_path=res/cmu/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/

global_res_path="$res_path"/CMU_eval_"$method".txt
rm -f "$global_res_path"

for slice_id in 2
do
  slice_res_path="$res_path"/CMU_eval_"$method"_slice"$slice_id".txt
  rm -f "$slice_res_path"
  for cam_id in 0 #1
  do
    slice_cam_res_path="$res_path"/CMU_eval_"$method"_slice"$slice_id"_c"$cam_id".txt
    rm -f "$slice_cam_res_path"
    for survey_id in 0 1 2 3 4 5 6 7 8 9 10
    do
      echo "Gather "$slice_id" "$cam_id" "$survey_id""
      eval_fn="$res_path"/"$slice_id"_c"$cam_id"_"$survey_id"/Aachen_eval_"$method".txt

      cat "$eval_fn" >> "$global_res_path"
      cat "$eval_fn" >> "$slice_res_path"
      cat "$eval_fn" >> "$slice_cam_res_path"
    done
  done
done
