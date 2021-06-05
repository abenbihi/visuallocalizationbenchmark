import argparse
import h5py
import numpy as np

import os

import shutil

import subprocess

import sqlite3

import torch

import types

from tqdm import tqdm

from matchers import mutual_nn_matcher

from camera import Camera

from utils import quaternion_to_rotation_matrix, camera_center_to_translation

import sys
IS_PYTHON3 = sys.version_info[0] >= 3

def array_to_blob(array):
    if IS_PYTHON3:
        return array.tostring()
    else:
        return np.getbuffer(array)

def recover_database_images_and_ids(args):
    """Associate image name, img id and camera id.
    
    Returns:
        images: dictionary img_name -> img_id for db AND q img
        cameras: dictionary img_name -> cam_id for db AND q img
    """
    images = {}
    cameras = {}
    
    # WARNING !!! This assumes one camera per model !!!
    camera_fn = "%s/prior/cameras.txt"%args.colmap_ws
    camera_prior = np.loadtxt(camera_fn, dtype=str)
    cam_id = camera_prior[0]
    print("cam_id: %s"%cam_id)

    # load db
    meta_fn = "%s/prior/images.txt"%args.colmap_ws
    meta = np.loadtxt(meta_fn, dtype=str)
    image_id_v = meta[:,0].astype(np.int)
    cam_id_v = meta[:,-2].astype(np.int)
    fn_v = meta[:,-1]
    for i, image_name in enumerate(fn_v):
        #if i%10==0:
        #    print("db: %d/%d %s"%(i, fn_v.shape[0], image_name))
        #print("%d/%d %s image_id: %d\tcam_id: %d"%(
        #    i, fn_v.shape[0], image_name, image_id_v[i], cam_id_v[i]))
        images[image_name] = image_id_v[i]
        cameras[image_name] = cam_id_v[i]
    #print(image_id_v)

    img_id = np.max(image_id_v) + 1
    
    # load q
    meta_fn = "%s/prior/query_fn.txt"%args.colmap_ws
    meta = np.loadtxt(meta_fn, dtype=str)
    for i, image_name in enumerate(meta):
        #if i%1==0:
        #    print("q: %d/%d %s"%(img_id+i, img_id+meta.shape[0], image_name))
        images[image_name] = img_id + i
        cameras[image_name] = cam_id
    
    #for k, v in images.items():
    #    print(k,v)

    return images, cameras


def preprocess_reference_model(args):
    """Get the list of db img, the cameras associated to them (and their
    intrinsics) and the img pose c_T_w."""
    print('Preprocessing the reference model...')

    camera_fn = "%s/prior/cameras.txt"%args.colmap_ws
    camera_prior = np.loadtxt(camera_fn, dtype=str)
    camera_model = camera_prior[1]
    intrinsics = list(camera_prior[2:].astype(np.float32))
    print(camera_model, intrinsics)

    meta_fn = "%s/prior/images.txt"%args.colmap_ws
    #print(meta_fn)
    meta = np.loadtxt("%s/prior/images.txt"%args.colmap_ws, dtype=str)
    image_id_v = meta[:,0]
    pose_v = meta[:,1:8].astype(np.float32)
    cam_id_v = meta[:,-2].astype(np.int)
    fn_v = meta[:,-1]

    camera_parameters = {}
    for i, image_name in enumerate(fn_v):
        #if i%10==0:
        #    print("%d/%d %s"%(i, fn_v.shape[0], image_name))
        qw, qx, qy, qz, tx, ty, tz = pose_v[i,:]
        qvec = np.array([qw, qx, qy, qz])
        t = np.array([tx, ty, tz])

        camera = Camera()
        camera.set_intrinsics(camera_model=camera_model, intrinsics=intrinsics)
        camera.set_pose(qvec=qvec, t=t)
        camera_parameters[image_name] = camera
    
    return camera_parameters


