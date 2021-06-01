import argparse

import numpy as np

import os

import shutil

import subprocess

import sqlite3

import types

from tqdm import tqdm

from camera import Camera

from utils import quaternion_to_rotation_matrix, camera_center_to_translation

import sys
IS_PYTHON3 = sys.version_info[0] >= 3

DEBUG = (1==1)

def array_to_blob(array):
    if IS_PYTHON3:
        return array.tostring()
    else:
        return np.getbuffer(array)

def recover_database_images_and_ids(paths, args):
    # Connect to the database.
    connection = sqlite3.connect(paths.database_path)
    print(paths.database_path)
    cursor = connection.cursor()

    # Recover database images and ids.
    images = {}
    cameras = {}
    cursor.execute("SELECT name, image_id, camera_id FROM images;")
    for row in cursor:
        images[row[0]] = row[1]
        cameras[row[0]] = row[2]
        #print(row[0])
    # Close the connection to the database.
    cursor.close()
    connection.close()

    return images, cameras


def preprocess_reference_model(paths, args):
    print('Preprocessing the reference model...')
    
    # Recover intrinsics.
    with open(os.path.join(paths.reference_model_path, 'database_intrinsics.txt')) as f:
        raw_intrinsics = f.readlines()
    
    camera_parameters = {}

    for intrinsics in raw_intrinsics:
        intrinsics = intrinsics.strip('\n').split(' ')
        
        image_name = intrinsics[0]
        
        camera_model = intrinsics[1]

        intrinsics = [float(param) for param in intrinsics[2 :]]

        camera = Camera()
        camera.set_intrinsics(camera_model=camera_model, intrinsics=intrinsics)

        camera_parameters[image_name] = camera
    
    # Recover poses.
    with open(os.path.join(paths.reference_model_path, 'aachen_cvpr2018_db.nvm')) as f:
        raw_extrinsics = f.readlines()

    # Skip the header.
    n_cameras = int(raw_extrinsics[2])
    raw_extrinsics = raw_extrinsics[3 : 3 + n_cameras]

    for extrinsics in raw_extrinsics:
        extrinsics = extrinsics.strip('\n').split(' ')

        image_name = extrinsics[0]

        # Skip the focal length. Skip the distortion and terminal 0.
        qw, qx, qy, qz, cx, cy, cz = [float(param) for param in extrinsics[2 : -2]]

        qvec = np.array([qw, qx, qy, qz])
        c = np.array([cx, cy, cz])
        
        # NVM -> COLMAP.
        t = camera_center_to_translation(c, qvec)

        camera_parameters[image_name].set_pose(qvec=qvec, t=t)
    
    return camera_parameters


def generate_empty_reconstruction(images, cameras, camera_parameters, paths, args):
    print('Generating the empty reconstruction...')

    if not os.path.exists(paths.empty_model_path):
        os.mkdir(paths.empty_model_path)
    
    with open(os.path.join(paths.empty_model_path, 'cameras.txt'), 'w') as f:
        for image_name in images:
            image_id = images[image_name]
            camera_id = cameras[image_name]
            try:
                camera = camera_parameters[image_name]
            except:
                continue
            f.write('%d %s %s\n' % (
                camera_id, 
                camera.camera_model, 
                ' '.join(map(str, camera.intrinsics))
            ))

    with open(os.path.join(paths.empty_model_path, 'images.txt'), 'w') as f:
        for image_name in images:
            image_id = images[image_name]
            camera_id = cameras[image_name]
            try:
                camera = camera_parameters[image_name]
            except:
                continue
            f.write('%d %s %s %d %s\n\n' % (
                image_id, 
                ' '.join(map(str, camera.qvec)), 
                ' '.join(map(str, camera.t)), 
                camera_id,
                image_name
            ))

    with open(os.path.join(paths.empty_model_path, 'points3D.txt'), 'w') as f:
        pass


