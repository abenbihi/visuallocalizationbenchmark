#!/bin/sh
# TODO: specify your path here

MACHINE=6
if [ "$MACHINE" -eq 0 ]; then
  WS_DIR=/home/abenbihi/ws/
elif [ "$MACHINE" -eq 1 ]; then
  WS_DIR=/home/gpu_user/assia/ws/
elif [ "$MACHINE" -eq 6 ]; then
  WS_DIR=/mnt/ssd/temporary/benbiass/ws/
  PYTHON=python3

  # singularity specific
  export PATH=/usr/local/cuda-9.0/bin${PATH:+:${PATH}}
  export LD_LIBRARY_PATH=/usr/local/cuda-9.0/lib64:${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
else
  echo "test_lake.sh: Get your MTF MACHINE correct"
  exit 1
fi

COLMAP_BIN="$WS_DIR"tools/colmap/build/src/exe/colmap
PYDATA_DIR="$WS_DIR"datasets/pydata/

AACHEN_META_DIR="$WS_DIR"datasets/pydata/aachen/
AACHEN_IMG_DIR="$WS_DIR"/tools/vlb/local_feature_evaluation/data/aachen-day-night/images/images_upright/

CMU_IMG_DIR="$WS_DIR"datasets/Extended-CMU-Seasons/bgr/
#CMU_IMG_DIR=/media/abenbihi/My\ Passport/ws/datasets/Extended-CMU-Seasons/bgr/

CMU_DIR="$WS_DIR"/datasets/Extended-CMU-Seasons/

ROBOT_DIR="$WS_DIR"/datasets/robotcar_seasons/

#WASABI_DIR="$WS_DIR"/tf/wasabi/
TOURISM_DIR="$WS_DIR"/datasets/tourism/
