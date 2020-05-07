#!/bin/sh

ws_dir=/home/gpu_user/assia/ws/
remote_vlb_dir=/home/assiab/tmp/vlb/
method=toto
trial=0

out_dir="$method"/loc/"$trial"
if ! [ -d "$out_dir" ]; then
  mkdir -p "$out_dir"
fi

scp assiab@192.93.8.199:"$remote_vlb_dir"/res/"$out_dir"/Aachen_eval_toto.txt "$out_dir"
mv "$out_dir"/Aachen_eval_toto.txt "$out_dir"/Aachen_eval_\[toto\].txt
