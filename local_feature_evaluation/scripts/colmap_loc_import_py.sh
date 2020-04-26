#!/bin/sh

# colmap run with pre-computed features and local feature matches
# use the cpp interface to import and match specified features
feat_name=elf
pair_name=sgvlad

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
  echo "Error: this script only works with query surveys."
  exit 1
fi

db_dir="$PYDATA_DIR"cmu/meta/surveys/"$slice_id"/"$slice_id"_c"$cam_id"_db/
q_dir="$PYDATA_DIR"cmu/meta/surveys/"$slice_id"/"$slice_id"_c"$cam_id"_"$survey_id"/
img_dir="$CMU_IMG_DIR"
#feat_dir="$WS_DIR"/tf/image-matching-benchmark/dream_cpp/res/sift/cmu/
feat_dir="$WS_DIR"/tf/elf/res/cmu/elf/0/
echo "$feat_dir"

colmap_ws=res/cmu/"$feat_name"/"$slice_id"_c"$cam_id"_"$survey_id"/

if [ 1 -eq 1 ]; then
  if [ -d "$colmap_ws" ]; then
    while true; do
      read -p ""$colmap_ws" already exists. Do you want to overwrite it (y/n) ?" yn
      case $yn in
        [Yy]* ) 
          rm -rf "$colmap_ws"; 
          mkdir -p "$colmap_ws"/sparse
          mkdir -p "$colmap_ws"/final
          mkdir -p "$colmap_ws"/final_txt
          break;;
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

  "$COLMAP_BIN" database_creator \
    --database_path "$colmap_ws"/database.db 

  cp -r "$db_dir"/colmap_prior "$colmap_ws"/prior
  cp "$q_dir"/colmap_prior/image_list.txt "$colmap_ws"/prior/query_fn.txt

  cat "$colmap_ws"/prior/image_pairs_to_match_intra.txt > "$colmap_ws"/image_pairs_to_match.txt
  cat "$q_dir"/colmap_prior/image_pairs_to_match_inter_"$pair_name".txt >> \
    "$colmap_ws"image_pairs_to_match.txt
fi

# TODO: When does the undistortion happen ?
if [ 1 -eq 1 ]; then
  python3 rec.py \
    --colmap_ws "$colmap_ws" \
    --feat_dir "$feat_dir" \
    --slice_id "$slice_id" \
    --cam_id "$cam_id" \
    --survey_id "$survey_id"
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
    --match_type pairs

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
    --output_path "$colmap_ws"/sparse/ 

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
    --Mapper.ba_refine_extra_params 0

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
    --est_pose_fn "$colmap_ws"/test_images.txt
  
  if [ "$?" -ne 0 ]; then
    echo "Error in recover_query_poses"
    exit 1
  fi
fi
