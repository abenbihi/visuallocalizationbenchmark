#!/bin/sh

num_threads=8
data=robotcar

# colmap run with pre-computed features and local feature matches
# use the cpp interface to import and match specified features
#feat_name=elf
#pair_name=sgvlad

# one year later
#feat_name=sift
pair_name=densevlad
top_k=20

#method=sift
#match_trial=11 # sift
#match_trial=95 # sp

#method=horus
#match_trial=9

#match_iter=0
#loc_iter=0

. ./scripts/export_path.sh
meta_dir="$PYDATA_DIR""$data"/meta/

if [ "$#" -eq 0 ]; then 
  echo "Arguments: "
  echo "1: slice"
  echo "2: camera id"
  echo "3: survey id"
  echo "4: method"
  echo "5: match_trial"
  echo "6: match_iter"
  echo "7: loc_iter"
  echo "8: use extra matches"
  echo "9: feat_name"

  exit 1
fi

if [ "$#" -ne 9 ]; then 
  echo "Error: bad number of arguments"
  echo "1: slice"
  echo "2: camera id"
  echo "3: survey id"
  echo "4: method"
  echo "5: match_trial"
  echo "6: match_iter"
  echo "7: loc_iter"
  echo "8: use extra matches"
  echo "9: feat_name"
  exit 1
fi

slice_id="$1"
cam_id="$2"
survey_id="$3"
method="$4"
match_trial="$5"
match_iter="$6"
loc_iter="$7"
use_extra_matches="$8"
feat_name="$9"

cluster_name="$slice_id"_"$cam_id"

if [ "$survey_id" -eq -1 ]; then
  echo "Error: this script only works with query surveys."
  exit 1
fi

db_dir="$PYDATA_DIR""$data"/meta/surveys/"$slice_id"/"$slice_id"_"$cam_id"_db/
q_dir="$PYDATA_DIR""$data"/meta/surveys/"$slice_id"/"$slice_id"_"$cam_id"_"$survey_id"/
img_dir="$ROBOT_IMG_DIR"

if [ "$feat_name" = elf ]; then
  feat_dir="$WS_DIR"/tf/elf/res/cmu/elf/0/
elif [ "$feat_name" = sift ]; then
  feat_dir="$ROBOT_FEAT_DIR"
elif [ "$feat_name" = superpoint ]; then
  feat_dir="$ROBOT_FEAT_DIR"superpoint_py_4096/
elif [ "$feat_name" = d2net ]; then
  feat_dir="$ROBOT_FEAT_DIR"d2net_py_-1/
else
  echo "Error: unknown feat "$feat_name""
  exit 1
fi
echo "$feat_dir"

if [ "$method" = sift ]; then  
  horus_match_path="$WS_DIR"/tools/anubis/res/sift/
  #match_path="$horus_match_path"/"$match_trial"/"$cluster_name"/"$match_iter"/point_matches/
elif [ "$method" = horus ]; then  
  horus_match_path="$WS_DIR"/tools/anubis/res/localization_"$data"/
else
  echo "Error: unknown method "$method""
  exit 1
fi
match_path="$horus_match_path"/"$match_trial"/"$cluster_name"/"$match_iter"/point_matches/

if ! [ -d "$feat_dir" ]; then
  echo "Error: feature path does not exists: "$feat_dir""
  exit 1
fi

#if ! [ -d "$match_path" ]; then
#  echo "Error: match path does not exists: "$match_path""
#  exit 1
#fi

colmap_ws=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/"$slice_id"_"$cam_id"_"$survey_id"/

