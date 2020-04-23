# Reference model
- list of image-cameras pairs with the camera intrinsics
- list of image pose (`c_T_w`)

# CMU

## Define colmap prior for the db images
Split the cmu data into surveys
```
cd ws/datasets/pydata/
# set the slice,cam,survey id params and set the mode to 'split'
./cmu/scripts/spit_surveys.sh 

# set the mode to 'test_split', it checks that you did not forget any images
./cmu/scripts/spit_surveys.sh
```

Generate the files images.txt, points3D.txt, cameras.txt used to initialize the
db images pose in the colmap reconstruction. The output is in
`pydata/cmu/surveys/`. This also generates a list of db image pairs to match.
```
cd ws/datasets/pydata/
# set the mode to 'colmap_init' and set the slice,cam,survey id params
./cmu/scripts/colmap_prior.sh 
```

## Generate the list of inter-survey images to match

### Ground-truth
For debug purposes, generate ground-truth pairs to match based on their poses
(assuming the poses are available).
```
cd ws/datasets/pydata/
# set the mode to 'match_inter' and set the slice,cam,survey id params
./cmu/scripts/colmap_prior.sh 
```

### SG-VLAD
Generate local features for all slices to disk
```
cd ws/tf/wasabi2/
# set the slice, cam, survey
./scripts/extract_features_old_ok.sh
```

Retrieve the nearest db image for each query image. This writes the retrieval
order to file in `res/<cmu_park/cmu_urban>/retrieval`: there is one line per
query image ( in the order of the query survey). Each line is the list of db
image ordered by the similarity with the query image. 
```
./scripts/wasabi2_manual.sh # set the slice, cam, survey
```

Generate the list of query-db image to pair. The results are written in the
`colmap_prior` directory under `image_pairs_inter_sgvlad.txt`
```
./scripts/export_img_pairs.sh # set the slice, cam, survey
```

## Generate the local features to match
Useful if you do not want to use the default sift colmap (which is very good).

### SIFT
Generate local features to file
```
cd ws/tools/features/sift_cv
./examples/cmu
```


Generate local features matches to file (to import through the colmap cpp
interface). The matches are written in the following format (Don't forget the
line break between the matches of two image pairs)
```
image_name1 image_name2
featureId1 featureId2
featureId1 featureId2
featureId1 featureId2
featureId1 featureId2

image_name1 image_name3
featureId1 featureId3
featureId1 featureId3
featureId1 featureId3
featureId1 featureId3
```

Run the following script to get the matches
```
cd ws/tools/features/sift_cv
./examples/cmu_match_features
```

### ELF
The local features are written to `res/cmu/elf/<trial>` in the form
`sliceX/<database/query>/<image_name>.txt` with the following format
```
# pts_num, des_dim
x y orientation scale [des]
```

Run the script
```
cd ws/tf/elf/
# set the script to cmu, set the slice, cam, survey
./scripts/bench_elf.sh 
```

## Reconstruction and Localization (finally)

### Sparse rec with COLMAP sift
Useful when you want to see what colmap can achieve in terms of sparse rec on
your data (it is a good indicator of the difficulty of your data).
```
./scripts/colmap_db.sh
```

### COLMAP sift with manual image-pairs to match
Useful when you want to see what colmap can achieve in terms of localization.
```
./scripts/colmap_loc_sift.sh
```

### My 128 features with manual image-pairs or feature-pairs to match
Use the cpp interface.
```
./scripts/colmap_loc_import.sh
```

### My N features with manual image-pairs or feature-pairs to match
Write the feature and the matches to the database through the python sqlite3 interface.
```
./scripts/colmap_loc_import_py.sh
```

