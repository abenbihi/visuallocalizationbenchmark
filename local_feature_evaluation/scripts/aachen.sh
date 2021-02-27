#!/bin/sh
. ./scripts/export_path.sh

data=aachen
data_dir=data/aachen-day-night/
colmap_dir="$WS_DIR"tools/colmap/build/src/exe/

method=anubis
trial=3

anubis_dir="$WS_DIR"/tools/anubis/res/localization/"$trial"
feat_path="$anubis_dir"/features/
match_path="$anubis_dir"/matches/

# input
#feat_path="$WS_DIR"tools/imb/dream_cpp/res/sp/aachen/features/"$feat_trial"/
#match_path="$WS_DIR"tools/imb/dream_cpp/res/sp/aachen/match/"$match_trial"/
##scene_path="$WS_DIR"datasets/pydata/aachen/meta/scenes/"$scene_trial"/
# output
#method=box_sp
res_path=res/"$data"/"$method"/"$trial"

rm -rf "$res_path"
mkdir -p "$res_path"

python3 aachen_box.py \
  --dataset_path "$data_dir" \
  --colmap_path "$colmap_dir" \
  --method_name "$method" \
  --res_path "$res_path" \
  --feat_path "$feat_path" \
  --match_path "$match_path" \
  --format "$method"
