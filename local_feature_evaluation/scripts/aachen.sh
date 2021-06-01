#!/bin/sh
# rci: salloc -p gpufast --gres=gpu:1 --mincpus=16 -t 240
. ./scripts/export_path.sh

data=aachen
data_dir=data/aachen-day-night/
#colmap_dir="$WS_DIR"tools/colmap/build/src/exe/
colmap_dir=/usr/local/bin/
img_dir="$VLB_DIR"/data/aachen-day-night/images/images_upright/

# TODO
method=adalam
method=horus
#method=anubis
num_threads=16

cluster_name=""
#cluster_name=impasse_church

if [ "$cluster_name" = "" ]; then
  match_list="$data_dir"image_pairs_to_match.txt
  #match_list="$data_dir"image_pairs_to_match_light1.txt
else
  scene_trial=20 # query clusters
  meta_dir="$AACHEN_META_DIR"/scenes/"$scene_trial"/"$cluster_name"/
  match_list="$meta_dir"/pairs.txt
fi

echo "method: "$method""
echo "cluster_name: "$cluster_name""
echo "match_list: "$match_list""

if [ "$method" = "horus" ] || [ "$method" = "anubis" ] ; then
  echo "LOCALIZATION for "$method""

  feat_path="$VLB_DIR"/data/aachen-day-night/features/ #images_upright_subset/
  horus_match_path="$WS_DIR"/tools/anubis/res/localization/

  match_trial=59
  match_iter_max=1
  match_iter=0

  loc_iter_max=2
  echo "feat_path: "$feat_path""

  echo "Match trial: "$match_trial""
  while [ "$match_iter" -lt "$match_iter_max" ];
  do
    echo "Match iter: "$match_iter""
    match_path="$horus_match_path"/"$match_trial"/"$match_iter"/"$cluster_name"/point_matches/

    echo "match_path: "$match_path""

    loc_iter=1
    while [ "$loc_iter" -lt "$loc_iter_max" ];
    do
      echo "Match iter / Loc iter: "$match_iter" / "$loc_iter""
      res_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$cluster_name"/"$loc_iter"/
      loc_iter="$((loc_iter+1))"

      rm -rf "$res_path"
      mkdir -p "$res_path"

      if [ 1 -eq 1 ]; then
        python3 aachen_custom_matches.py \
          --dataset_path "$data_dir" \
          --colmap_path "$colmap_dir" \
          --method_name "$method" \
          --res_path "$res_path" \
          --feat_path "$feat_path" \
          --match_path "$match_path" \
          --num_threads "$num_threads" \
          --format "$method" \
          --match_list "$match_list"
      fi
 
      if [ 0 -eq 1 ]; then
        box_corner_path="$horus_match_path"/"$match_trial"/distorted_box_corner_features/
        box_corner_match_path="$horus_match_path"/"$match_trial"/"$match_iter"/"$cluster_name"/box_point_matches/

        python3 aachen_custom_matches_and_box_corners.py \
          --dataset_path "$data_dir" \
          --colmap_path "$colmap_dir" \
          --method_name "$method" \
          --res_path "$res_path" \
          --feat_path "$feat_path" \
          --box_corner_path "$box_corner_path" \
          --match_path "$match_path" \
          --box_corner_match_path "$box_corner_match_path" \
          --num_threads "$num_threads" \
          --format "$method" \
          --match_list "$match_list"
      fi

    done
    match_iter="$((match_iter+1))"
  done
fi

if [ "$method" = "adalam" ]; then
  echo "LOCALIZATION for "$method""
  feat_path="$VLB_DIR"/data/aachen-day-night/features/images_upright_subset/
  adalam_match_path="$WS_DIR"/tools/AdaLAM/res/aachen/

  match_trial=0
  match_iter_max=2
  match_iter=0

  loc_iter_max=2
  echo "feat_path: "$feat_path""

  echo "Match trial: "$match_trial""
  while [ "$match_iter" -lt "$match_iter_max" ];
  do
    #echo "Match iter: "$match_iter""
    match_path="$adalam_match_path"/"$match_trial"/"$match_iter"/
    echo "match_path: "$match_path""

    loc_iter=0
    while [ "$loc_iter" -lt "$loc_iter_max" ];
    do
      echo "Match iter / Loc iter: "$match_iter" / "$loc_iter""
      res_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/
      loc_iter="$((loc_iter+1))"

      rm -rf "$res_path"
      mkdir -p "$res_path"

      python3 aachen_custom_matches.py \
        --dataset_path "$data_dir" \
        --colmap_path "$colmap_dir" \
        --method_name "$method" \
        --res_path "$res_path" \
        --feat_path "$feat_path" \
        --match_path "$match_path" \
        --num_threads "$num_threads"

    done
    match_iter="$((match_iter+1))"
  done
fi

if [ 0 -eq 1 ]; then
  data=aachen
  data_dir=data/aachen-day-night/
  colmap_dir="$WS_DIR"tools/colmap/build/src/exe/

  method=anubis
  trial=24

  anubis_dir="$WS_DIR"/tools/anubis/res/localization/"$trial"

  #feat_path="$anubis_dir"/features/
  #match_path="$anubis_dir"/matches/

  feat_path="$anubis_dir"/intersection_features/
  match_path="$anubis_dir"/point_matches/

  # input
  #feat_path="$WS_DIR"tools/imb/dream_cpp/res/sp/aachen/features/"$feat_trial"/
  #match_path="$WS_DIR"tools/imb/dream_cpp/res/sp/aachen/match/"$match_trial"/
  ##scene_path="$WS_DIR"datasets/pydata/aachen/meta/scenes/"$scene_trial"/
  # output
  #method=box_sp
  res_path=res/"$data"/"$method"/"$trial"

  rm -rf "$res_path"

  #cp -r "$res_path"_base "$res_path"
  mkdir -p "$res_path"


  #"$colmap_dir"/colmap matches_importer \
    #  --database_path "$res_path"/database.db \
    #  --match_list_path "$data_dir"/image_pairs_to_match.txt \
    #  --SiftMatching.num_threads 1 \
    #  --log_to_stderr 1 \
    #  --log_level 5 \
    #  --match_type pairs 

  python3 aachen_box.py \
    --dataset_path "$data_dir" \
    --colmap_path "$colmap_dir" \
    --method_name "$method" \
    --res_path "$res_path" \
    --feat_path "$feat_path" \
    --match_path "$match_path" \
    --format "$method"
fi


if [ 0 -eq 1 ]; then
  data=aachen
  data_dir=data/aachen-day-night/
  colmap_dir="$WS_DIR"tools/colmap/build/src/exe/

  method=anubis
  anubis_trial=24
  loc_trial=24

  anubis_dir="$WS_DIR"/tools/anubis/res/localization/"$anubis_trial"
  feat_path="$anubis_dir"/
  match_path="$anubis_dir"/

  res_path=res/"$data"/"$method"/"$loc_trial"

  rm -rf "$res_path"
  mkdir -p "$res_path"

  python3 aachen_box_lines.py \
    --dataset_path "$data_dir" \
    --colmap_path "$colmap_dir" \
    --method_name "$method" \
    --res_path "$res_path" \
    --feat_path "$feat_path" \
    --match_path "$match_path" \
    --format "$method"
fi
