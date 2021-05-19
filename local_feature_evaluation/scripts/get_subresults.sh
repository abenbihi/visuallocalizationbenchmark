#!/bin/sh

. ./scripts/export_path.sh

data=aachen
data_dir=data/aachen-day-night/
#colmap_dir="$WS_DIR"tools/colmap/build/src/exe/
colmap_dir=/usr/local/bin/
img_dir="$VLB_DIR"/data/aachen-day-night/images/images_upright/
cluster_list="$AACHEN_META_DIR"/scenes/query_clusters/
scene_trial=20 # colmap format

method=adalam
match_trial=0

#method=horus
#match_trial=43

method=anubis
match_trial=47

method=sift
match_trial=5

match_iter=0
loc_iter=0
res_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/
all_res_fn="$res_path"/Aachen_eval_"$method".txt
method_names="$res_path"/method_names.txt

while read -r line
do
  cluster_name="$(echo "$line" | cut -d' ' -f2 | cut -d'.' -f1)"
  echo "cluster_name: "$cluster_name""
  #continue
  meta_dir="$AACHEN_META_DIR"/scenes/"$scene_trial"/"$cluster_name"

  sub_res_fn="$res_path"/Aachen_eval_"$method"_"$cluster_name".txt
  #echo "$sub_res_fn"
  #exit 0

  echo "$method"_"$match_trial"_"$match_iter"_"$loc_iter"_"$cluster_name" >> "$method_names"

  while read -r line
  do
    is_query="$(echo "$line" | grep query | wc -c)"

    if [ "$is_query" -le 0 ]; then
      continue
    fi
    #echo "$is_query"
    #echo "$line"

    query_name="$(echo "$line" | cut -d' ' -f10)"
    #echo "$query_name"

    sub_query_name="$(echo "$query_name" | cut -d'/' -f4)"
    #echo "$sub_query_name"

    sub_res="$(grep "$sub_query_name" "$all_res_fn")"
    is_registered="$(echo "$sub_res" | wc -c)"
    #echo "$is_registered"
    if [ "$is_registered" -le 1 ]; then
      echo "Not registered: "$sub_query_name""
      continue
    fi
    echo "$sub_res" >> "$sub_res_fn"

    if [ "$?" -ne 0 ]; then
      echo "error"
      exit 1
    fi

  done < "$meta_dir"/images.txt
done < "$cluster_list"/cluster_names.txt
