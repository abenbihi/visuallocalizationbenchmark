#!/bin/sh

#WS_DIR=/mnt/datagrid/personal/benbiass/ws/

. ./scripts/export_path.sh

singularity shell --nv \
    "$WS_DIR"tools/docker_generic/singularity_eg/draft/cv_torch_colmap.sif
