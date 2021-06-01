#!/bin/sh

remote_dir=benbiass@147.32.84.13:/datagrid/personal/benbiass/ws/tools/vlb/local_feature_evaluation/
remote_dir=benbiass@login.rci.cvut.cz:/home/benbiass/ws/tools/vlb/local_feature_evaluation/

# TODO
data=aachen
method=adalam

match_trial=0
match_iter_max=1

loc_iter_max=3

match_iter=0
while [ "$match_iter" -lt "$match_iter_max" ];
do
    loc_iter=2
    while [ "$loc_iter" -lt "$loc_iter_max" ];
    do
        res_dir=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/
        loc_iter="$((loc_iter+1))"

        mkdir -p "$res_dir"
        echo "rsync -avh "$remote_dir""$res_dir"/Aachen_eval_"$method".txt \ "
        echo "    "$res_dir""

        rsync -avh "$remote_dir""$res_dir"/Aachen_eval_"$method".txt \
            "$res_dir"

        i="$((i+1))"
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