def import_features(images, paths, args):
    # Connect to the database.
    connection = sqlite3.connect(paths.database_path)
    cursor = connection.cursor()

    # Import the features.
    print('Importing features...')
    if DEBUG:
        subset_fn = np.unique(np.loadtxt(paths.match_list_path, dtype=str))
    
    id_shifts = {}
    count, false_count = 0,0
    for image_name, image_id in tqdm(images.items(), total=len(images.items())):
        if DEBUG:
            if image_name not in subset_fn:
                continue
        
        intersection_keypoints = None
        box_keypoints = None

        # import local features
        features_path = "%s/%s.txt"%(paths.feature_path, image_name)
        if not os.path.exists(features_path):
            print("Bad path motherfucker: %s"%features_path)
            exit(1)
        else:
            features = np.loadtxt(features_path, skiprows=1)
            features = features[:,:5]

        # import box corners
        features_path = "%s/%s.txt"%(paths.box_corner_path, image_name)
        if os.path.exists(features_path):
            data = [l.split("\n")[0].split(" ") for l in
                    open(features_path).readlines()]
            if (len(data)) > 1: # i.e. more than the header
                box_keypoints = np.array(data[1:]).astype(np.float32)
        else:
            print("Bad path motherfucker: %s"%features_path)
            exit(1)
        
        # fuse them
        keypoints = None
        if features is None:
            id_shifts[image_name] = 0
            if box_keypoints is None:
                false_count += 1
                keypoints = np.arange(8).reshape((4,2)).astype(np.float32)
            else: 
                keypoints = box_keypoints
        else:
            id_shifts[image_name] = features.shape[0]
            if box_keypoints is None:
                keypoints = features
            else:
                #print(features.shape)
                #print(box_keypoints.shape)
                keypoints = np.vstack((features, box_keypoints))

        assert(keypoints is not None)
        #print(keypoints.shape)
        #exit(1)

        count += 1
 
        n_keypoints = keypoints.shape[0]
        
        # Keep only x, y coordinates.
        keypoints = keypoints[:, : 2]
        # Add placeholder scale, orientation.
        keypoints = np.concatenate([keypoints, np.ones((n_keypoints, 1)), np.zeros((n_keypoints, 1))], axis=1).astype(np.float32)
       
        keypoints_str = keypoints.tostring()
        cursor.execute("INSERT INTO keypoints(image_id, rows, cols, data) VALUES(?, ?, ?, ?);",
                       (image_id, keypoints.shape[0], keypoints.shape[1], keypoints_str))
        connection.commit()
    
    print("# negatives / total: %d/%d"%(false_count, count))
    # Close the connection to the database.
    cursor.close()
    connection.close()

    return id_shifts


def image_ids_to_pair_id(image_id1, image_id2):
    if image_id1 > image_id2:
        return 2147483647 * image_id2 + image_id1
    else:
        return 2147483647 * image_id1 + image_id2


def match_features(images, paths, args, id_shifts):
    # Connect to the database.
    connection = sqlite3.connect(paths.database_path)
    cursor = connection.cursor()

    # Match the features and insert the matches in the database.
    print('Matching...')

    with open(paths.match_list_path, 'r') as f:
        raw_pairs = f.readlines()
    
    image_pair_ids = set()
    count, false_count = 0,0
    for raw_pair in tqdm(raw_pairs, total=len(raw_pairs)):
        image_name1, image_name2 = raw_pair.strip('\n').split(' ')
        if args.format == "adalam":
            # adalam
            fn1 = image_name1
            fn2 = image_name2
        elif args.format == "horus":
            fn1 = image_name1.split(".")[0]
            fn2 = image_name2.split(".")[0]
        elif args.format == "anubis":
            fn1 = image_name1.split(".")[0]
            fn2 = image_name2.split(".")[0]
        else:
            raise ValueError("Unknown match format: %s"%args.format)

        feature_matches = None
        box_matches = None
        
        # read local feature matches
        matches_path = "%s/%s_%s.txt"%(paths.match_path,
                fn1.replace("/","-"), fn2.replace("/","-"))
        if not os.path.exists(matches_path):
            print("No such file: %s"%matches_path)
            exit(0)
        else:
            data = [l.split("\n")[0].split(" ") for l in
                    open(matches_path).readlines()]
            if (len(data)) > 1: # i.e. more than the header
                feature_matches = np.array(data[1:]).astype(np.uint32)

        # read the box corners matches
        matches_path = "%s/%s_%s.txt"%(paths.box_corner_match_path,
                fn1.replace("/","-"), fn2.replace("/","-"))
        if os.path.exists(matches_path):
            data = [l.split("\n")[0].split(" ") for l in
                    open(matches_path).readlines()]
            if (len(data)) > 1: # i.e. more than the header
                box_matches = np.array(data[1:]).astype(np.uint32)

        # fuse them
        matches = None
        shift1 = id_shifts[image_name1] 
        shift2 = id_shifts[image_name2]

        if feature_matches is None:
            if box_matches is None:
                matches = np.array([[0,0],[1,1]]).astype(np.uint32) # random matches
            else:
                box_matches[:,0] = box_matches[:,0] + shift1
                box_matches[:,1] = box_matches[:,1] + shift2
                matches = box_matches
        else: 
            if box_matches is None:
                matches = feature_matches
            else:
                box_matches[:,0] = box_matches[:,0] + shift1
                box_matches[:,1] = box_matches[:,1] + shift2
                matches = np.vstack((feature_matches, box_matches))

        #if matches is None:
        #    print("FUCKING None MACHES")
        #    matches = np.array([[0,0],[1,1]]).astype(np.uint32) # random matches
        #    exit(1)
        #else:
        #    print("WTF")
        #    exit(1)

        count += 1

        image_id1, image_id2 = images[image_name1], images[image_name2]
        image_pair_id = image_ids_to_pair_id(image_id1, image_id2)
        if image_pair_id in image_pair_ids:
            continue
        image_pair_ids.add(image_pair_id)

        if image_id1 > image_id2:
            matches = matches[:, [1, 0]]
        
        matches_str = matches.tostring()
        cursor.execute("INSERT INTO matches(pair_id, rows, cols, data) VALUES(?, ?, ?, ?);",
                       (image_pair_id, matches.shape[0], matches.shape[1], matches_str))
        connection.commit()
    
    print("# negatives / total: %d/%d"%(false_count,count))
    # Close the connection to the database.
    cursor.close()
    connection.close()