if [ 1 -eq 1 ]; then
  #if [ -d "$colmap_ws" ]; then
  #  while true; do
  #    read -p ""$colmap_ws" already exists. Do you want to overwrite it (y/n) ?" yn
  #    case $yn in
  #      [Yy]* ) 
  #        rm -rf "$colmap_ws"; 
  #        mkdir -p "$colmap_ws"/sparse
  #        mkdir -p "$colmap_ws"/final
  #        mkdir -p "$colmap_ws"/final_txt
  #        break;;
  #      [Nn]* ) break;;
  #      * ) * echo "Please answer yes or no.";;
  #    esac
  #  done
  #else
  #  mkdir -p "$colmap_ws"
  #  mkdir -p "$colmap_ws"/sparse
  #  mkdir -p "$colmap_ws"/final
  #  mkdir -p "$colmap_ws"/final_txt
  #fi

  if [ -d "$colmap_ws" ]; then
    rm -rf "$colmap_ws"
  fi
    mkdir -p "$colmap_ws"
    mkdir -p "$colmap_ws"/sparse
    mkdir -p "$colmap_ws"/final
    mkdir -p "$colmap_ws"/final_txt

  # generate an empty reconstruction with the parameters of database images

  "$COLMAP_BIN" database_creator \
    --database_path "$colmap_ws"/database.db 

  cp -r "$db_dir"/colmap_prior "$colmap_ws"/prior
  cp "$q_dir"/colmap_prior/image_list.txt "$colmap_ws"/prior/query_fn.txt

  cat "$colmap_ws"/prior/image_pairs_to_match_intra.txt > "$colmap_ws"/image_pairs_to_match.txt
  
  if [ "$pair_name" = densevlad ]; then
    cat \
      "$meta_dir"retrieval/"$pair_name"/"$slice_id"/"$slice_id"_"$cam_id"_"$survey_id"/image_pairs_to_match_top_"$top_k".txt \
      >> "$colmap_ws"/image_pairs_to_match.txt
  else
    echo "Error: unknown retrieval method "$pair_name""
    exit 1
  fi

  #cat "$q_dir"/colmap_prior/image_pairs_to_match_inter_"$pair_name".txt >> \
  #  "$colmap_ws"image_pairs_to_match.txt
fi

# TODO: When does the undistortion happen ?
if [ 1 -eq 1 ]; then
  #if ! [ -d "$match_path" ]; then
  #  echo "Error: no such directory: "$match_path""
  #  exit 1
  #fi
  
  #sift_trial=11
  if [ "$feat_name" = sift ]; then
    #sift_trial=89
    sift_trial=99
  elif [ "$feat_name" = superpoint ]; then
    sift_trial=95 # debug location
    sift_trial=100
  elif [ "$feat_name" = d2net ]; then
    sift_trial=95 # debug location
    sift_trial=101
  fi
  sift_match_path="$WS_DIR"/tools/anubis/res/sift/"$sift_trial"/"$cluster_name"/0/point_matches/
  echo "sift_match_path: "$sift_match_path""
  if [ "$use_extra_matches" -eq 1 ]; then
    if ! [ -d "$sift_match_path" ]; then
      echo "Error: no such directory: "$sift_match_path""
      exit 1
    fi
  fi

  init_db=0
  if [ "$init_db" -eq 0 ]; then
    if [ "$feat_name" = sift ]; then
      db_path=res/robotcar/db_with_imported_features/"$cluster_name"_0/database.db
      cp -r res/robotcar/db_with_imported_features/"$cluster_name"_0/database.db \
        "$colmap_ws"
    elif [ "$feat_name" = superpoint ]; then
      db_path=res/robotcar/db_with_imported_features_superpoint/"$cluster_name"_0/database.db
      cp -r res/robotcar/db_with_imported_features_superpoint/"$cluster_name"_0/database.db \
        "$colmap_ws"
    elif [ "$feat_name" = d2net ]; then
      db_path=res/robotcar/db_with_imported_features_d2net/"$cluster_name"_0/database.db
      cp -r res/robotcar/db_with_imported_features_d2net/"$cluster_name"_0/database.db \
        "$colmap_ws"
    else
      echo "Error when importing initialized db"
      exit 1
    fi

    if ! [ -f "$db_path" ]; then
      echo "Error: init_db does not exist at "$db_path""
      exit 1
    fi

    if [ "$?" -ne 0 ]; then
      echo "Error when copying database to "$colmap_ws""
      exit 1
    fi
  fi

  python3 rec_robotcar.py \
    --colmap_ws "$colmap_ws" \
    --feat_dir "$feat_dir" \
    --match_path "$match_path" \
    --match_path2 "$sift_match_path" \
    --use_extra_matches "$use_extra_matches" \
    --slice_id "$slice_id" \
    --cam_id "$cam_id" \
    --survey_id "$survey_id" \
    --num_threads "$num_threads" \
    --format "$method" \
    --init_db "$init_db"
 
  if [ "$?" -ne 0 ]; then
    echo "Error in matches insertion"
    exit 1
  fi
