#!/bin/sh

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
match_trial=11

#method=horus
#match_trial=0

match_iter=0
loc_iter=0
      
res_dir=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/

if [ 1 -eq 1 ]; then
  survey_id=0

  slice_id=16
  while [ "$slice_id" -le 16 ];
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
      echo ""$slice_id" "$cam_id" "$survey_id""
      sub_res_dir="$res_dir"/"$slice_id"_"$cam_id"_"$survey_id"
      mkdir -p "$sub_res_dir"
      rsync -avh "$dst"tools/vlb/local_feature_evaluation/"$sub_res_dir"/Aachen*txt "$sub_res_dir"
      if [ "$?" -ne 0 ]; then
        echo "Error when getting results from "$sub_res_dir""
        exit 1
      fi
    done
  done
fi

if [ 1 -eq 1 ]; then
  mkdir -p "$res_dir"
rsync -avh "$dst"tools/vlb/local_feature_evaluation/"$res_dir"/*txt "$res_dir"
if [ "$?" -ne 0 ]; then
  echo "Error when getting global results from "$res_dir""
  exit 1
fi
fi
