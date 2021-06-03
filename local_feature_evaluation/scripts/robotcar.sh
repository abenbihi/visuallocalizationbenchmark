#!/bin/sh

# TODO: make this arguments of the loc script
match_trial=11
match_iter=0
loc_iter=0

method=sift
#method=horus

res_dir=res/robotcar/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/
  
survey_id=0

slice_id=1
while [ "$slice_id" -le 48 ];
do
  slice_id="$((slice_id+1))"

  if [ "$slice_id" = 1 ]; then
    continue
  fi

  if [ "$slice_id" = 7 ]; then
    continue
  fi

  if [ "$slice_id" = 8 ]; then
    continue
  fi

  if [ "$slice_id" = 43 ]; then
    continue
  fi

  for cam_id in left rear right
  do
    echo "\n\n"$slice_id" "$cam_id" "$survey_id""
    eval_fn="$res_dir""$slice_id"_c"$cam_id"_"$survey_id"/Aachen_eval_"$method".txt
    if [ -f "$eval_fn" ]; then
      echo "Evaluation file already exists at "$eval_fn"\n"
      continue
    fi

    ./scripts/colmap_loc_import_py_robotcar.sh "$slice_id" "$cam_id" "$survey_id"
    if [ "$?" -ne 0 ]; then
      echo "Error when loc on "$slice_id" "$cam_id" "$survey_id""
      exit 1
    fi
    echo "... "$slice_id" "$cam_id" "$survey_id" done"
  done
done
