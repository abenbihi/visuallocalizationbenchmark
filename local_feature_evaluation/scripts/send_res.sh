#!/bin/sh

data=aachen
method=anubis
trials=9

remote_dir=benbiass@147.32.84.13:/datagrid/personal/benbiass/ws/tools/vlb/local_feature_evaluation/

for trial in "$trials"
do
  res_dir=res/aachen/"$method"/"$trial"/
  #ssh benbiass@147.32.84.13 "cd "$remote_dir"; mkdir -p "$res_dir""
  #echo "$?"
  #if [ "$?" -ne 0 ]; then
  #  echo "Error: failed to create remote directory."
  #  exit 1
  #fi
  
  rsync -avh "$res_dir"/Aachen_eval_"$method".txt "$remote_dir""$res_dir"
  #rsync -avh res/"$data"/README.md  "$remote_dir"/res/"$data"
  echo "rsync -avh "$res_dir"/Aachen_eval_ngransac.txt "$remote_dir""$res_dir""
  if [ "$?" -ne 0 ]; then
    echo "Error: failed to send file."
    echo "File to send: "$res_dir"/Aachen_eval_ngransac.txt"
    echo "Destination: "$remote_dir""$res_dir""
    exit 1
  fi
done
