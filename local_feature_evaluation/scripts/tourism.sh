#!/bin/sh

. ./scripts/export_path.sh

scene=reichstag
colmap_ws=res/sift/"$scene"/
img_dir="$TOURISM_DIR"/valid/"$scene"/set_100/
camera_model=PINHOLE
prior_dir="$PYDATA_DIR"facades/meta/sfm/"$scene"/
feat_dir="$WS_DIR"/tf/dream/imb/dream_cpp/res/sift/reichstag/features/
#camera_params=

if [ 0 -eq 1 ]; then
  if [ -d "$colmap_ws" ]; then
    while true; do
      read -p ""$colmap_ws" already exists. Do you want to overwrite it (y/n) ?" yn
      case $yn in
        [Yy]* ) rm -rf "$colmap_ws"; 
          mkdir -p "$colmap_ws"/sparse; 
          mkdir -p "$colmap_ws"/txt; 
          break;;
        [Nn]* ) break;;
        * ) * echo "Please answer yes or no.";;
      esac
    done
  else
    mkdir -p "$colmap_ws"
    mkdir -p "$colmap_ws"/sparse
    mkdir -p "$colmap_ws"/txt
  fi

  # generate an empty reconstruction with the parameters of database images
  cp -r "$prior_dir"/colmap_prior "$colmap_ws"/prior
fi

# feature extraction with known camera params
if [ 0 -eq 1 ]; then
  "$COLMAP_BIN" feature_extractor \
    --database_path "$colmap_ws"/database.db \
    --image_path "$img_dir" \
    --image_list_path "$colmap_ws"/prior/image_list.txt \
    --SiftExtraction.upright 1 \
    --SiftExtraction.max_num_orientations 1 \
    --ImageReader.camera_model "$camera_model" # \
    #--ImageReader.camera_params "$camera_params" 
  if [ $? -ne 0 ]; then
    echo "Error during feature_extractor."
    exit 1
  fi
fi

# imports pre-computed features with known camera params
if [ 0 -eq 1 ]; then
  "$COLMAP_BIN" database_creator \
    --database_path "$colmap_ws"/database.db \

  "$COLMAP_BIN" feature_importer \
    --database_path "$colmap_ws"/database.db \
    --image_path "$img_dir" \
    --import_path "$feat_dir" \
    --image_list_path "$colmap_ws"/prior/image_list.txt \
    --ImageReader.camera_model "$camera_model"
  
  if [ $? -ne 0 ]; then
    echo "Error during feature_importer."
    exit 1
  fi
fi

if [ 0 -eq 1 ]; then
  "$COLMAP_BIN" matches_importer \
    --database_path $colmap_ws/database.db \
    --match_list_path $colmap_ws/prior/image_pairs_to_match_intra.txt \
    --match_type pairs
fi

if [ 0 -eq 1 ]; then
  echo "$img_dir"
  # for when you know the camera pose beforehand
  "$COLMAP_BIN" point_triangulator \
    --database_path $colmap_ws/database.db \
    --image_path "$img_dir" \
    --input_path "$colmap_ws"/prior/ \
    --output_path "$colmap_ws"/sparse/
  if [ $? -ne 0 ]; then
    echo "Error during point_triangulator."
    exit 1
  fi
fi

if [ 1 -eq 1 ]; then
  "$COLMAP_BIN" mapper \
    --database_path "$colmap_ws"/database.db \
    --image_path "$img_dir" \
    --output_path "$colmap_ws"/sparse/
  if [ $? -ne 0 ]; then
    echo "Error during point_triangulator."
    exit 1
  fi
fi



# Convert the model to TXT.
if [ 1 -eq 1 ]; then
  "$COLMAP_BIN" model_converter \
    --input_path "$colmap_ws"sparse \
    --output_path "$colmap_ws"txt \
    --output_type TXT
  if [ "$?" -ne 0 ]; then
    echo "Error in model_converter"
    exit 1
  fi

fi

