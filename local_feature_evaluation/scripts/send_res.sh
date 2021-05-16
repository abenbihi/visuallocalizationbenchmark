#!/bin/sh

data=aachen

#method=anubis
#trials=23_bis

server=benbiass@147.32.84.13:

remote_vlb_dir=/datagrid/personal/benbiass/ws/tools/vlb/local_feature_evaluation/

method=adalam
match_trial=0
#loc_iter=0

loc_iter_max=1
match_iter_max=1

res_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/

match_iter=0
while [ "$match_iter" -lt "$match_iter_max" ];
do
  loc_iter=0
  while [ "$loc_iter" -lt "$loc_iter_max" ];
  do
    res_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/

    ssh benbiass@147.32.84.13 "cd "$remote_vlb_dir"; mkdir -p "$res_path""
    if [ "$?" -ne 0 ]; then
      echo "Error: failed to create remote directory."
      exit 1
    fi

    rsync -avh "$res_path"/Aachen_eval_"$method".txt "$server""$remote_vlb_dir""$res_path"
    if [ "$?" -ne 0 ]; then
      echo "Error: failed to send file."
      echo "File to send: "$res_dir"/Aachen_eval_"$method".txt"
      echo "Destination: "$remote_vlb_dir""$res_dir""
      exit 1
    fi
    loc_iter="$((loc_iter+1))"
  done
  match_iter="$((match_iter+1))"
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