def match_features_debug(images, paths, args):
    # Connect to the database.
    connection = sqlite3.connect(paths.database_path)
    cursor = connection.cursor()

    # Match the features and insert the matches in the database.
    print('Matching...')
    
    # list of image pairs to match
    with open(paths.match_list_path, 'r') as f:
        raw_pairs = f.readlines()
    
    # find the matches already processed
    pairs_left = []
    for raw_pair in tqdm(raw_pairs, total=len(raw_pairs)):
        image_name1, image_name2 = raw_pair.strip('\n').split(' ')
        image_id1, image_id2 = images[image_name1], images[image_name2]
        image_pair_id = image_ids_to_pair_id(image_id1, image_id2)

        print(str(image_pair_id))
        cursor.execute("SELECT rows, cols, data FROM matches WHERE pair_id = ?;",
                (str(image_pair_id),))
        data = cursor.fetchall()
        #print(data)
        if (len(data) == 0):
            pairs_left.append(raw_pair)
        #print(cursor)
        #for l in cursor:
        #    print(l)
        
        #break
    
    print("# pairs_left: %d/%d"%(len(pairs_left), len(raw_pairs)))
    
    cursor.close()
    connection.close()

def geometric_verification(paths, args):
    print('Running geometric verification...')

    subprocess.call([os.path.join(args.colmap_path, 'colmap'), 'matches_importer',
                     '--database_path', paths.database_path,
                     '--match_list_path', paths.match_list_path,
                     #'--SiftMatching.num_threads', "1",
                     '--log_to_stderr', '1',
                     '--log_level', '5',
                     '--match_type', 'pairs'])


def reconstruct(paths, args):
    if not os.path.isdir(paths.database_model_path):
        os.mkdir(paths.database_model_path)
    
    # Reconstruct the database model.
    subprocess.call([os.path.join(args.colmap_path, 'colmap'), 'point_triangulator',
                     '--database_path', paths.database_path,
                     '--image_path', paths.image_path,
                     '--input_path', paths.empty_model_path,
                     '--output_path', paths.database_model_path,
                     '--Mapper.ba_refine_focal_length', '0',
                     '--Mapper.ba_refine_principal_point', '0',
                     '--Mapper.ba_refine_extra_params', '0'])


def register_queries(paths, args):
    if not os.path.isdir(paths.final_model_path):
        os.mkdir(paths.final_model_path)
    
    # Register the query images.
    subprocess.call([os.path.join(args.colmap_path, 'colmap'), 'image_registrator',
                     '--database_path', paths.database_path,
                     '--input_path', paths.database_model_path,
                     '--output_path', paths.final_model_path,
                     '--Mapper.ba_refine_focal_length', '0',
                     '--Mapper.ba_refine_principal_point', '0',
                     '--Mapper.ba_refine_extra_params', '0'])


