#!/bin/sh
# TODO: specify your path here

MACHINE=0
if [ "$MACHINE" -eq 0 ]; then
  WS_DIR=/home/abenbihi/ws/
  COLMAP_BIN="$WS_DIR"tools/colmap/build/src/exe/colmap
elif [ "$MACHINE" -eq 1 ]; then
  WS_DIR=/home/gpu_user/assia/ws/
elif [ "$MACHINE" -eq 6 ]; then
  WS_DIR=/mnt/ssd/temporary/benbiass/ws/
  PYTHON=python3
  COLMAP_BIN=/usr/local/bin/colmap

  # singularity specific
  export PATH=/usr/local/cuda-9.0/bin${PATH:+:${PATH}}
  export LD_LIBRARY_PATH=/usr/local/cuda-9.0/lib64:${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
else
  echo "test_lake.sh: Get your MTF MACHINE correct"
  exit 1
fi

PYDATA_DIR="$WS_DIR"datasets/pydata/

ROBOT_DIR="$WS_DIR"/datasets/robotcar_seasons/
ROBOT_IMG_DIR="$WS_DIR"/datasets/robotcar_seasons/images/
ROBOT_FEAT_DIR="$WS_DIR"/datasets/robotcar_seasons/features/

CMU_DIR="$WS_DIR"/datasets/Extended-CMU-Seasons/
CMU_IMG_DIR="$CMU_DIR"slices/ #bgr/
CMU_FEAT_DIR="$CMU_DIR"features/

#WASABI_DIR="$WS_DIR"/tf/wasabi/
TOURISM_DIR="$WS_DIR"/datasets/tourism/

VLB_DIR="$WS_DIR"/tools/vlb/local_feature_evaluation/

AACHEN_META_DIR="$WS_DIR"datasets/pydata/aachen/
AACHEN_IMG_DIR="$WS_DIR"/tools/vlb/local_feature_evaluation/data/aachen-day-night/images/
AACHEN_FEAT_DIR="$WS_DIR"/tools/vlb/local_feature_evaluation/data/aachen-day-night/features/
AACHEN_META_DIR="$WS_DIR"/datasets/pydata/aachen/meta/
