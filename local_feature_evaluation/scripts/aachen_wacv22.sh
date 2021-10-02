#!/bin/sh
# rci: salloc -p gpufast --gres=gpu:1 --mincpus=16 -t 240
. ./scripts/export_path.sh


data=aachen
data_dir=data/aachen-day-night/
#colmap_dir="$WS_DIR"tools/colmap/build/src/exe/
colmap_dir=/usr/local/bin/
img_dir="$VLB_DIR"/data/aachen-day-night/images/images_upright/

# TODO
#method=adalam
method=horus
#method=sift
#method=anubis
num_threads=10
VERSION=0
#feat_name=sift
#feat_name=superpoint
feat_name=d2net

cluster_name= #"debug"
#cluster_name=impasse_church

if [ "$cluster_name" = "" ]; then
  if [ "$VERSION" -eq 0 ]; then
    match_list="$data_dir"image_pairs_to_match.txt
    #match_list="$data_dir"image_pairs_to_match_light1.txt
  elif [ "$VERSION" -eq 1 ]; then
    #scene_trial=21
    #meta_dir="$AACHEN_META_DIR"/scenes/"$scene_trial"/debug/ #"$cluster_name"/
    #match_list="$meta_dir"/pairs.txt

    match_list="$data_dir"image_pairs_to_match_v1_1.txt
  else
    echo "Error: unknown version: "$VERSION""
    exit 1
  fi
  #match_list="$data_dir"image_pairs_to_match_light1.txt
else
  if [ "$VERSION" -eq 0 ]; then
    scene_trial=20 # query clusters
  elif [ "$VERSION" -eq 1 ]; then
    scene_trial=21 # query clusters
  else
    echo "Error: unknown version: "$VERSION""
    exit 1
  fi
  meta_dir="$AACHEN_META_DIR"/scenes/"$scene_trial"/"$cluster_name"/
  match_list="$meta_dir"/pairs.txt
fi

echo "method: "$method""
#echo "cluster_name: "$cluster_name""
echo "match_list: "$match_list""
if [ "$feat_name" = sift ]; then
  feat_path="$VLB_DIR"/data/aachen-day-night/features/
elif [ "$feat_name" = superpoint ]; then 
  feat_path="$VLB_DIR"/data/aachen-day-night/features/superpoint_py_4096/
elif [ "$feat_name" = d2net ]; then 
  feat_path="$VLB_DIR"/data/aachen-day-night/features/d2net_py_-1/
else
  echo "Error: unknown features: "$feat_name""
  exit 1
fi

if [ "$method" = sift ]; then
  horus_match_path="$WS_DIR"/tools/anubis/res/"$method"/

  match_trial=98
  match_iter_max=1
  match_iter=0
  #exit 1

  loc_iter_max=1
  echo "feat_path: "$feat_path""

  echo "Match trial: "$match_trial""
  while [ "$match_iter" -lt "$match_iter_max" ];
  do
    echo "Match iter: "$match_iter""
    
    match_path="$horus_match_path"/"$match_trial"/"$match_iter"/"$cluster_name"/point_matches/
    echo "match_path: "$match_path""
    if ! [ -d "$match_path" ]; then
      echo "Error: no matches in this directory: "$match_path""
      exit 1
    fi

    loc_iter=0
    while [ "$loc_iter" -lt "$loc_iter_max" ];
    do
      echo "Match iter / Loc iter: "$match_iter" / "$loc_iter""
      res_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$cluster_name"/"$loc_iter"/
      loc_iter="$((loc_iter+1))"

      rm -rf "$res_path"
      init_db=0
      if [ "$init_db" -eq 0 ]; then
        if [ "$VERSION" -eq 0 ]; then
          if [ "$feat_name" = sift ]; then
            ref_db_path=res/aachen/db_with_imported_features_v10
          elif [ "$feat_name" = superpoint ]; then
            ref_db_path=res/aachen/db_with_imported_features_superpoint_v10
          elif [ "$feat_name" = d2net ]; then
            ref_db_path=res/aachen/db_with_imported_features_d2net_v10
          fi
        elif [ "$VERSION" -eq 1 ]; then
          if [ "$feat_name" = sift ]; then
            ref_db_path=res/aachen/db_with_imported_features_v11
          elif [ "$feat_name" = superpoint ]; then
            ref_db_path=res/aachen/db_with_imported_features_superpoint_v11
          elif [ "$feat_name" = d2net ]; then
            ref_db_path=res/aachen/db_with_imported_features_d2net_v11
          else
            echo "Error: ref_db_path does not exist for this data."
            exit 1
          fi
        else
          echo "Error: incorrect data version "$VERSION""
          exit 1
        fi

        if ! [ "$ref_db_path" ]; then
          echo "Error: ref_db_path: "$ref_db_path" does not exist."
          exit 1
        fi

        mkdir -p "$res_path"
        cp -r "$ref_db_path"/database.db "$res_path"
        if [ "$?" -ne 0 ]; then
          echo "Error: failed to copy reference database from "$ref_db_path"/database.db to "$res_path""
          exit 1
        fi

        cp -r "$ref_db_path"/sparse-rec-empty "$res_path"/sparse-"$method"-empty
        if [ "$?" -ne 0 ]; then
          echo "Error: failed to copy empty reconstruction from "$ref_db_path"/sparse-rec-empty to "$res_path""
          exit 1
        fi
      else
        mkdir -p "$res_path"
      fi

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
          --match_list "$match_list" \
          --version "$VERSION" \
          --use_extra_matches 0 \
          --init_db "$init_db"
      fi
    done
    match_iter="$((match_iter+1))"
  done