fi


# specify img to match
if [ 1 -eq 1 ]; then
  "$COLMAP_BIN" matches_importer \
    --database_path "$colmap_ws"/database.db \
    --match_list_path "$colmap_ws"/image_pairs_to_match.txt \
    --match_type pairs \
    --SiftMatching.num_threads "$num_threads"

  if [ "$?" -ne 0 ]; then
    echo "Error in matches_importer"
    exit 1
  fi
fi

# triangulate the database observations in the 3D model at fixed intrinsics
if [ 1 -eq 1 ]; then
  #echo "img_dir: "$img_dir""
  "$COLMAP_BIN" point_triangulator \
    --database_path "$colmap_ws"/database.db \
    --image_path "$img_dir" \
    --input_path "$colmap_ws"/prior/ \
    --output_path "$colmap_ws"/sparse/ \
    --Mapper.num_threads "$num_threads"

  if [ "$?" -ne 0 ]; then
    echo "Error in point_triangulator"
    exit 1
  fi
fi

# Register the query images.
if [ 1 -eq 1 ]; then
  "$COLMAP_BIN" image_registrator \
    --database_path "$colmap_ws"/database.db \
    --input_path "$colmap_ws"/sparse/ \
    --output_path "$colmap_ws"/final/ \
    --Mapper.ba_refine_focal_length 0 \
    --Mapper.ba_refine_principal_point 0 \
    --Mapper.ba_refine_extra_params 0 \
    --Mapper.num_threads "$num_threads"

  if [ "$?" -ne 0 ]; then
    echo "Error in iamge_registrator"
    exit 1
  fi
fi

# Convert the model to TXT.
if [ 1 -eq 1 ]; then
  "$COLMAP_BIN" model_converter \
    --input_path "$colmap_ws"final \
    --output_path "$colmap_ws"final_txt \
    --output_type TXT
  if [ "$?" -ne 0 ]; then
    echo "Error in model_converter"
    exit 1
  fi
fi


if [ 1 -eq 1 ]; then
  echo "Write estimated query pose to file."
  python3 recover_query_poses.py \
    --gt_pose_fn "$q_dir"/pose.txt \
    --colmap_pose "$colmap_ws"final_txt/images.txt \
    --est_pose_fn "$colmap_ws"/Aachen_eval_"$method"_fullname.txt
  
  if [ "$?" -ne 0 ]; then
    echo "Error in recover_query_poses"
    exit 1
  fi

  # format the evaluation file (remove condition)
  #rm "$colmap_ws"/Aachen_eval_"$method".txt
  num_registered_queries="$(wc -l "$colmap_ws"/Aachen_eval_"$method"_fullname.txt | cut -d' ' -f1)"
  if [ "$num_registered_queries" -eq 0 ]; then
    touch "$colmap_ws"/Aachen_eval_"$method".txt
  else
    while read -r line
    do
      fn="$(echo "$line" | cut -d'/' -f2-)"
      echo "$fn" >> "$colmap_ws"/Aachen_eval_"$method".txt
    done < "$colmap_ws"/Aachen_eval_"$method"_fullname.txt
  fi
fi
