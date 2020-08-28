#!/bin/sh
. ./scripts/export_path.sh

data=aachen
data_dir=data/aachen-day-night/
colmap_dir="$WS_DIR"tools/colmap/build/src/exe/


#method=elf
#feat_path="$WS_DIR"/tf/elf/res/aachen/elf/0/
#loc_trial=0
#res_path=res/"$data"/"$method"/"$loc_trial"/loc/

#feat_path="$WS_DIR"tools/imb/dream_cpp/res/sift/aachen/features/
#method=sift
#loc_trial=0


feat_trial=4
match_trial=1
scene_trial=2

# input
feat_path="$WS_DIR"tools/imb/dream_cpp/res/sp/aachen/features/"$feat_trial"/
match_path="$WS_DIR"tools/imb/dream_cpp/res/sp/aachen/match/"$match_trial"/
scene_path="$WS_DIR"datasets/pydata/aachen/meta/scenes/"$scene_trial"/
# output
method=box_sp
loc_trial=2
res_path=res/"$data"/"$method"/"$loc_trial"/loc/

#cp -r res/"$data"/"$method"/"$trial"/loc_ref res/"$data"/"$method"/"$trial"/loc/

rm -rf "$res_path"
mkdir -p "$res_path"

#python3 reconstruction_pipeline.py \
#  --dataset_path "$data_dir" \
#  --colmap_path "$colmap_dir" \
#  --method_name box_sp \
#  --res_path "$res_path" \
#  --feat_path "$feat_path"

python3 aachen_box.py \
  --dataset_path "$data_dir" \
  --colmap_path "$colmap_dir" \
  --method_name box_sp \
  --scene_path "$scene_path" \
  --feat_path "$feat_path" \
  --match_path "$match_path" \
  --match_list data/aachen-day-night/image_pairs_to_match_gt_night_gem_day.txt \
  --res_path "$res_path"

  #--match_list data/aachen-day-night/image_pairs_to_match.txt \ gt night