def recover_query_poses(paths, args):
    print('Recovering query poses...')

    if not os.path.isdir(paths.final_txt_model_path):
        os.mkdir(paths.final_txt_model_path)

    # Convert the model to TXT.
    subprocess.call([os.path.join(args.colmap_path, 'colmap'), 'model_converter',
                     '--input_path', paths.final_model_path,
                     '--output_path', paths.final_txt_model_path,
                     '--output_type', 'TXT'])
    
    # Recover query names.
    query_image_list_path = os.path.join(args.dataset_path, 'queries/night_time_queries_with_intrinsics.txt')
    
    with open(query_image_list_path) as f:
        raw_queries = f.readlines()
    
    query_names = set()
    for raw_query in raw_queries:
        raw_query = raw_query.strip('\n').split(' ')
        query_name = raw_query[0]
        query_names.add(query_name)

    with open(os.path.join(paths.final_txt_model_path, 'images.txt')) as f:
        raw_extrinsics = f.readlines()

    f = open(paths.prediction_path, 'w')

    # Skip the header.
    for extrinsics in raw_extrinsics[4 :: 2]:
        extrinsics = extrinsics.strip('\n').split(' ')

        image_name = extrinsics[-1]

        if image_name in query_names:
            # Skip the IMAGE_ID ([0]), CAMERA_ID ([-2]), and IMAGE_NAME ([-1]).
            f.write('%s %s\n' % (image_name.split('/')[-1], ' '.join(extrinsics[1 : -2])))

    f.close()


if __name__ == "__main__":    
    parser = argparse.ArgumentParser()
    parser.add_argument('--dataset_path', required=True, help='Path to the dataset')
    parser.add_argument('--colmap_path', required=True, help='Path to the COLMAP executable folder')
    parser.add_argument('--method_name', required=True, help='Name of the method')
    parser.add_argument('--res_path', type=str, required=True)
    parser.add_argument('--feat_path', type=str, required=True)
    parser.add_argument('--match_path', type=str, required=True)
    parser.add_argument('--box_corner_path', type=str, required=True)
    parser.add_argument('--box_corner_match_path', type=str, required=True)
    parser.add_argument('--format', type=str, required=True)
    parser.add_argument('--num_threads', type=int, required=True)
    parser.add_argument('--match_list', type=str, required=True)
 
    args = parser.parse_args()

    # Create the extra paths.
    paths = types.SimpleNamespace()
    paths.dummy_database_path = os.path.join(args.dataset_path, 'database.db')
    paths.image_path = os.path.join(args.dataset_path, 'images', 'images_upright')
    paths.reference_model_path = os.path.join(args.dataset_path, '3D-models')
    paths.match_list_path = args.match_list
    #paths.match_list_path = os.path.join(args.dataset_path, 'image_pairs_to_match.txt')
    #paths.match_list_path = os.path.join(args.dataset_path, 'image_pairs_to_match_light1.txt')
    paths.box_corner_path = args.box_corner_path
    paths.box_corner_match_path = args.box_corner_match_path
    
    paths.feature_path = args.feat_path
    paths.match_path = args.match_path
    paths.database_path = "%s/database.db"%args.res_path
    paths.empty_model_path = "%s/sparse-%s-empty"%(args.res_path, args.method_name)
    paths.database_model_path = "%s/sparse-%s-database"%(args.res_path, args.method_name)
    paths.final_model_path = "%s/sparse-%s-final"%(args.res_path, args.method_name)
    paths.final_txt_model_path = "%s/sparse-%s-final-txt"%(args.res_path, args.method_name)
    paths.prediction_path = "%s/Aachen_eval_%s.txt"%(args.res_path, args.method_name)


    # Create a copy of the dummy database.
    if os.path.exists(paths.database_path):
        raise FileExistsError('The database file already exists for method %s.' % args.method_name)
    shutil.copyfile(paths.dummy_database_path, paths.database_path)
    
    ## Reconstruction pipeline.
    camera_parameters = preprocess_reference_model(paths, args)
    images, cameras = recover_database_images_and_ids(paths, args)
    
    generate_empty_reconstruction(images, cameras, camera_parameters, paths, args)
    id_shifts = import_features(images, paths, args)
    match_features(images, paths, args, id_shifts)
    geometric_verification(paths, args)
    reconstruct(paths, args)
    register_queries(paths, args)
    recover_query_poses(paths, args)
