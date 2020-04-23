"""Script to run localisation on Extended-CMU-Seasons."""
import argparse
import os
import types

import cv2
import numpy as np
from pyquaternion import Quaternion

def recover_query_poses(gt_pose_fn, colmap_out_fn, out_fn):
    """
    Writes the estimated query poses to file with the expected format and
    convention.

    Copied from
    https://github.com/tsattler/visuallocalizationbenchmark/tree/master/local_feature_evaluation
    """
    print('Recovering query poses...')
    
    # load query img names
    query_names = np.loadtxt(gt_pose_fn, dtype=str)[:,0]
    
    # load img pose estimation
    with open(colmap_out_fn, "r") as f:
        raw_extrinsics = f.readlines()

    f = open(out_fn, "w")
    # Skip the header.
    for extrinsics in raw_extrinsics[4 :: 2]:
        extrinsics = extrinsics.strip('\n').split(' ')
        image_name = extrinsics[-1]
        if image_name in query_names:
            # Skip the IMAGE_ID ([0]), CAMERA_ID ([-2]), and IMAGE_NAME ([-1]).
            #f.write('%s %s\n' % (image_name.split('/')[-1], ' '.join(extrinsics[1 : -2])))
            f.write('%s %s\n' % (image_name, ' '.join(extrinsics[1 : -2])))
    f.close()


def pose_accuracy(gt_q, gt_t, est_q, est_t):
    """ """
    gt_R = Quaternion(gt_q).rotation_matrix
    gt_c = -np.dot(gt_R.T, gt_t) # cam center
 
    est_R = Quaternion(est_q).rotation_matrix
    est_c = -np.dot(est_R.T, est_t)
   
    error_translation = np.sqrt(np.sum((gt_c - est_c)**2))

    trace = np.trace(np.dot(gt_R.T, est_R))
    cos_abs_alpha = (trace - 1) / 2 # cos(|\alpha|)
    error_rotation = np.arccos(cos_abs_alpha) # radians
    error_rotation = 180 * error_rotation / np.pi # degrees

    return error_translation, error_rotation


def compute_metrics(gt_pose_fn, est_pose_fn):#paths, args):
    """Writes the estimated query poses to file with the expected format and
    convention.
    
    Copied from
    https://github.com/tsattler/visuallocalizationbenchmark/tree/master/local_feature_evaluation
    """
    print('Recovering query poses...')
    # get gt poses
    gt_pose_v = np.loadtxt(gt_pose_fn, dtype=str)
    gt_fn_v = gt_pose_v[:,0]
    gt_pose_v = gt_pose_v[:,1:].astype(np.float32) # q_c_w, c
    gt_ok = (gt_pose_v[:,0].astype(np.int) != -1).astype(np.int32)
    gt_num = gt_fn_v.shape[0]
    gt_found = np.zeros(gt_num, np.uint8)

    gt_t_l = []
    for l in gt_pose_v:
        qw, qx, qy, qz, cx, cy, cz = [float(ll) for ll in l]
        R = Quaternion([qw, qx, qy, qz]).rotation_matrix
        c = np.array([cx, cy, cz]) # cam center
        t = -np.dot(R, c)
        gt_t_l.append(t)
    gt_t_v =np.array(gt_t_l)
    gt_pose_v[:,4:] = gt_t_v # q_c_w, t_c_w

    #print(est_pose_fn)
    est_pose_v = np.loadtxt(est_pose_fn, dtype=str)
    est_fn_v = est_pose_v[:,0]
    est_pose_v = est_pose_v[:,1:].astype(np.float32)
    est_num = est_pose_v.shape[0]
    
    error_t_l = []
    error_r_l = []
    for idx, est_fn in enumerate(est_fn_v):
        gt_idx = np.where(gt_fn_v==est_fn)[0]
        if gt_idx.size == 0:
            continue
        gt_idx = gt_idx[0]
        if gt_ok[gt_idx] == 0:
            continue # we don't have the gt pose
        gt_q = gt_pose_v[gt_idx, 0:4]
        gt_t = gt_pose_v[gt_idx, 4:]
        est_q = est_pose_v[idx, 0:4]
        est_t = est_pose_v[idx, 4:]
        error_t, error_r = pose_accuracy(gt_q, gt_t, est_q, est_t)
        error_t_l.append(error_t)
        error_r_l.append(error_r)

    error_t_v = np.array(error_t_l)
    error_r_v = np.array(error_r_l)
    pose_num_found = error_t_v.shape[0]
    pose_num_all = gt_fn_v.shape[0] 
    
    ratio_found = 1.*est_num / gt_num
    print("Found %.2f%% of the images."%(100*ratio_found))
    thresh_l = [[0.25, 2], [0.5, 5], [5, 10]]
    acc_l = []
    for thresh in thresh_l:
        t_p = error_t_v<thresh[0]
        r_p = error_r_v<thresh[1]
        p = t_p * r_p
        acc_found = np.sum(p)/pose_num_found
        #acc_all = np.sum(p)/pose_num_all
        print("%.2f(m) %d(deg): %.1f%%"%(thresh[0], thresh[1], 100*acc_found))




if __name__ == "__main__":    
    parser = argparse.ArgumentParser()
    parser.add_argument("--gt_pose_fn", type=str)
    parser.add_argument("--colmap_pose_fn", type=str)
    parser.add_argument("--est_pose_fn", type=str)
    args = parser.parse_args()

    recover_query_poses(args.gt_pose_fn, args.colmap_pose_fn, args.est_pose_fn)
    compute_metrics(args.gt_pose_fn, args.est_pose_fn)