def init_db(paths, images, cameras, args):
    """ """
    camera_fn = "%s/prior/cameras.txt"%args.colmap_ws
    camera_prior = np.loadtxt(camera_fn, dtype=str)
    cam_id = camera_prior[0]
    model = camera_prior[1]
    #cam_id = args.cam_id
    intrinsics = list(camera_prior[4:])

    #model = "OPENCV"
    #if args.cam_id == 0:
    #    intrinsics = [868.993378, 866.063001, 525.942323,
    #            420.042529, -0.399431, 0.188924, 0.000153,
    #            0.000571]
    #else:
    #    intrinsics = [873.382641, 876.489513, 529.324138,
    #            397.272397, -0.397066, 0.181925, 0.000176,
    #            -0.000579]
    intrinsics = np.array(intrinsics).astype(np.float64)
    intrinsics = intrinsics.tostring()
    W = camera_prior[2]
    H = camera_prior[3]

    connection = sqlite3.connect(paths.database_path)
    cursor = connection.cursor()
    
    # insert camera
    modelId = 2
    str_ = "INSERT INTO cameras(camera_id, model, width, height, params, prior_focal_length)"
    str_ += " VALUES(?, ?, ?, ?, ?, ?);"
    cursor.execute(str_, (cam_id, str(modelId), str(W), str(H), intrinsics, "0"))
    connection.commit()

    # insert images
    for image_name, image_id in images.items():
        #print("%s %d"%(image_name, image_id))
        str_ = ("INSERT INTO images(image_id, name, camera_id, prior_qw, prior_qx, "
                "prior_qy, prior_qz, prior_tx, prior_ty, prior_tz) VALUES(?, ?, ?, ?, ?, "
                "?, ?, ?, ?, ?);")
        cursor.execute(str_, (str(image_id), image_name, cam_id,
            "1.0", "0.0", "0.0", "0.0", # q
            "0.0", "0.0", "0.0")) # t
        connection.commit()

    # Close the connection to the database.
    cursor.close()
    connection.close()

def import_features(images, paths, args):
    # Connect to the database.
    connection = sqlite3.connect(paths.database_path)
    cursor = connection.cursor()

    print('Importing features...')
    for image_name, image_id in tqdm(images.items(), total=len(images.items())):
        features_path = "%s/%s.txt"%(paths.feature_path, image_name)
        #print(features_path)
        
        if not os.path.exists(features_path):
            raise ValueError("No such feature file: %s"%features_path)
        #features = np.loadtxt(features_path)
        features = np.loadtxt(features_path, skiprows=1)
        
        keypoints = features[:,:4].astype(np.float32)
        keypoints_str = keypoints.tostring()
        cursor.execute("INSERT INTO keypoints(image_id, rows, cols, data) VALUES(?, ?, ?, ?);",
                       (str(image_id), keypoints.shape[0], keypoints.shape[1], keypoints_str))
        connection.commit()
    
    # Close the connection to the database.
    cursor.close()
    connection.close()


def image_ids_to_pair_id(image_id1, image_id2):
    if image_id1 > image_id2:
        return 2147483647 * image_id2 + image_id1
    else:
        return 2147483647 * image_id1 + image_id2


