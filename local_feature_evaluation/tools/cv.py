import glob
from joblib import Parallel, delayed
import multiprocessing as mp
import os
from tqdm import tqdm

import cv2
import numpy as np


def get_sift():
    """ """


def get_features(img_fn, max_num_feat, out_dir, new_size=None):
    """ """
    fe = cv2.xfeatures2d.SIFT_create(max_num_feat)
    img = cv2.imread(img_fn, 0)
    old_size = (img.shape[1], img.shape[0])
    if new_size is not None:
        img = cv2.resize(img, new_size, interpolation=cv2.INTER_LINEAR)
        sx2big, sy2big = 1.0*old_size[0]/new_size[0], 1.0*old_size[1]/new_size[1] 
    
    kp, des = fe.detectAndCompute(img, None)
    if new_size is not None:
        pts = np.vstack([[sx2big*kp.pt[0], sy2big*kp.pt[1]] for kp in kp])
    else:
        pts = np.vstack([[kp.pt[0], kp.pt[1]] for kp in kp])
    
    out_fn = "%s/%s"%(out_dir, img_fn.split("/")[-1].split(".")[0])
    out_d = {}
    out_d['descriptors'] = des
    out_d['keypoints'] = pts
    np.save(out_fn, out_d)


def main():
    """Extrcat local features to test my evaluation pipeline."""
    method = "toto"
    trial = 0
    out_dir = "res/%s/feat/%d"%(method, trial)
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    img_dir = "data/images_upright/"
    db_img_l = glob.glob("%s/db/*jpg"%img_dir)
    qd_img_l = glob.glob("%s/query/day/*/*jpg"%img_dir)
    qn_img_l = glob.glob("%s/query/night/*/*jpg"%img_dir)
    img_num = len(db_img_l) + len(qd_img_l) + len(qn_img_l)
    print("#db: %d\t#qd: %d\t#qn: %d"%(len(db_img_l), len(qd_img_l), len(qn_img_l)))
    print("#total: %d"%img_num)
    
    img_fn_l = db_img_l + qd_img_l + qn_img_l
    #img_fn_l = img_fn_l[:10]
    max_num_feat  = 500
    
    norm = 'L2'
    FLANN_INDEX_KDTREE = 0
    index_params = dict(algorithm = FLANN_INDEX_KDTREE, trees = 5)
    search_params = dict(checks=50)
    matcher = cv2.FlannBasedMatcher(index_params,search_params)

    num_cores = 1 #int(len(os.sched_getaffinity(0)) * 0.9)
    #print(img_fn_l[:10])
    Parallel(n_jobs=num_cores)(delayed(get_features)(fn, max_num_feat,
        out_dir) for fn in tqdm(img_fn_l))

    #for i, img_fn in enumerate(img_fn_l):
    #    img = cv2.imread(img_fn, 0)
    #    kp, des = fe.detectAndCompute(img, None)
    #    print(out_fn)
    #    #exit(0)


if __name__=="__main__":
    main()
