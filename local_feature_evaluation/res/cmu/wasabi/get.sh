#!/bin/sh
slice_id=4
#rsync -avh assiab@192.93.8.199:/home/assiab/tmp/vlb/cmu/elf/slice"$slice_id".txt .
#rsync -avh assiab@192.93.8.199:/home/assiab/tmp/vlb/cmu/wasabi/urban.txt .

#for slice_id in 13 14 15 16 17 18 19 20 21
for slice_id in 2 #3 4 5 6 
do
  #rsync -avh assiab@192.93.8.199:/home/assiab/tmp/vlb/cmu/wasabi/slice"$slice_id".txt .
  rsync -avh assiab@192.93.8.199:/home/assiab/tmp/vlb/cmu/wasabi/rerank_formated/slice"$slice_id".txt ./rerank_formated/
done
