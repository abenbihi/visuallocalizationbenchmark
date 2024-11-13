#!/bin/sh

DATA=cambridge
FEATURE=rootsift

SCENE=ShopFacade

prior_dir="$PYDATA_DIR"cambridge/meta/"$SCENE"/
img_dir="$CMU_IMG_DIR"


colmap_ws=res/"$DATA"/"$FEATURE"/"$SCENE"/

if [ 0 -eq 1 ]; then
  if [ -d "$colmap_ws" ]; then
    while true; do
      read -p ""$colmap_ws" already exists. Do you want to overwrite it (y/n) ?" yn
      case $yn in
        [Yy]* ) rm -rf "$colmap_ws"; mkdir -p "$colmap_ws"; break;;
        [Nn]* ) break;;
        * ) * echo "Please answer yes or no.";;
      esac
    done
  else
    mkdir -p "$colmap_ws"
    mkdir -p "$colmap_ws"/sparse
    mkdir -p "$colmap_ws"/final
    mkdir -p "$colmap_ws"/final_txt
  fi

  # generate an empty reconstruction with the parameters of database images
  cp -r "$prior_dir"/colmap_prior "$colmap_ws"/colmap_prior
fi

# Create db

# Feature Extraction
if [ 0 -eq 1 ]; then
  "$COLMAP_BIN" feature_extractor \
    --database_path "$colmap_ws"/database.db \
    --image_path "$img_dir" \
    --image_list_path "$prior_dir"image_list.txt \
    --SiftExtraction.max_num_features 8192 \
    --SiftExtraction.upright 1 \
    --ImageReader.camera_model "$camera_model" \
    --ImageReader.camera_params "$camera_params" 
  if [ $? -ne 0 ]; then
    echo "Error during feature_extractor."
    exit 1
  fi
fi

# Edit the camera model


# Match Features (db/db and db/q)
# specify img to match
if [ 0 -eq 1 ]; then
  cat "$colmap_ws"/prior/image_pairs_to_match_intra.txt > \
    "$colmap_ws"/image_pairs_to_match.txt

  cat "$q_dir"/colmap_prior/image_pairs_to_match_inter.txt >> \
    "$colmap_ws"image_pairs_to_match.txt

  "$COLMAP_BIN" matches_importer \
    --database_path "$colmap_ws"/database.db \
    --match_list_path "$colmap_ws"/image_pairs_to_match.txt \
    --match_type pairs

  if [ "$?" -ne 0 ]; then
    echo "Error in matches_importer"
    exit 1
  fi
fi


# triangulate the database observations in the 3D model at fixed intrinsics
if [ 0 -eq 1 ]; then
  "$COLMAP_BIN" point_triangulator \
    --database_path "$colmap_ws"/database.db \
    --image_path "$img_dir" \
    --input_path "$colmap_ws"/prior/ \
    --output_path "$colmap_ws"/sparse/ 

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
    --Mapper.ba_refine_extra_params 0

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
    --est_pose_fn "$colmap_ws"/test_images.txt
  
  if [ "$?" -ne 0 ]; then
    echo "Error in recover_query_poses"
    exit 1
  fi

fi
