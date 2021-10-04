#!/bin/sh
# rci: salloc -p gpufast --gres=gpu:1 --mincpus=16 -t 240
. ./scripts/export_path.sh

data=aachen
data_dir=data/aachen-day-night/
colmap_dir=/usr/local/bin/
img_dir="$VLB_DIR"/data/aachen-day-night/images/images_upright/
feat_path="$VLB_DIR"/data/aachen-day-night/features/ #images_upright_subset/

if [ "$#" -ne 6 ]; then
  echo "Error: wrong number of arguments"
  echo "1. version"
  echo "2. method"
  echo "3. match_trial"
  echo "4. match_iter"
  echo "5. loc_iter"
  echo "6. use_extra_matches"
  exit 1
fi

# TODO
version="$1"
method="$2"
match_trial="$3"
match_iter="$4"
loc_iter="$5"
use_extra_matches="$6"

init_db=0
num_threads=8

if [ "$version" -eq 0 ]; then
  match_list="$data_dir"image_pairs_to_match.txt
  #match_list="$data_dir"image_pairs_to_match_light1.txt
elif [ "$version" -eq 1 ]; then
  match_list="$data_dir"image_pairs_to_match_v1_1.txt
else
  echo "Error: unknown version: "$version""
  exit 1
fi

# prepare output directory
res_path=res/"$data"/"$method"/"$match_trial"/"$match_iter"/"$loc_iter"/
#loc_iter="$((loc_iter+1))"

rm -rf "$res_path"
init_db=0
if [ "$version" -eq 0 ]; then
  ref_db_path=res/aachen/db_with_imported_features_v10
elif [ "$version" -eq 1 ]; then
  ref_db_path=res/aachen/db_with_imported_features_v11
else
  echo "Error: incorrect data version "$version""
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

# define feature matches path
if [ "$method" = sift ]; then
  match_path="$WS_DIR"/tools/anubis/res/"$method"/"$match_trial"/"$match_iter"/point_matches/
  sift_match_path=
elif [ "$method" = horus ]; then
  match_path="$WS_DIR"/tools/anubis/res/localization/"$match_trial"/"$match_iter"/point_matches/

  # match for the fusion
  if [ "$version" -eq 0 ]; then
    sift_trial=13 # aachen v1.0
  elif [ "$version" -eq 1 ]; then
    sift_trial=12 # aachen v1.1
  fi
  sift_match_path="$WS_DIR"/tools/anubis/res/sift/"$sift_trial"/0/point_matches/
fi

echo "data_dir: "$data_dir""
echo "method: "$method""
echo "res_path: "$res_path""
echo "feat_path: "$feat_path""
echo "match_path: "$match_path""
echo "use_extra_matches: "$use_extra_matches""
echo "sift_match_path: "$sift_match_path""

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
  --version "$version" \
  --match_path2 "$sift_match_path" \
  --use_extra_matches "$use_extra_matches" \
  --init_db 0
