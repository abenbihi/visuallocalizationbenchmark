#!/bin/sh

. ./scripts/export_path.sh

#TODO
server=rci
server=lascar

# set server path
if [ "$server" = rci ]; then
  address=benbiass@login.rci.cvut.cz
  remote_ws=/home/benbiass/ws/
elif [ "$server" = ritz ]; then
  address=benbiass@147.32.84.13
  remote_ws=/mnt/datagrid/personal/benbiass/ws/
elif [ "$server" = lascar ]; then
  #address=benbiass@192.168.85.150
  address=benbiass@lcraid.felk.cvut.cz
  remote_ws=/mnt/ssd/temporary/benbiass/ws/
else
  echo "Error: server not specified."
  exit 1
fi
dst="$address":"$remote_ws"

data=robotcar

method=sift
match_trial=91

method=horus
match_trial=10

match_iter=0
loc_iter=3
      
res_dir=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/

if [ 1 -eq 1 ]; then
  survey_id=0

  #slice_id=2
  #while [ "$slice_id" -le 2 ];
  #do
  #  slice_id="$((slice_id+1))"
  while read -r slice_id
  do
    if [ "$slice_id" = 1 ] || [ "$slice_id" -eq 7 ] || [ "$slice_id" -eq 8 ] || [ "$slice_id" -eq 43 ]; then
      continue
    fi

    #for cam_id in left rear right
    for cam_id in left right #rear
    do
      echo ""$slice_id" "$cam_id" "$survey_id""
      sub_res_dir="$res_dir"/"$slice_id"_"$cam_id"_"$survey_id"
      mkdir -p "$sub_res_dir"
      rsync -avh "$dst"tools/vlb/local_feature_evaluation/"$sub_res_dir"/Aachen*txt "$sub_res_dir"
      if [ "$?" -ne 0 ]; then
        echo "Error when getting results from "$sub_res_dir""
        exit 1
      fi
    done
  done < "$ROBOT_META_DIR"/debug_locations.txt
fi

if [ 1 -eq 1 ]; then
  mkdir -p "$res_dir"
rsync -avh "$dst"tools/vlb/local_feature_evaluation/"$res_dir"/*txt "$res_dir"
if [ "$?" -ne 0 ]; then
  echo "Error when getting global results from "$res_dir""
  exit 1
fi
fi
