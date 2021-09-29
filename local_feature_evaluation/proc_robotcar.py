import os

import numpy as np
from pyquaternion import Quaternion

WS_DIR = "/home/abenbihi/ws/"
ROBOT_DIR = "%s/datasets/robotcar_seasons/"%WS_DIR
META_DIR = "%s/datasets/pydata/robotcar/meta/"%WS_DIR
SCENE_DIR = "%s/scenes/0/"%META_DIR

def left2rear():
    """Convert the pose evaluation file for the left cameras to one for the
    rear cameras using the provided extrinsics. Let's see if I got better at
    geometry :)."""
    # TODO
    method = "horus"
    match_trial = 10

    #method = "sift"
    #match_trial = 91 

    match_iter = 0
    loc_iter = 3
    #loc_id = 3

    cam_id = "right"
    new_cam_id = "rear"
    
    extrinsics_dir = "%s/extrinsics/"%ROBOT_DIR
    car_T_c_left = np.loadtxt("%s/%s_extrinsics.txt"%(extrinsics_dir, cam_id),
            delimiter=",")
    car_T_c_rear = np.loadtxt("%s/rear_extrinsics.txt"%extrinsics_dir,
            delimiter=",")

    #w_T_c_right = np.loadtxt("%s/right_extrinsics.txt"%extrinsics_dir)

    # Input: pose of the left cameras in colmap format i.e. c_left_P_w
    # Transformation: c_rear_T_c_left
    # Output: pose of the rear cameras in colmap format i.e. c_rear_P_w

    # Prepare transformation
    #c_rear_T_w = np.linalg.inv(w_T_c_rear)
    c_rear_T_car = np.eye(4)
    c_rear_T_car[:3,:3] = np.transpose(car_T_c_rear[:3,:3])
    c_rear_T_car[:3,3] = -np.dot(c_rear_T_car[:3,:3], car_T_c_rear[:3,3])
    #print(c_rear_T_w)
    #print(np.linalg.inv(w_T_c_rear))
    print(np.sum(c_rear_T_car - np.linalg.inv(car_T_c_rear)))
    assert(np.sum(c_rear_T_car - np.linalg.inv(car_T_c_rear)) < 1e-3)
    print(np.dot(c_rear_T_car, car_T_c_rear))

    c_rear_T_c_left = np.dot(c_rear_T_car, car_T_c_left)
    #R = c_rear_T_c_left[:3,:3]
    #print(np.dot(np.transpose(R), R))
    #exit(0)
    #print(np.dot(c_rear_T_w, w_T_c_rear))


    #for loc_id in [44, 26, 11, 41, 19, 29, 9, 34, 33, 14, 45, 27, 28]:
    #    left_poses_path = "res/robotcar/%s/%d/%d/%d/%d_%s_0/Aachen_eval_%s.txt"%(
    #        method, match_trial, match_iter, loc_iter, loc_id, cam_id, method)
    #    if not os.path.exists(left_poses_path):
    #        continue
    if 1==1:
        left_poses_path = "res/robotcar/%s/%d/0/%d/ROBOT_eval_%s_%s.txt"%(
                method, match_trial, loc_iter, method, cam_id)
        left_poses = np.loadtxt(left_poses_path, dtype=str)

        new_poses = []
        for l in left_poses:
            img_fn = l[0]
            print(img_fn)
            qw, qx, qy, qz, tx, ty, tz = [float(ll) for ll in l[1:]] 
            R = Quaternion(np.array([qw, qx, qy, qz])).rotation_matrix # cam -> world
            #print(np.dot(np.transpose(R), R))
            t = np.array([tx, ty, tz]) # cam -> world
            c_left_T_w = np.eye(4)
            c_left_T_w[:3,:3] = R
            c_left_T_w[:3,3] = t

            c_rear_T_w = np.dot(c_rear_T_c_left, c_left_T_w)
            #R = c_rear_T_w[:3,:3]
            #print("\nnp.dot(R, np.transpose(R))")
            #print(np.dot(R, np.transpose(R)))
            #print(c_rear_T_w)
            #print(c_rear_T_w)
            qw, qx, qy, qz = Quaternion(matrix=c_rear_T_w[:3,:3], atol=1e-5)
            tx, ty, tz = c_rear_T_w[:3,3]
            
            new_img_fn = img_fn.replace(cam_id, new_cam_id)
            new_poses.append([
                "%s %.6f %.6f %.6f %.6f %.3f %.3f %.3f"%(
                    new_img_fn, qw, qx, qy, qz, tx, ty, tz)])
            
        #new_dir = "res/robotcar/%s/%d/%d/%d/%d_%s--%s_0/"%(
        #    method, match_trial, match_iter, loc_iter, loc_id, cam_id, new_cam_id)
        #print(new_dir)
        #if not os.path.exists(new_dir):
        #    os.makedirs(new_dir)
        #new_fn = "%s/Aachen_eval_%s.txt"%(new_dir, method)

        #new_fn = "res/robotcar/%s/%d/%d/%d/%d_%s_0/Aachen_eval_%s_%s.txt"%(
        #    method, match_trial, match_iter, loc_iter, loc_id, cam_id, method,
        #    new_cam_id)


        new_fn = "res/robotcar/%s/%d/0/%d/ROBOT_eval_%s_%s_rear.txt"%(
                method, match_trial, loc_iter, method, cam_id)
        print(new_fn)
        np.savetxt(new_fn, np.array(new_poses), fmt="%s")

