#!/bin/sh

if [ 0 -eq 1 ]; then # extract features from database
  database_path=data/aachen-day-night/aachen.db
  image_path=data/aachen-day-night/images/images_upright/
  output_path=data/aachen-day-night/features/
  min_num_matches=15
  export_images=0
  binary_feature_files=0

  mkdir -p "$output_path"/db
  mkdir -p "$output_path"/query
  mkdir -p "$output_path"/query/day/milestone
  mkdir -p "$output_path"/query/day/nexus4
  mkdir -p "$output_path"/query/day/nexus5x
  mkdir -p "$output_path"/query/night/milestone
  mkdir -p "$output_path"/query/night/nexus5x

  python export_to_visualsfm.py \
    --database_path "$database_path" \
    --image_path "$image_path" \
    --output_path "$output_path" \
    --min_num_matches "$min_num_matches" \
    --export_images "$export_images" \
    --binary_feature_files "$binary_feature_files"
fi

if [ 1 -eq 1 ]; then # rename_features
  while read -r line
  do
    fn=data/aachen-day-night/features/"$line"
    new_fn="$(echo "$fn" | cut -d'.' -f1)".jpg.txt
    echo ""$fn" -> "$new_fn""
    if ! [ -f "$fn" ]; then
      continue
    fi
    mv "$fn" "$new_fn"
    #break
  done < data/aachen-day-night/features/feature_list.txt
fi
