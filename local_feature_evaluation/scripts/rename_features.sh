#!/bin/sh


img_dir=./data/aachen-day-night/images/images_upright/
feat_dir=./data/aachen-day-night/features/all/

# rename sequences
if [ 1 -eq 1 ]; then
    seq_id=0
    while [ "$seq_id" -le 7 ];
    do
        seq_id="$((seq_id+1))"

        suffix=sequences/nexus4_sequences/sequence_"$seq_id"/
        ls "$feat_dir"/"$suffix" > tmp_list.txt
        while read -r fn
        do
            echo "\nfn: "$fn""
            root_fn="$(echo "$fn" | cut -d'.' -f1)"
            img_fn="$img_dir"/"$suffix"/"$root_fn"
            #echo "$img_fn"

            # check if needs an extension renaming
            ext="$(echo "$fn" | cut -d'.' -f2)"
            #echo "ext: "$ext""
            if [ -f "$img_fn"."$ext" ]; then
                echo "No need to rename feature."
                continue
            fi

            #echo "Neet to rename feature"

            ext1=png
            ext2=jpg
            if [ -f "$img_fn"."$ext1" ]; then
                new_fn="$feat_dir"/"$suffix"/"$root_fn"."$ext1".txt
                #continue
            elif [ -f "$img_fn"."$ext2" ]; then
                new_fn="$feat_dir"/"$suffix"/"$root_fn"."$ext2".txt
            else
                echo "Error: none of the image extension exists:"
                echo "Ext1: "$img_fn"."$ext1""
                echo "Ext2: "$img_fn"."$ext2""
                continue
                #exit 1
            fi

            echo "Use extension "$ext2""
            echo "$img_fn"
            old_fn="$feat_dir"/"$suffix"/"$fn"
            echo ""$old_fn" -> "$new_fn""
            mv "$old_fn" "$new_fn"
            if [ "$?" -ne 0 ]; then
                echo "Error when renaming "$old_fn" -> "$new_fn""
                exit 1
            fi

            #break
        done < tmp_list.txt
        #break
    done
fi


# rename go pro directory
if [ 0 -eq 1 ]; then
    #for suffix in sequences/gopro3_5fps  sequences/gopro3_undistorted
    for suffix in sequences/gopro3_undistorted
    do
        ls "$feat_dir"/"$suffix" > tmp_list.txt
        while read -r fn
        do
            echo "\nfn: "$fn""
            root_fn="$(echo "$fn" | cut -d'.' -f1)"
            img_fn="$img_dir"/"$suffix"/"$root_fn"
            #echo "$img_fn"

            # check if needs an extension renaming
            ext="$(echo "$fn" | cut -d'.' -f2)"
            #echo "ext: "$ext""
            if [ -f "$img_fn"."$ext" ]; then
                echo "No need to rename feature."
                continue
            fi

            #echo "Neet to rename feature"

            ext1=png
            ext2=jpg
            if [ -f "$img_fn"."$ext1" ]; then
                new_fn="$feat_dir"/"$suffix"/"$root_fn"."$ext1".txt
                #continue
            elif [ -f "$img_fn"."$ext2" ]; then
                new_fn="$feat_dir"/"$suffix"/"$root_fn"."$ext2".txt
            else
                echo "Error: none of the image extension exists:"
                echo "Ext1: "$img_fn"."$ext1""
                echo "Ext2: "$img_fn"."$ext2""
                #continue
                exit 1
            fi

            echo "Use extension "$ext2""
            echo "$img_fn"
            old_fn="$feat_dir"/"$suffix"/"$fn"
            echo ""$old_fn" -> "$new_fn""
            mv "$old_fn" "$new_fn"
            if [ "$?" -ne 0 ]; then
                echo "Error when renaming "$old_fn" -> "$new_fn""
                exit 1
            fi

            #break
        done < tmp_list.txt
        #break
    done
fi
