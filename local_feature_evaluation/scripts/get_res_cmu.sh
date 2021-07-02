#!/bin/sh

data=cmu

server=rci
server=ritz
#server=lascar

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
echo "dst: "$dst""

remote_vlb_dir="$remote_ws"/tools/vlb/local_feature_evaluation/

method=adalam
match_trial=0

method=anubis
match_trial=55

method=sift
match_trial=9

loc_iter_max=1
match_iter_max=1

match_iter=0
while [ "$match_iter" -lt "$match_iter_max" ];
do
  loc_iter=0
  while [ "$loc_iter" -lt "$loc_iter_max" ];
  do
    res_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/

    for slice_id in 2
    do
      for cam_id in 0 #1
      do
        for survey_id in 0 1 2 3 4 5 6 7 8 9 10
        do

          suffix="$slice_id"_c"$cam_id"_"$survey_id"
          sub_res_path="$res_path"/"$suffix"/

          mkdir -p "$sub_res_path"
          if [ "$?" -ne 0 ]; then
            echo "Error: failed to create directory: "$sub_res_path"."
            exit 1
          fi

          rsync -avh \
            "$address":"$remote_vlb_dir""$sub_res_path"/Aachen_eval_"$method"*.txt \
            "$sub_res_path"
            
          if [ "$?" -ne 0 ]; then
            echo "Error: failed to send file."
            echo "File to send: "$res_dir"/Aachen_eval_"$method".txt"
            echo "Destination: "$remote_vlb_dir""$sub_res_path""
            exit 1
          fi
          loc_iter="$((loc_iter+1))"
        done
        match_iter="$((match_iter+1))"
      done
    done
  done
done

#for trial in "$trials"
#do
#  res_dir=res/aachen/"$method"/"$trial"/
#  #ssh benbiass@147.32.84.13 "cd "$remote_dir"; mkdir -p "$res_dir""
#  #echo "$?"
#  #if [ "$?" -ne 0 ]; then
#  #  echo "Error: failed to create remote directory."
#  #  exit 1
#  #fi
#  
#  rsync -avh "$res_dir"/Aachen_eval_"$method".txt "$remote_dir""$res_dir"
#  #rsync -avh res/"$data"/README.md  "$remote_dir"/res/"$data"
#  echo "rsync -avh "$res_dir"/Aachen_eval_ngransac.txt "$remote_dir""$res_dir""
#  if [ "$?" -ne 0 ]; then
#    echo "Error: failed to send file."
#    echo "File to send: "$res_dir"/Aachen_eval_ngransac.txt"
#    echo "Destination: "$remote_dir""$res_dir""
#    exit 1
#  fi
#done