fi

if [ "$method" = "horus" ] || [ "$method" = "anubis" ] ; then
  echo "LOCALIZATION for "$method""
  horus_match_path="$WS_DIR"/tools/anubis/res/localization/

  # sift matches
  if [ "$feat_name" = sift ]; then
    if [ "$VERSION" -eq 0 ]; then
      sift_trial=13 # aachen v1.0
    elif [ "$VERSION" -eq 1 ]; then
      sift_trial=12 # aachen v1.1
    fi
  elif [ "$feat_name" = superpoint ]; then 
   if [ "$VERSION" -eq 0 ]; then
     #sift_trial=92 # aachen v1.0 (RT0.8 + MD0.7 + NN)
     sift_trial=93 # aachen v1.0 (NN)
    elif [ "$VERSION" -eq 1 ]; then
      sift_trial=97
    fi
  elif [ "$feat_name" = d2net ]; then 
    if [ "$VERSION" -eq 0 ]; then
      sift_trial=94 # aachen v1.0 (NN)
    elif [ "$VERSION" -eq 1 ]; then
      sift_trial=98
    fi
  fi
  sift_match_path="$WS_DIR"/tools/anubis/res/sift/"$sift_trial"/0/point_matches/

  feat_path="$VLB_DIR"/data/aachen-day-night/features/ #images_upright_subset/
  echo "feat_path: "$feat_path""
  echo "sift_match_path: "$sift_match_path""

  # TODO
  match_trial=192
  match_iter_max=1
  match_iter=0

  loc_iter_max=3

  use_extra_matches=1 # TODO
  if [ "$use_extra_matches" -eq 1 ]; then
    if ! [ -d "$sift_match_path" ]; then
      echo "Error: no such directory: "$sift_match_path""
      exit 1
    fi
  fi

  echo "Match trial: "$match_trial""
  while [ "$match_iter" -lt "$match_iter_max" ];
  do
    echo "Match iter: "$match_iter""
    match_path="$horus_match_path"/"$match_trial"/"$match_iter"/"$cluster_name"/point_matches/
    echo "match_path: "$match_path""
    if ! [ -d "$match_path" ]; then
      echo "Error: no matches in this directory: "$match_path""
      exit 1
    fi

    loc_iter=2 # TODO
    #use_extra_matches=0

    while [ "$loc_iter" -lt "$loc_iter_max" ];
    do
      #use_extra_matches="$loc_iter"
      echo "Match iter / Loc iter: "$match_iter" / "$loc_iter""
      echo "use_extra_matches: "$use_extra_matches""
      res_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$cluster_name"/"$loc_iter"/
      loc_iter="$((loc_iter+1))"

      rm -rf "$res_path"

      # set the initial database
      init_db=0
      if [ "$VERSION" -eq 0 ]; then
        if [ "$feat_name" = sift ]; then
          ref_db_path=res/aachen/db_with_imported_features_v10/
        elif [ "$feat_name" = superpoint ]; then
          ref_db_path=res/aachen/db_with_imported_features_superpoint_v10/
        elif [ "$feat_name" = d2net ]; then
          ref_db_path=res/aachen/db_with_imported_features_d2net_v10/
        fi
      elif [ "$VERSION" -eq 1 ]; then
        if [ "$feat_name" = sift ]; then
          ref_db_path=res/aachen/db_with_imported_features_v11
        elif [ "$feat_name" = superpoint ]; then
          ref_db_path=res/aachen/db_with_imported_features_superpoint_v11/
        elif [ "$feat_name" = d2net ]; then
          ref_db_path=res/aachen/db_with_imported_features_d2net_v11/
        else
          echo "Error: ref_db_path does not exist for this data."
          exit 1
        fi
      else
        echo "Error: incorrect data version "$VERSION""
        exit 1
      fi

      # copy initial database
      if [ "$init_db" -eq 0 ]; then
        if ! [ "$ref_db_path" ]; then
          echo "Error: ref_db_path: "$ref_db_path" does not exist."
          exit 1
        fi

        mkdir -p "$res_path"
        cp -r "$ref_db_path"/database.db "$res_path"
        if [ "$?" -ne 0 ]; then
          echo "Error: failed to copy reference database from "$ref_db_path"/database.db to "$res_path""
          exit 1
        fi

        cp -r "$ref_db_path"/sparse-rec-empty "$res_path"/sparse-"$method"-empty
        if [ "$?" -ne 0 ]; then
          echo "Error: failed to copy empty reconstruction from "$ref_db_path"/sparse-rec-empty to "$res_path""
          exit 1
        fi
      else
        mkdir -p "$res_path"
      fi

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
          --match_list "$match_list" \
          --version "$VERSION" \
          --match_path2 "$sift_match_path" \
          --use_extra_matches "$use_extra_matches" \
          --init_db "$init_db"
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
