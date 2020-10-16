#!/bin/sh

data=aachen
method=oanet
trials=2

remote_url=benbiass@147.32.84.13
remote_dir=/datagrid/personal/benbiass/ws/tools/vlb/local_feature_evaluation/

for trial in "$trials"
do
  res_dir=res/aachen/"$method"/"$trial"/loc
  ssh benbiass@147.32.84.13 "cd "$remote_dir"; mkdir -p "$res_dir""
  #echo "ssh benbiass@147.32.84.13 cd "$remote_dir"; echo mkdir -p "$res_dir""
  
  echo "$?"
  if [ "$?" -ne 0 ]; then
    echo "Error: failed to create remote directory."
    exit 1
  fi
  
  rsync -avh "$res_dir"/Aachen_eval_"$method".txt "$remote_url":"$remote_dir""$res_dir"
  rsync -avh res/"$data"/"$method"/README.md  "$remote_url":"$remote_dir"/res/"$data"/"$method"
  #echo "rsync -avh "$res_dir"/Aachen_eval_ngransac.txt "$remote_url":"$remote_dir""$res_dir""
  #echo "rsync -avh res/"$data"/README.md  "$remote_url":"$remote_dir"/res/"$data""
 
  if [ "$?" -ne 0 ]; then
    echo "Error: failed to send file."
    echo "File to send: "$res_dir"/Aachen_eval_ngransac.txt"
    echo "Destination: "$remote_url":"$remote_dir""$res_dir""
    exit 1
  fi
done
