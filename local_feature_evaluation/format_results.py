import os
import numpy as np
from pyquaternion import Quaternion


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


def main():
    """ """
    ws_dir = "/home/gpu_user/assia/ws/"
    meta_dir = "%s/datasets/pydata/cmu/meta/surveys/"%ws_dir

    slice_id = 5
    # gather poses
    gt_pose_l = []
    est_pose_l = []
    for cam_id in range(2):
        for survey_id in range(11):
            survey_dir = "%s/%d/%d_c%d_%d"%(meta_dir, slice_id, slice_id,
                    cam_id, survey_id)
            #print(survey_dir)
            gt_pose_fn = "%s/pose.txt"%survey_dir
            gt_pose_v = np.loadtxt(gt_pose_fn, dtype=str)
            gt_pose_l.append(gt_pose_v)

            est_pose_fn = "res/cmu/elf/%d_c%d_%d/test_images.txt"%(slice_id, cam_id,
                    survey_id)
            if not os.path.exists(est_pose_fn):
                print("%d %d %d gt est: %d / %d"%(slice_id, cam_id, survey_id, gt_pose_v.shape[0], 0))
                continue
            est_pose_v = np.loadtxt(est_pose_fn, dtype=str).reshape((-1,8))
            est_pose_l.append(est_pose_v)

            print("%d %d %d gt est: %d / %d"%(slice_id, cam_id, survey_id,
                 est_pose_v.shape[0], gt_pose_v.shape[0]))
    
    # gt
    gt_pose_v = np.vstack(gt_pose_l)
    gt_fn_v = gt_pose_v[:,0]
    gt_pose_v = gt_pose_v[:,1:].astype(np.float32) # q_c_w, c
    gt_ok = (gt_pose_v[:,0].astype(np.int) != -1).astype(np.int32)
    gt_num = gt_fn_v.shape[0]
    gt_found = np.zeros(gt_num, np.uint8)
    
    # cam center -> cam translation
    gt_t_l = []
    for l in gt_pose_v:
        qw, qx, qy, qz, cx, cy, cz = [float(ll) for ll in l]
        R = Quaternion([qw, qx, qy, qz]).rotation_matrix
        c = np.array([cx, cy, cz]) # cam center
        t = -np.dot(R, c)
        gt_t_l.append(t)
    gt_t_v =np.array(gt_t_l)
    gt_pose_v[:,4:] = gt_t_v # q_c_w, t_c_w
    
    # save gt poses (for debug)
    fn_v = np.expand_dims(np.array([l.split("/")[-1] for l in gt_fn_v]), 1)
    all_gt_fn = "res/cmu/elf/slice%d_gt.txt"%slice_id
    np.savetxt(all_gt_fn, np.hstack((fn_v, gt_pose_v.astype(str))), fmt="%s")

    # estimated poses
    est_pose_v = np.vstack(est_pose_l)
    est_fn_v = est_pose_v[:,0]
    est_pose_v = est_pose_v[:,1:].astype(np.float32)
    est_num = est_pose_v.shape[0]

    # save estimated pose with expected format
    fn_v = np.expand_dims(np.array([l.split("/")[-1] for l in est_fn_v]), 1)
    print(est_pose_v.shape)
    all_fn = "res/cmu/elf/slice%d.txt"%slice_id
    np.savetxt(all_fn, np.hstack((fn_v, est_pose_v.astype(str))), fmt="%s")

    exit(0) 
    # compute error (debug the same metric as the website)
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



if __name__=="__main__":
    main()
