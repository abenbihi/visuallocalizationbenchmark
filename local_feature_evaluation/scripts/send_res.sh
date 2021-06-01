#!/bin/sh

data=aachen

#method=anubis
#trials=23_bis

server=ritz
if [ "$server" = ritz ]; then
  address=benbiass@147.32.84.13
  remote_ws=/datagrid/personal/benbiass/ws/
else 
  echo "Error: unspecified server"
  exit 1
fi

remote_vlb_dir="$remote_ws"/tools/vlb/local_feature_evaluation/

method=adalam
match_trial=0

method=anubis
match_trial=55

loc_iter_max=1
match_iter_max=2

res_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/

match_iter=0
while [ "$match_iter" -lt "$match_iter_max" ];
do
  loc_iter=0
  while [ "$loc_iter" -lt "$loc_iter_max" ];
  do
    res_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/

    ssh "$address" "cd "$remote_vlb_dir"; mkdir -p "$res_path""
    if [ "$?" -ne 0 ]; then
      echo "Error: failed to create remote directory."
      exit 1
    fi

    #rsync -avh "$res_path"/Aachen_eval_"$method".txt "$address":"$remote_vlb_dir""$res_path"
    rsync -avh "$res_path"/Aachen_eval_"$method"*.txt "$address":"$remote_vlb_dir""$res_path"
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
