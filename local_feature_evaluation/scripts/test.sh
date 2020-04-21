#!/bin/sh
MACHINE=1
if [ "$MACHINE" -eq 0 ]; then
  WS_DIR=/home/abenbihi/ws/
elif [ "$MACHINE" -eq 1 ]; then
  WS_DIR=/home/gpu_user/assia/ws/
else
  echo "Error: wrong MACHINE macro."
  exit 1
fi

data=aachen
data_dir=data/aachen-day-night/
colmap_dir="$WS_DIR"tools/colmap/build/src/exe/

method=toto
trial=0

feat_path=res/"$data"/"$method"/"$trial"/feat/
res_path=res/"$data"/"$method"/"$trial"/loc/
rm -rf "$res_path"
mkdir -p "$res_path"

python3 reconstruction_pipeline.py \
  --dataset_path "$data_dir" \
  --colmap_path "$colmap_dir" \
  --method_name toto \
  --res_path "$res_path" \
  --feat_path "$feat_path"

