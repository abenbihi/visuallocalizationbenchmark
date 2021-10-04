#!/bin/sh

num_threads=4

## colmap run with pre-computed features and local feature matches
## use the cpp interface to import and match specified features
#feat_name=elf
#pair_name=sgvlad

# one year later
feat_name=sift
pair_name=densevlad
top_k=20

method=sift
match_trial=0

loc_iter=1

. ./scripts/export_path.sh
meta_dir="$PYDATA_DIR"symphony/meta/

#camera_model=OPENCV
#camera_params=780.170806,709.378535,317.745657,246.801583,-0.295703,0.157403,-0.001469,-0.000924

db_dir="$meta_dir"/surveys/db/
q_dir="$meta_dir"/surveys/db/ # TODO
img_dir="$WS_DIR"datasets/symphony_seasons/symphony/

if [ "$feat_name" = sift ]; then
  feat_dir="$WS_DIR"/tools/symphony_baselines/res/features/sift_distorted_on_undistorted_img/
else
  echo "Error: unknown feat "$feat_name""
  exit 1
fi
echo "feat_dir: "$feat_dir""

if [ "$method" = sift ]; then  
  match_path="$WS_DIR"/tools/symphony_baselines/res/matches/
else
  echo "Error: unknown method "$method""
  exit 1
fi
match_path="$match_path"/"$match_trial"/
echo "match_path: "$match_path""

if ! [ -d "$feat_dir" ]; then
  echo "Error: feature path does not exists: "$feat_dir""
  exit 1
fi

if ! [ -d "$match_path" ]; then
  echo "Error: match path does not exists: "$match_path""
  exit 1
fi

colmap_ws=res/symphony/"$method"/"$match_trial"/"$loc_iter"/

if [ 0 -eq 1 ]; then
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

  rm -rf "$colmap_ws"; 
  mkdir -p "$colmap_ws"/sparse
  mkdir -p "$colmap_ws"/final
  mkdir -p "$colmap_ws"/final_txt

  # generate an empty reconstruction with the parameters of database images

  "$COLMAP_BIN" database_creator \
    --database_path "$colmap_ws"/database.db 

  cp -r "$db_dir"/colmap_prior "$colmap_ws"/prior
  if [ "$?" -ne 0 ]; then
    echo "Error: could not copy colmap prior for database."
    exit 1
  fi
  #cp "$q_dir"/colmap_prior/image_list.txt "$colmap_ws"/prior/query_fn.txt # TODO

  cat "$colmap_ws"/prior/image_pairs_to_match_intra.txt > "$colmap_ws"/image_pairs_to_match.txt
  
  # TODO
  #if [ "$pair_name" = densevlad ]; then
  #  cat \
  #    "$meta_dir"retrieval/"$pair_name"/"$slice_id"/"$slice_id"_"$cam_id"_"$survey_id"/image_pairs_to_match_top_"$top_k".txt \
  #    >> "$colmap_ws"/image_pairs_to_match.txt
  #else
  #  echo "Error: unknown retrieval method "$pair_name""
  #  exit 1
  #fi
fi

# TODO: When does the undistortion happen ?
if [ 0 -eq 1 ]; then
  if ! [ -d "$match_path" ]; then
    echo "Error: no such directory: "$match_path""
    exit 1
  fi
  python3 rec_symphony.py \
    --colmap_ws "$colmap_ws" \
    --feat_dir "$feat_dir" \
    --match_dir "$match_path" \
    --num_threads "$num_threads" \
    --format "$method"
 
  if [ "$?" -ne 0 ]; then
    echo "Error in matches insertion"
    exit 1
  fi
fi


# specify img to match
if [ 0 -eq 1 ]; then
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
if [ 0 -eq 1 ]; then
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
if [ 0 -eq 1 ]; then
  "$COLMAP_BIN" model_converter \
    --input_path "$colmap_ws"final \
    --output_path "$colmap_ws"final_txt \
    --output_type TXT
  if [ "$?" -ne 0 ]; then
    echo "Error in model_converter"
    exit 1
  fi
fi


if [ 0 -eq 1 ]; then
  echo "Write estimated query pose to file."
  python3 recover_query_poses.py \
    --gt_pose_fn "$q_dir"/pose.txt \
    --colmap_pose "$colmap_ws"final_txt/images.txt \
    --est_pose_fn "$colmap_ws"/Aachen_eval_"$method"_fullname.txt
  
  if [ "$?" -ne 0 ]; then
    echo "Error in recover_query_poses"
    exit 1
  fi

  # format the evaluation file (remove slice<i>/db-query)
  while read -r line
  do
    fn="$(echo "$line" | cut -d'/' -f3)"
    res="$(echo "$line" | cut -d' ' -f3-8)"
    echo "$fn" >> "$colmap_ws"/Aachen_eval_"$method".txt
  done < "$colmap_ws"/Aachen_eval_"$method"_fullname.txt
fi