def match_features(images, paths, args):
    # Connect to the database.
    connection = sqlite3.connect(paths.database_path)
    cursor = connection.cursor()

    cursor.execute("DELETE FROM matches;")
    connection.commit()

    # Match the features and insert the matches in the database.
    print('Matching...')
    
    img_pairs_fn = "%s/image_pairs_to_match.txt"%args.colmap_ws
    with open(img_pairs_fn, 'r') as f:
        raw_pairs = f.readlines()
    
    empty_pairs = []
    
    image_pair_ids = set()
    count, false_count, empty_count = 0,0,0
    for raw_pair in tqdm(raw_pairs, total=len(raw_pairs)):
        image_name1, image_name2 = raw_pair.strip('\n').split(' ')

        fn1 = image_name1.split(".")[0]
        fn2 = image_name2.split(".")[0]
 
        match_fn = "%s/%s_%s.txt"%(paths.match_path, fn1.replace("/","-"),
                fn2.replace("/","-"))
        if not os.path.exists(match_fn):
           print("No such file: %s"%match_fn)
           false_count += 1
           exit(1)
 
        if args.format == "adalam":
            matches = np.loadtxt(match_fn)
        elif (args.format == "horus" or args.format == "anubis" or
                args.format=="sift"):
            matches = np.loadtxt(match_fn, skiprows=1)
        else:
            raise ValueError("Unknwon format: %s"%args.format)
 
        if matches.shape[0] == 0: # bm could not match keypoints
            matches = np.array([[0,0],[1,1]]).astype(np.uint32) # random matches
            empty_pairs.append([image_name1, image_name2])
            empty_count += 1
        else:
            if args.format == "adalam":
                matches = matches[:,:2].astype(np.uint32) # adalam
            matches = matches.reshape((-1,2))
            matches = matches.astype(np.uint32)
        
        ## uncomment if you have issues with estimateUncalibrated. It means that
        ## the indices are your matches are fucked up and do not correspond to
        ## your feature indices. Good luck with that, because this is a very
        ## annoying bug.
        #features_path1 = "%s/%s.txt"%(paths.feature_path, image_name1)
        #features_path2 = "%s/%s.txt"%(paths.feature_path, image_name2)

        #if not os.path.exists(features_path1):
        #    raise ValueError("No such feature file: %s"%features_path1)
        #else:
        #    features1 = np.loadtxt(features_path1, skiprows=1)
        #    keypoints1 = features1[:,:4].astype(np.float32)
        #if not os.path.exists(features_path2):
        #    raise ValueError("No such feature file: %s"%features_path1)
        #else:
        #    features2 = np.loadtxt(features_path2, skiprows=1)
        #    keypoints2 = features2[:,:4].astype(np.float32)

        #match_max1 = np.max(matches[:,0])
        #match_max2 = np.max(matches[:,1])
        #image_id1, image_id2 = images[image_name1], images[image_name2]
        #if (match_max1 >= features1.shape[0]):
        #    print("fail1: %s %s %d %d"%(image_name1, image_name2, image_id1,
        #        image_id2))
        #    print("match_max1 >= # features1: %d >= %s"%(match_max1,
        #        features1.shape[0]))
        #if (match_max2 >= features2.shape[0]):
        #    print("fail2: %s %s %d %d"%(image_name1, image_name2, image_id1,
        #        image_id2))
        #    print("match_max2 >= # features2: %d >= %s"%(match_max2,
        #        features2.shape[0]))
        #assert(match_max1 < features1.shape[0])
        #assert(match_max2 < features2.shape[0])

        count += 1

        ##print(image_name1, image_name2)
        #features_path1 = "%s/%s.txt"%(paths.feature_path, image_name1)
        #features_path2 = "%s/%s.txt"%(paths.feature_path, image_name2)
        #descriptors1 = np.loadtxt(features_path1)[:,4:]
        #descriptors2 = np.loadtxt(features_path2)[:,4:]
        #descriptors1 = torch.from_numpy(descriptors1).to(device)
        #descriptors2 = torch.from_numpy(descriptors2).to(device)      
        #matches = mutual_nn_matcher(descriptors1, descriptors2).astype(np.uint32)

        image_id1, image_id2 = images[image_name1], images[image_name2]
        image_pair_id = image_ids_to_pair_id(image_id1, image_id2)
        if image_pair_id in image_pair_ids:
            continue
        image_pair_ids.add(image_pair_id)

        if image_id1 > image_id2:
            matches = matches[:, [1, 0]]
        
        matches_str = matches.tostring()
        cursor.execute("INSERT INTO matches(pair_id, rows, cols, data) VALUES(?, ?, ?, ?);",
                       (str(image_pair_id), matches.shape[0], matches.shape[1], matches_str))
        connection.commit()
    
    print("# negatives matches / # empty matches / total: %d / %d / %d"%(
        false_count, empty_count, count))
    # Close the connection to the database.
    cursor.close()
    connection.close()


