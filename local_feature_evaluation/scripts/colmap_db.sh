#!/bin/sh
# default colmap run to generate sparse PCL on one survey

. ./scripts/export_path.sh

if [ "$#" -eq 0 ]; then 
  echo "Arguments: "
  echo "1: slice"
  echo "2: camera id"
  echo "3: survey id"
  exit 1
fi

if [ "$#" -ne 3 ]; then 
  echo "Error: bad number of arguments"
  echo "1: slice"
  echo "2: camera id"
  echo "3: survey id"
  exit 1
fi

slice_id="$1"
cam_id="$2"
survey_id="$3"

camera_model=OPENCV
if [ "$cam_id" -eq 0 ]; then 
  camera_params=868.993378,866.063001,525.942323,420.042529,-0.399431,0.188924,0.000153,0.000571
elif [ "$cam_id" -eq 1 ]; then
  camera_params=873.382641,876.489513,529.324138,397.272397,-0.397066,0.181925,0.000176,-0.000579
else
  echo "Error: Wrong cam_id="$cam_id" != {0,1}."
  exit 1
fi

if [ "$survey_id" -eq -1 ]; then
  survey_id=db
fi
project_name="$slice_id"/"$slice_id"_c"$cam_id"_"$survey_id"
#colmap_ws=cmu/res/colmap/"$project_name"/

#db_dir="$PYDATA_DIR"cmu/meta/surveys/"$slice_id"/"$slice_id"_c"$cam_id"_db/
prior_dir="$PYDATA_DIR"cmu/meta/surveys/"$slice_id"/"$slice_id"_c"$cam_id"_"$survey_id"/

img_dir="$CMU_IMG_DIR"


colmap_ws=res/cmu/sift/"$project_name"/
if [ 0 -eq 1 ]; then
  if [ -d "$colmap_ws" ]; then
    while true; do
      read -p ""$colmap_ws" already exists. Do you want to overwrite it (y/n) ?" yn
      case $yn in
        [Yy]* ) rm -rf "$colmap_ws"; 
          mkdir -p "$colmap_ws"/sparse; 
          mkdir -p "$colmap_ws"/dense; 
          break;;
        [Nn]* ) break;;
        * ) * echo "Please answer yes or no.";;
      esac
    done
  else
    mkdir -p "$colmap_ws"/sparse; 
    mkdir -p "$colmap_ws"/dense; 
  fi
fi


# generate an empty reconstruction with the parameters of database images
if [ 0 -eq 1 ]; then
  if [ -d "$colmap_ws"/prior/ ]; then
    mkdir -p "$colmap_ws"/prior/
  fi
  cp -r "$prior_dir"/colmap_prior "$colmap_ws"/prior
fi


# feature extraction with known camera params
if [ 0 -eq 1 ]; then
  "$COLMAP_BIN" feature_extractor \
    --database_path "$colmap_ws"/database.db \
    --image_path "$img_dir" \
    --image_list_path "$colmap_ws"/prior/image_list.txt \
    --ImageReader.camera_model "$camera_model" \
    --ImageReader.camera_params "$camera_params" 
  if [ $? -ne 0 ]; then
    echo "Error during feature_extractor."
    exit 1
  fi
fi

if [ 0 -eq 1 ]; then
  "$COLMAP_BIN" matches_importer \
    --database_path $colmap_ws/database.db \
    --match_list_path $colmap_ws/prior/image_pairs_to_match_intra.txt \
    --match_type pairs
  
  #"$COLMAP_BIN" exhaustive_matcher \
  #  --database_path "$colmap_ws"/database.db

  if [ $? -ne 0 ]; then
    echo "Error during matcher."
    exit 1
  fi
fi

if [ 1 -eq 1 ]; then
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

