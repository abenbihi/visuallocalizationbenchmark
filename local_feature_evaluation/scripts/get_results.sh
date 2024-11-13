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

data=aachen

method=sift
match_trial=12

method=horus
match_trial=61

match_iter=0
loc_iter=1
      
res_dir=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/

if [ 1 -eq 1 ]; then
  mkdir -p "$res_dir"
rsync -avh "$dst"tools/vlb/local_feature_evaluation/"$res_dir"/Aachen*txt "$res_dir"
if [ "$?" -ne 0 ]; then
  echo "Error when getting global results from "$res_dir""
  exit 1
fi
fi
