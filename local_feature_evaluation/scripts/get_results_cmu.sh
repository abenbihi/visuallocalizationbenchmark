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

data=cmu

method=sift
match_trial=10

method=horus
match_trial=1

match_iter=0
loc_iter=0
      
res_dir=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/

for slice_id in 2 3 4 5
do
  for cam_id in 0 1
  do
    for survey_id in 0 1 2 3 4 5 6 7 8 9 10
    do
      echo ""$slice_id" "$cam_id" "$survey_id""
      sub_res_dir="$res_dir"/"$slice_id"_c"$cam_id"_"$survey_id"
      mkdir -p "$sub_res_dir"
      rsync -avh "$dst"tools/vlb/local_feature_evaluation/"$sub_res_dir"/Aachen*txt "$sub_res_dir"
      if [ "$?" -ne 0 ]; then
        echo "Error when getting results from "$sub_res_dir""
        exit 1
      fi
    done
  done
done

rsync -avh "$dst"tools/vlb/local_feature_evaluation/"$res_dir"/*txt "$res_dir"
if [ "$?" -ne 0 ]; then
  echo "Error when getting global results from "$res_dir""
  exit 1
fi
