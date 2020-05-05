#!/bin/sh

slice_id=2
cat retrieval_formated/slice"$slice_id".txt > urban.txt
cat retrieval_formated/slice"$slice_id".txt > all.txt
for slice_id in 3 4 5 6
do
  cat retrieval_formated/slice"$slice_id".txt >> urban.txt
  cat retrieval_formated/slice"$slice_id".txt >> all.txt
done

slice_id=13
cat retrieval_formated/slice"$slice_id".txt > suburb.txt
cat retrieval_formated/slice"$slice_id".txt >> all.txt
for slice_id in 14 15 16 17
do
  cat retrieval_formated/slice"$slice_id".txt >> suburb.txt
  cat retrieval_formated/slice"$slice_id".txt >> all.txt
done


slice_id=18
cat retrieval_formated/slice"$slice_id".txt > park.txt
cat retrieval_formated/slice"$slice_id".txt >> all.txt
for slice_id in 19 20 21
do
  cat retrieval_formated/slice"$slice_id".txt >> park.txt
  cat retrieval_formated/slice"$slice_id".txt >> all.txt
done
