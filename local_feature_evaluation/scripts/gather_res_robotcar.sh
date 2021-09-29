#!/bin/sh
. ./scripts/export_path.sh

data=robotcar

method=sift
match_trial=91

method=horus
match_trial=10

match_iter=0
loc_iter=3

res_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/
mkdir -p "$res_path"

global_cam_id=right
global_res_path="$res_path"/ROBOT_eval_"$method"_"$global_cam_id".txt
rm -f "$global_res_path"

survey_id=0

# gather by camera
if [ 1 -eq 1 ]; then
  slice_id=0
  while read -r slice_id
  do
    # no queries
    if [ "$slice_id" = 1 ] || [ "$slice_id" -eq 7 ] || [ "$slice_id" -eq 8 ] || [ "$slice_id" -eq 43 ]; then
      continue
    fi

    echo "Gather "$slice_id" "$global_cam_id" "$survey_id""
    eval_fn="$res_path"/"$slice_id"_"$global_cam_id"_"$survey_id"/Aachen_eval_"$method".txt
    #eval_fn="$res_path"/"$slice_id"_"$cam_id"_"$survey_id"/Aachen_eval_"$method"_rear.txt
    if ! [ -f "$eval_fn" ]; then
      echo "Warning: no registered queries for "$slice_id"_"$global_cam_id""
      continue
    fi

    cat "$eval_fn" >> "$global_res_path"
    if [ "$?" -ne 0 ]; then
      echo "Error when copying results from "$eval_fn" to "$global_res_path""
      exit 1
    fi
  done < "$ROBOT_META_DIR"/debug_locations.txt
fi

# gather global res
if [ 0 -eq 1 ]; then
  slice_id=0
  #while [ "$slice_id" -le 48 ];
  #do
  #  slice_id="$((slice_id+1))"
  while read -r slice_id
  do

    # no queries
    if [ "$slice_id" = 1 ] || [ "$slice_id" -eq 7 ] || [ "$slice_id" -eq 8 ] || [ "$slice_id" -eq 43 ]; then
      continue
    fi

    ## empty ones for this xp
    #if [ "$slice_id" = 40 ]; then
    #  continue
    #fi

    #if [ "$slice_id" = 41 ]; then
    #  continue
    #fi

    #if [ "$slice_id" = 42 ]; then
    #  continue
    #fi

    for cam_id in right
    do
      echo "Gather "$slice_id" "$cam_id" "$survey_id""
      #eval_fn="$res_path"/"$slice_id"_"$cam_id"_"$survey_id"/Aachen_eval_"$method"_fullname.txt
      #eval_fn="$res_path"/"$slice_id"_"$cam_id"_"$survey_id"/Aachen_eval_"$method".txt
      eval_fn="$res_path"/"$slice_id"_"$cam_id"_"$survey_id"/Aachen_eval_"$method"_rear.txt
      if ! [ -f "$eval_fn" ]; then
        echo "Warning: no registered queries for "$slice_id"_"$cam_id""
        continue
      fi

      cat "$eval_fn" >> "$global_res_path"
      if [ "$?" -ne 0 ]; then
        echo "Error when copying results from "$eval_fn" to "$global_res_path""
        exit 1
      fi

      #cat "$eval_fn" >> "$slice_res_path"
      #if [ "$?" -ne 0 ]; then
      #  echo "Error when copying results from "$eval_fn" to "$slice_res_path""
      #  exit 1
      #fi

      #cat "$eval_fn" >> "$slice_cam_res_path"
      #if [ "$?" -ne 0 ]; then
      #  echo "Error when copying results from "$eval_fn" to "$slice_cam_res_path""
      #  exit 1
      #fi

    done
  done < "$ROBOT_META_DIR"/debug_locations.txt
fi

# gather res by camera
if [ 0 -eq 1 ]; then

  slice_id=0
  while [ "$slice_id" -le 48 ];
  do
    slice_id="$((slice_id+1))"

    slice_res_path="$res_path"/ROBOT_eval_"$method"_slice"$slice_id".txt
    rm -f "$slice_res_path"
    for cam_id in left rear right
    do
      slice_cam_res_path="$res_path"/ROBOT_eval_"$method"_slice"$slice_id"_c"$cam_id".txt
      rm -f "$slice_cam_res_path"
      echo "Gather "$slice_id" "$cam_id" "$survey_id""
      eval_fn="$res_path"/"$slice_id"_c"$cam_id"_"$survey_id"/Aachen_eval_"$method".txt

      cat "$eval_fn" >> "$global_res_path"
      if [ "$?" -ne 0 ]; then
        echo "Error when copying results from "$eval_fn" to "$global_res_path""
        exit 1
      fi

      cat "$eval_fn" >> "$slice_res_path"
      if [ "$?" -ne 0 ]; then
        echo "Error when copying results from "$eval_fn" to "$slice_res_path""
        exit 1
      fi

      cat "$eval_fn" >> "$slice_cam_res_path"
      if [ "$?" -ne 0 ]; then
        echo "Error when copying results from "$eval_fn" to "$slice_cam_res_path""
        exit 1
      fi

    done
done
fi
