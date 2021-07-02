#!/bin/sh

. ./scripts/export_path.sh

data=aachen
VERSION=0
#data=cmu

# TODO
#session_id=4d3btcg5rfkjv0pn6mk7j4jml473zz9r
session_id=8x9iz315tt0jgjj8njq2xhv1sdboxy5i

if [ "$data" = aachen ]; then
  # submit clustered results
  if [ 0 -eq 1 ]; then
    cluster_list="$AACHEN_META_DIR"/scenes/query_clusters/

    method=anubis
    match_trial=55

    method=horus
    match_trial=70

    match_iter=0
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
        --dataset aachen \
        --result_path "$result_path"

      if [ "$?" -ne 0 ]; then
        echo "Error when uploading "$result_path""
        exit 1
      fi

      echo "$result_path"
      #break

      sleep 1
    done < "$cluster_list"/cluster_names.txt
  else # submit complete results

    method=horus
    match_trial=71

    #method=sift
    #match_trial=51

    match_iter=0
    loc_iter=0

    #while [ "$match_trial" -le 65 ];
    #do
    #  match_trial="$((match_trial+1))"

      method_name="$method"_"$match_trial"_"$match_iter"_"$loc_iter"
      if [ "$VERSION" -eq 0 ]; then
        result_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/Aachen_eval_"$method".txt
        dataset=aachen
      elif [ "$VERSION" -eq 1 ]; then
        #result_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/Aachen_v1_1_eval_"$method".txt
        result_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/Aachen_eval_"$method".txt
        dataset=aachenv11
      else
        echo "Error: wrong data version: "$VERSION""
        exit 1
      fi

      if ! [ -f "$result_path" ]; then
        echo "Warning: no result path: "$result_path""
        continue
      fi

      echo "method_name: "$method_name""
      echo "result_path: "$result_path""

      python3 upload_results.py \
        --session_id "$session_id" \
        --method_name "$method_name" \
        --dataset "$dataset" \
        --result_path "$result_path"

      if [ "$?" -ne 0 ]; then
        echo "Error when uploading "$result_path""
        exit 1
      fi

      echo "$result_path"
      #break

      sleep 1
    #done
  fi
elif [ "$data" = cmu ]; then
  method=sift
  match_trial=10

  method=horus
  match_trial=0

  match_iter=0
  loc_iter=0
  res_dir=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/
  for slice_id in 2 3 4 5
  do
    for cam_id in 1 #0 1
    do
      cluster_name=slice"$slice_id"_c"$cam_id"
      echo "cluster_name: "$cluster_name""

      method_name="$method"_"$match_trial"_"$match_iter"_"$loc_iter"-"$cluster_name"
      result_path="$res_dir"/CMU_eval_"$method"_"$cluster_name".txt

      if ! [ -f "$result_path" ]; then
        echo "Warning: no result path: "$result_path""
        continue
      fi

      echo "method_name: "$method_name""
      echo "result_path: "$result_path""

      python3 upload_results.py \
        --session_id "$session_id" \
        --method_name "$method_name" \
        --dataset extended-cmu \
        --result_path "$result_path"

      if [ "$?" -ne 0 ]; then
        echo "Error when uploading "$result_path""
        exit 1
      fi

      echo "$result_path"
      #break

      sleep 1
    done
    #break
  done

else
  echo "Error: unknown data "$data""
  exit 1
fi
