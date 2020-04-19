#!/bin/sh

# colmap run with pre-computed features and local feature matches
# use the cpp interface to import and match specified features

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

#if [ "$survey_id" -eq -1 ]; then
#  survey_id=db
#fi
colmap_ws=res/cmu/sift/"$slice_id"_c"$cam_id"_"$survey_id"/
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
fi

db_dir="$PYDATA_DIR"pycmu/meta/surveys/"$slice_id"/"$slice_id"_c"$cam_id"_db/
q_dir="$PYDATA_DIR"pycmu/meta/surveys/"$slice_id"/"$slice_id"_c"$cam_id"_"$survey_id"/
#feat_dir=/home/abenbihi/ws/datasets/pydata/pycmu/res/edge_local_des
img_dir="$CMU_IMG_DIR"

# generate an empty reconstruction with the parameters of database images
if [ 1 -eq 1 ]; then
  #if [ -d "$colmap_ws"/colmap_prior ]; then
  #  mkdir -p "$colmap_ws"/colmap_prior
  #fi
  cp -r "$db_dir"/colmap_prior "$colmap_ws"/prior
fi

    
# TODO: When does the undistortion happen ?
if [ 1 -eq 1 ]; then
  cat "$colmap_ws"/prior/image_list.txt > "$colmap_ws"image_list.txt
  cat "$q_dir"/colmap_prior/image_list.txt >> "$colmap_ws"image_list.txt

  "$COLMAP_BIN" feature_extractor \
    --database_path "$colmap_ws"/database.db \
    --image_path "$img_dir" \
    --image_list_path "$colmap_ws"image_list.txt \
    --ImageReader.camera_model "$camera_model" \
    --ImageReader.camera_params "$camera_params" 
  if [ $? -ne 0 ]; then
    echo "Error during feature_extractor."
    exit 1
  fi


fi


# specify img to match
if [ 0 -eq 1 ]; then
  cat "$colmap_ws"/prior/image_pairs_to_match_intra.txt > \
    "$colmap_ws"/image_pairs_to_match.txt

  cat "$q_dir"/image_pairs_to_match_inter.txt >> \
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


# specify features to match
if [ 0 -eq 1 ]; then
  cat "$colmap_ws"colmap_prior/feat_pairs_to_match_intra.txt > \
    "$colmap_ws"/feat_pairs_to_match.txt

  cat "$q_dir"/feat_pairs_to_match_inter.txt >> \
    "$colmap_ws"feat_pairs_to_match.txt

  "$COLMAP_BIN" matches_importer \
    --database_path "$colmap_ws"/database.db \
    --match_list_path "$colmap_ws"/feat_pairs_to_match.txt \
    --match_type raw

  if [ "$?" -ne 0 ]; then
    echo "Error in matches_importer"
    exit 1
  fi
fi


# triangulate the database observations in the 3D model at fixed intrinsics
if [ 0 -eq 1 ]; then
  if ! [ -d "$colmap_ws"/sparse/ ]; then
    mkdir -p "$colmap_ws"/sparse/
  fi

  "$COLMAP_BIN" point_triangulator \
    --database_path "$colmap_ws"/database.db \
    --image_path "$IMG_DIR" \
    --input_path "$colmap_ws"/colmap_prior/ \
    --output_path "$colmap_ws"/sparse/ 
  #\
  #  --Mapper.ba_refine_focal_length 0 \
  #  --Mapper.ba_refine_principal_point 0 \
  #  --Mapper.ba_refine_extra_params 0

  if [ "$?" -ne 0 ]; then
    echo "Error in point_triangulator"
    exit 1
  fi

fi

# Register the query images.
if [ 0 -eq 1 ]; then
  if ! [ -d "$colmap_ws"/final/ ]; then
    mkdir -p "$colmap_ws"/final/
  fi

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
  echo "Convert the model to TXT."
  if ! [ -d "$colmap_ws"/final_txt/ ]; then
    mkdir -p "$colmap_ws"/final_txt
  fi

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
  python3 -m cmu.recover_query_poses \
    --pydata_path "$PYDATA_DIR" \
    --slice_id "$slice_id" \
    --cam_id "$cam_id" \
    --survey_id "$survey_id"
  if [ "$?" -ne 0 ]; then
    echo "Error in recover_query_poses"
    exit 1
  fi

fi


if [ 1 -eq 1 ]; then
  echo "Compute metrics."
  python3 -m cmu.pose_accuracy \
    --pydata_path "$PYDATA_DIR" \
    --slice_id "$slice_id" \
    --cam_id "$cam_id" \
    --survey_id "$survey_id" \
    --feat_name wasabi2
  if [ "$?" -ne 0 ]; then
    echo "Error in recover_query_poses"
    exit 1
  fi
fi
