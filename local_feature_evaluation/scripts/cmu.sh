#!/bin/sh

# TODO: make this arguments of the loc script
match_trial=9
match_iter=0
loc_iter=0


for slice_id in 2
do
    for cam_id in 0 #1
    do
        for survey_id in 0 #1 2 3 4 5 6 7 8 9 10
        do
            eval_fn=res/cmu/sift/"$match_trial"/"$match_iter"/"$loc_iter"/"$slice_id"_c"$cam_id"_"$survey_id"/Aachen_eval_sift.txt
            if [ -f "$eval_fn" ]; then
                echo "Evaluation file already exists at "$eval_fn"\n"
                continue
            fi

            ./scripts/colmap_loc_import_py.sh "$slice_id" "$cam_id" "$survey_id"
            if [ "$?" -ne 0 ]; then
                echo "Error when loc on "$slice_id" "$cam_id" "$survey_id""
                exit 1
            fi
            break
        done
    done
done
