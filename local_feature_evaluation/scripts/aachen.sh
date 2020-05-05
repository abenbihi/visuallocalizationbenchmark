#!/bin/sh
. ./scripts/export_path.sh

data=aachen
data_dir=data/aachen-day-night/
colmap_dir="$WS_DIR"tools/colmap/build/src/exe/


feat_path="$WS_DIR"/tf/elf/res/aachen/elf/0/

method=elf
trial=0
res_path=res/"$data"/"$method"/"$trial"/loc/

#cp -r res/"$data"/"$method"/"$trial"/loc_ref res/"$data"/"$method"/"$trial"/loc/
rm -rf "$res_path"
mkdir -p "$res_path"

python3 reconstruction_pipeline.py \
  --dataset_path "$data_dir" \
  --colmap_path "$colmap_dir" \
  --method_name elf_vgg \
  --res_path "$res_path" \
  --feat_path "$feat_path"

