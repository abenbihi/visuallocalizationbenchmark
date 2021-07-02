#!/bin/sh
# Given two methods, output the list of images and estimated poses commonly
# registered by the two methods and the diff.

. ./scripts/export_path.sh

VERSION=1

data=aachen
data_dir=data/aachen-day-night/
colmap_dir=/usr/local/bin/
img_dir="$VLB_DIR"/data/aachen-day-night/images/images_upright/

#cluster_list="$AACHEN_META_DIR"/scenes/query_clusters/
scene_trial=16 # v1.0
scene_trial=17 # v1.1
meta_dir="$AACHEN_META_DIR"/scenes/"$scene_trial"/

#method=adalam
#match_trial=0

method1=horus
match_trial1=58
match_iter1=0
loc_iter1=0

# v1.1
match_trial1=61
match_iter1=0
loc_iter1=1

#method=anubis
#match_trial=58

method2=sift
match_trial2=5
match_iter2=0
loc_iter2=0

method2=sift
match_trial2=12
match_iter2=0
loc_iter2=0

if [ "$VERSION" -eq 0 ]; then
  prefix=Aachen_eval_
else
  prefix=Aachen_v1_1_eval_
fi

res_dir1=res/"$data"/"$method1"/"$match_trial1"/"$match_iter1"/"$loc_iter1"/
eval_fn1="$res_dir1""$prefix""$method1".txt
common_fn1="$res_dir1"Aachen_eval_"$method1"-"$match_trial1"_and_"$method2"-"$match_trial2".txt
diff_fn1="$res_dir1"Aachen_eval_"$method1"-"$match_trial1"_not_"$method2"-"$match_trial2".txt

res_dir2=res/"$data"/"$method2"/"$match_trial2"/"$match_iter2"/"$loc_iter2"/
eval_fn2="$res_dir2""$prefix""$method2".txt
common_fn2="$res_dir2"Aachen_eval_"$method2"-"$match_trial2"_and_"$method1"-"$match_trial1".txt
diff_fn2="$res_dir2"Aachen_eval_"$method2"-"$match_trial2"_not_"$method1"-"$match_trial1".txt

rm -f "$common_fn1"
rm -f "$common_fn2"
rm -f "$diff_fn1"
rm -f "$diff_fn2"

echo "Comparing method1="$method1" and method2="$method2""
echo "Res1 at "$eval_fn1""
echo "Res2 at "$eval_fn2""

echo "\nmethod1 AND method2 at:"
echo ""$common_fn1""
echo ""$common_fn2""
echo "\nmethod1 MINUS method2 at:"
echo ""$diff_fn1""
echo "\nmethod2 MINUS method1 at:"
echo ""$diff_fn2""

while read -r line
do
  query_name="$(echo "$line" | cut -d'/' -f4 | cut -d' ' -f1)"
  echo "line: "$line""
  echo "query_name: "$query_name""

  sub_res1="$(grep "$query_name" "$eval_fn1")"
  echo "$sub_res1"
  is_registered1="$(echo "$sub_res1" | wc -c)"
  #echo "is_registered1: "$is_registered1""

  sub_res2="$(grep "$query_name" "$eval_fn2")"
  #echo "$sub_res2"
  is_registered2="$(echo "$sub_res2" | wc -c)"

  if [ "$is_registered1" -le 1 ] && [ "$is_registered2" -le 1 ]; then
    echo "Not registered: "$query_name""
  elif [ "$is_registered1" -gt 1 ] && [ "$is_registered2" -le 1 ]; then
    echo "Registered in "$method1"-"$match_trial1" but NOT in "$method2"-"$match_trial2""
    echo "$sub_res1" >> "$diff_fn1"
    #exit 1
  elif [ "$is_registered1" -le 1 ] && [ "$is_registered2" -gt 1 ]; then
    echo "Registered in "$method2"-"$match_trial2" but NOT in "$method1"-"$match_trial1""
    echo "$sub_res2" >> "$diff_fn2"
  elif [ "$is_registered1" -gt 1 ] && [ "$is_registered2" -gt 1 ]; then
    echo "Registered in "$method1"-"$match_trial1" AND in "$method2"-"$match_trial2""
    echo "$sub_res1" >> "$common_fn1"
    echo "$sub_res2" >> "$common_fn2"
  fi

done < data/aachen-day-night/queries/night_time_queries_with_intrinsics.txt
