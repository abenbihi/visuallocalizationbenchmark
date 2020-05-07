#!/bin/sh
# TODO: specify your path here

MACHINE=0
if [ "$MACHINE" -eq 0 ]; then
  WS_DIR=/home/abenbihi/ws/
elif [ "$MACHINE" -eq 1 ]; then
  WS_DIR=/home/gpu_user/assia/ws/
else
  echo "test_lake.sh: Get your MTF MACHINE correct"
  exit 1
fi

COLMAP_BIN="$WS_DIR"tools/colmap/build/src/exe/colmap
PYDATA_DIR="$WS_DIR"datasets/pydata/


CMU_IMG_DIR="$WS_DIR"datasets/Extended-CMU-Seasons/bgr/
CMU_IMG_DIR=/media/abenbihi/My\ Passport/ws/datasets/Extended-CMU-Seasons/bgr/

#WASABI_DIR="$WS_DIR"/tf/wasabi/
TOURISM_DIR="$WS_DIR"/datasets/tourism/