def geometric_verification(paths, args):
    print('Running geometric verification...')

    WS_DIR= "/home/gpu_user/assia/ws/"
    colmap_path = "%s/tools/colmap/build/src/exe/colmap"%(WS_DIR)
    match_list_path = "%s/image_pairs_to_match.txt"%(args.colmap_ws)
    print(match_list_path)
    subprocess.call([colmap_path, 'matches_importer',
                     '--database_path', paths.database_path,
                     '--match_list_path', match_list_path,
                     '--match_type', 'pairs'])


def reconstruct(paths, args):
    if not os.path.isdir(paths.database_model_path):
        os.mkdir(paths.database_model_path)
    print(paths.empty_model_path)
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
    parser.add_argument('--colmap_ws', required=True, type=str)
    parser.add_argument('--feat_dir', type=str)
    parser.add_argument('--match_dir', type=str)
    parser.add_argument('--slice_id', type=int)
    parser.add_argument('--cam_id', type=str)
    parser.add_argument('--survey_id', type=int)
    parser.add_argument('--num_threads', type=int, required=True)
    parser.add_argument('--format', type=str, required=True)
 
    #parser.add_argument('--dataset_path', required=True, help='Path to the dataset')
    #parser.add_argument('--colmap_path', required=True, help='Path to the COLMAP executable folder')
    #parser.add_argument('--method_name', required=True, help='Name of the method')
    #parser.add_argument('--res_path', type=str)
    #parser.add_argument('--feat_path', type=str)
    args = parser.parse_args()

    # Torch settings for the matcher.
    use_cuda = torch.cuda.is_available()
    device = torch.device("cuda:0" if use_cuda else "cpu")

    # Create the extra paths.
    paths = types.SimpleNamespace()
    #paths.dummy_database_path = os.path.join(args.dataset_path, 'database.db')
    #paths.image_path = os.path.join(args.dataset_path, 'images', 'images_upright')
    #paths.reference_model_path = os.path.join(args.dataset_path, '3D-models')
    #paths.match_list_path = os.path.join(args.dataset_path, 'image_pairs_to_match.txt')
    #paths.features_path = os.path.join(args.dataset_path, args.method_name)
    #
    paths.feature_path = args.feat_dir
    paths.match_path = args.match_dir
    paths.database_path = "%s/database.db"%args.colmap_ws
    ##paths.empty_model_path = os.path.join(args.res_path, 'sparse-%s-empty' % args.method_name)
    ##paths.database_model_path = os.path.join(args.res_path, 'sparse-%s-database' % args.method_name)
    ##paths.final_model_path = os.path.join(args.res_path, 'sparse-%s-final' % args.method_name)
    ##paths.final_txt_model_path = os.path.join(args.res_path, 'sparse-%s-final-txt' % args.method_name)
    ##paths.prediction_path = os.path.join(args.res_path, 'Aachen_eval_[%s].txt' % args.method_name)
    ##print(paths.image_path)
    ##
    ### Create a copy of the dummy database.
    ##if os.path.exists(paths.database_path):
    ##    raise FileExistsError('The database file already exists for method %s.' % args.method_name)
    ##shutil.copyfile(paths.dummy_database_path, paths.database_path)
    ##
    
    # create empty database

    # import images and cameras
    camera_parameters = preprocess_reference_model(args)
    images, cameras = recover_database_images_and_ids(args)

    ## init empty database
    init_db(paths, images, cameras, args)

    import_features(images, paths, args)
    match_features(images, paths, args)

    ###geometric_verification(paths, args)
    ###reconstruct(paths, args)
    ###register_queries(paths, args)
    ###recover_query_poses(paths, args)
