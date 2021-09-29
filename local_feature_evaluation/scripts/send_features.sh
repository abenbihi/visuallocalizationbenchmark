#!/bin/sh
# Send features to server.
# Send only the features that we actually use to save space

. ./scripts/export_path.sh

server=rci
#server=ritz
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
echo "dst: "$dst""

feat_dir=./data/aachen-day-night/features/all/
remote_feat_dir="$dst"/tools/vlb/local_feature_evaluation/data/aachen-day-night/features/

scene_trial=17
cluster_name=""

meta_dir="$AACHEN_META_DIR"/scenes/"$scene_trial"/"$cluster_name"/
image_path="$meta_dir"/images.txt

while read -r line
do
  echo "$line"
  if [ "$line" = "" ]; then
    continue
    #break
  fi
  fn="$(echo "$line" | cut -d' ' -f10)"
  echo "$fn"
  local_feat_fn="$feat_dir""$fn".txt
  
  remote_feat_fn="$remote_feat_dir"/"$fn".txt

  echo "$local_feat_fn"
  echo "$remote_feat_fn"

  rsync -avh "$local_feat_fn" "$remote_feat_fn"
  if [ "$?" -ne 0 ]; then
    echo "Error when sending "$local_feat_fn" to "$remote_feat_fn""
    exit 1
  fi
  #break
done < "$image_path"
