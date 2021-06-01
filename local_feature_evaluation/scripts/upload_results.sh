#!/bin/sh

. ./scripts/export_path.sh

data=aachen

# TODO
session_id=4d3btcg5rfkjv0pn6mk7j4jml473zz9r

# submit clustered results
if [ 1 -eq 1 ]; then
  cluster_list="$AACHEN_META_DIR"/scenes/query_clusters/

  method=anubis
  match_trial=55
  match_iter=1
  loc_iter=0

  while read -r line
  do
    cluster_name="$(echo "$line" | cut -d' ' -f2 | cut -d'.' -f1)"
    echo "cluster_name: "$cluster_name""
  
    method_name="$method"_"$match_trial"_"$match_iter"_"$loc_iter"_"$cluster_name"
    result_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/Aachen_eval_"$method"_"$cluster_name".txt

    if ! [ -f "$result_path" ]; then
      echo "Warning: no result path: "$result_path""
      continue
    fi

    echo "method_name: "$method_name""
    echo "result_path: "$result_path""

    python3 upload_results.py \
      --session_id "$session_id" \
      --method_name "$method_name" \
      --result_path "$result_path"

    if [ "$?" -ne 0 ]; then
      echo "Error when uploading "$result_path""
      exit 1
    fi

    echo "$result_path"
    #break

    sleep 1
  done < "$cluster_list"/cluster_names.txt
fi
