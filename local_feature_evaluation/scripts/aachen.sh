#!/bin/sh
. ./scripts/export_path.sh
#exit 1

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

# box trial: 318
loc_trial=3
feat_trial=4
match_trial=1
scene_trial=2

# box trial: 342
loc_trial=4
feat_trial=4
match_trial=3
#scene_trial=4
scene_trial=2

# draft
loc_trial=5

# input
feat_path="$WS_DIR"tools/imb/dream_cpp/res/sp/aachen/features/"$feat_trial"/
match_path="$WS_DIR"tools/imb/dream_cpp/res/sp/aachen/match/"$match_trial"/
scene_path="$WS_DIR"datasets/pydata/aachen/meta/scenes/"$scene_trial"/
# output
method=box_sp
res_path=res/"$data"/"$method"/"$loc_trial"/loc/


# yi 2018 learning


# oanet
method=oanet
feat_path="$WS_DIR"/tools/bm/res/features/0/ # sift (opencv python)
match_path="$WS_DIR"/tf/OANet/res/0/
loc_trial=2
res_path=res/"$data"/"$method"/"$loc_trial"/loc/

# ngransac
method=ngransac
feat_path="$WS_DIR"/tools/bm/res/features/2/ # upright root sift (opencv c++)
match_path="$WS_DIR"/tf/ngransac/res/5/
loc_trial=0
res_path=res/"$data"/"$method"/"$loc_trial"/loc/

# bm
method=bm
feat_path="$WS_DIR"/tools/bm/res/features/upright-root-sift_cpp_8000/aachen/
bm_trial=0 # 25 :( # loc_trial 0
bm_trial=7 # inchAllah
bm_iter=0

match_path="$WS_DIR"/tools/imb/dream_cpp/res/bm/"$bm_trial"/"$bm_iter"/aachen/kp_match/
loc_trial=2
res_path=res/"$data"/"$method"/"$loc_trial"/loc/

#cp -r res/"$data"/"$method"/"$trial"/loc_ref res/"$data"/"$method"/"$trial"/loc/

rm -rf "$res_path"
mkdir -p "$res_path"

#python3 reconstruction_pipeline.py \
python3 reconstruction_pipeline_custom_matches.py \
  --dataset_path "$data_dir" \
  --colmap_path "$colmap_dir" \
  --method_name "$method" \
  --res_path "$res_path" \
  --feat_path "$feat_path" \
  --match_path "$match_path"

#python3 aachen_box.py \
#  --dataset_path "$data_dir" \
#  --colmap_path "$colmap_dir" \
#  --method_name box_sp \
#  --scene_path "$scene_path" \
#  --feat_path "$feat_path" \
#  --match_path "$match_path" \
#  --match_list data/aachen-day-night/image_pairs_to_match_gt_night_gem_day.txt \
#  --res_path "$res_path"

  #--match_list data/aachen-day-night/image_pairs_to_match.txt \ gt night