def convert_with_estimated_extrinsics(loc_id, cam_id1, cam_id2):
    """ """
    # load left/right reference poses
    images_fn = "%s/%d_%s/images.txt"%(SCENE_DIR, loc_id, cam_id1)
    images1 = np.loadtxt(images_fn, dtype=str)
    # remove non-reference images
    fns1 = images1[:,-1]
    mask = np.squeeze(np.array([["reference" in l] for l in fns1]))
    #print(mask)
    #print(mask.shape)
    images1 = images1[mask,:]
    fns1 = images1[:,-1]
    #print(fns1)

    # load rear reference poses
    images_fn = "%s/%d_%s/images.txt"%(SCENE_DIR, loc_id, cam_id2)
    images2 = np.loadtxt(images_fn, dtype=str)
    # remove non-reference images
    fns2 = images2[:,-1]
    mask = np.squeeze(np.array([["reference" in l] for l in fns2]))
    images2 = images2[mask,:]
    fns2 = images2[:,-1]

    # least-square estimate of the extrinsic

    # convert the left/right estimated poses to rear poses

def fuse_left_and_right():
    """ """
    method = "horus"
    match_trial = 10

    #method = "sift"
    #match_trial = 89

    match_iter = 0
    loc_iter = 3

    left_poses_path = "res/robotcar/%s/%d/0/%d/ROBOT_eval_%s_left_rear.txt"%(
            method, match_trial, loc_iter, method)
    left_poses = np.loadtxt(left_poses_path, dtype=str)

    right_poses_path = "res/robotcar/%s/%d/0/%d/ROBOT_eval_%s_right_rear.txt"%(
            method, match_trial, loc_iter, method)
    right_poses = np.loadtxt(right_poses_path, dtype=str)
    print("# left poses: %d"%(left_poses.shape[0]))
    print("# right poses: %d"%(right_poses.shape[0]))

    # find the common images to both
    left_images = left_poses[:, 0]
    right_images = right_poses[:, 0]

    common = set()
    delta_left = []
    delta_right = []

    for l in left_images:
        timestamp = l.split(".")[0].split("/")[1]
        #if "right/%s.jpg"%timestamp in right_images:
        if "rear/%s.jpg"%timestamp in right_images:
            common.add(timestamp)
        else:
            delta_left.append(timestamp)
    print("# common: %d"%(len(common)))
    
    for l in right_images:
        timestamp = l.split(".")[0].split("/")[1]
        #if "left/%s.jpg"%timestamp in left_images:
        if "rear/%s.jpg"%timestamp in left_images:
            common.add(timestamp)
        else:
            delta_right.append(timestamp)
    print("# delta_left: %d"%(len(delta_left)))
    print("# delta_right: %d"%(len(delta_right)))
    #print("# common: %d"%(len(common)))

    # keep common from left
    results = []
    for l in common:
        #idx = np.where(left_images == "left/%s.jpg"%l)[0][0]
        idx = np.where(left_images == "rear/%s.jpg"%l)[0][0]
        #print(idx)
        results.append(left_poses[idx,:])
    
    for l in delta_left:
        #idx = np.where(left_images == "left/%s.jpg"%l)[0][0]
        idx = np.where(left_images == "rear/%s.jpg"%l)[0][0]
        #print(idx)
        results.append(left_poses[idx,:])

    #print(right_images)
    #print("right/%s.jpg"%l)
    #print(left_poses_path)
    #print(right_poses_path)

    for l in delta_right:
        #idx = np.where(right_images == "right/%s.jpg"%l)[0][0]
        idx = np.where(right_images == "rear/%s.jpg"%l)[0][0]
        #print(idx)
        results.append(right_poses[idx,:])

    print("# poses: %d"%(len(results)))

    # add delta left and delta right
    poses_path = "res/robotcar/%s/%d/0/%d/ROBOT_eval_%s_fuse_rear.txt"%(
            method, match_trial, loc_iter, method)
    print(poses_path)
    np.savetxt(poses_path, np.array(results), fmt="%s")


if __name__=="__main__":
    #left2rear()

    loc_id = 3
    cam_id1 = "right"
    cam_id2 = "rear"

    #left2rear()

    fuse_left_and_right()
    #convert_with_estimated_extrinsics(loc_id, cam_id1, cam_id2)
