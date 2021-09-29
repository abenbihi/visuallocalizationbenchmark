#!/bin/sh

# Download results from remote backup


#server=ritz
#if [ "$server" = ritz ]; then
#  address=benbiass@147.32.84.13
#  remote_ws=/datagrid/personal/benbiass/ws/
#else 
#  echo "Error: unspecified server"
#  exit 1
#fi
#

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
remote_vlb_dir="$remote_ws"/tools/vlb/local_feature_evaluation/

data=aachen

method=adalam
match_trial=0

method=anubis
match_trial=53

method=horus
match_trial=171

#method=sift
#match_trial=76

while [ "$match_trial" -le 171 ];
do
  match_trial="$((match_trial+1))"
loc_iter_max=2
match_iter_max=1

res_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/

match_iter=0
while [ "$match_iter" -lt "$match_iter_max" ];
do
  loc_iter=1
  while [ "$loc_iter" -lt "$loc_iter_max" ];
  do
    res_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/
    mkdir -p "$res_path"

    #rsync -avh  "$address":"$remote_vlb_dir""$res_path"/Aachen_eval_"$method"*.txt "$res_path"
    rsync -avh  "$address":"$remote_vlb_dir""$res_path"/Aachen*"$method"*.txt "$res_path"
    if [ "$?" -ne 0 ]; then
      echo "Error: failed to get file."
      echo "File to get: "$remote_vlb_dir""$res_path"/Aachen_eval_"$method".txt"
      echo "Origin: "$address""
      exit 1
    fi
    loc_iter="$((loc_iter+1))"
  done
  match_iter="$((match_iter+1))"
done
done # while [ "$match_trial" -le  ];

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
