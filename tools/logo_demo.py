#!/usr/bin/env python

# --------------------------------------------------------
# Fast R-CNN
# Copyright (c) 2015 Microsoft
# Licensed under The MIT License [see LICENSE for details]
# Written by Ross Girshick
# --------------------------------------------------------

"""
Demo script showing detections in sample images.

See README.md for installation instructions before running.
"""

import _init_paths
from fast_rcnn.config import cfg
from fast_rcnn.test import im_detect
from selective_search_ijcv_with_python import selective_search 
from utils.cython_nms import nms
from utils.timer import Timer
import matplotlib.pyplot as plt
import numpy as np
import scipy.io as sio
import caffe, os, sys, cv2
import argparse

# CLASSES = ('__background__',
#            'aeroplane', 'bicycle', 'bird', 'boat',
#            'bottle', 'bus', 'car', 'cat', 'chair',
#            'cow', 'diningtable', 'dog', 'horse',
#            'motorbike', 'person', 'pottedplant',
#            'sheep', 'sofa', 'train', 'tvmonitor')

CLASSES = (
    '__background__',
    'google',
    'apple',
    'adidas',
    'hp',
    'stellaartois',
    'paulaner',
    'guiness',
    'singha',
    'cocacola',
    'dhl',
    'texaco',
    'fosters',
    'fedex',
    'aldi',
    'chimay',
    'shell',
    'becks',
    'tsingtao',
    'ford',
    'carlsberg',
    'bmw',
    'pepsi',
    'esso',
    'heineken',
    'erdinger',
    'corona',
    'milka',
    'ferrari',
    'nvidia',
    'rittersport',
    'ups',
    'starbucks',
)

NETS = {'vgg16': ('VGG16',
                  'vgg16_fast_rcnn_iter_40000.caffemodel'),
        'vgg_cnn_m_1024': ('VGG_CNN_M_1024',
                           'vgg_cnn_m_1024_fast_rcnn_iter_40000.caffemodel'),
        'caffenet': ('CaffeNet',
                     'caffenet_fast_rcnn_iter_40000.caffemodel')}


def vis_detections(im, class_name, dets, thresh=0.5):
    """Draw detected bounding boxes."""
    inds = np.where(dets[:, -1] >= thresh)[0]
    if len(inds) == 0:
        return

    im = im[:, :, (2, 1, 0)]
    fig, ax = plt.subplots(figsize=(12, 12))
    ax.imshow(im, aspect='equal')
    for i in inds:
        bbox = dets[i, :4]
        score = dets[i, -1]

        ax.add_patch(
            plt.Rectangle((bbox[0], bbox[1]),
                          bbox[2] - bbox[0],
                          bbox[3] - bbox[1], fill=False,
                          edgecolor='red', linewidth=3.5)
            )
        ax.text(bbox[0], bbox[1] - 2,
                '{:s} {:.3f}'.format(class_name, score),
                bbox=dict(facecolor='blue', alpha=0.5),
                fontsize=14, color='white')

    ax.set_title(('{} detections with '
                  'p({} | box) >= {:.1f}').format(class_name, class_name,
                                                  thresh),
                  fontsize=14)
    plt.axis('off')
    plt.tight_layout()
    plt.draw()

def logo_demo(net, image_name, classes):
    """Detect object classes in an image using pre-computed object proposals."""
    # Load the demo image
    im_file = os.path.join(cfg.ROOT_DIR, 'data', 'demo', image_name + '.jpg')
    im = cv2.imread(im_file)

    # Load pre-computed Selected Search object proposals
    # box_file = os.path.join(cfg.ROOT_DIR, 'data', 'demo',
    #                         image_name + '_boxes.mat')
    # obj_proposals = sio.loadmat(box_file)['boxes']

    # Calculate Selected Search object proposals
    # obj_proposals = np.array(selective_search.get_windows([im_file]))[0, :, :]

    # Use the entire image as a project proposal
    print im.shape
    obj_proposals = np.array(
        [[0, 0, im.shape[0], im.shape[1]],
        [0, 0, im.shape[0], im.shape[1]]])

    print obj_proposals 
    print obj_proposals.shape
    # delete rows with boxes of 0 area
    # to_delete = []
    # for i in range(obj_proposals.shape[0]):
    #     current = obj_proposals[i, :]
    #     if current[0] == current[2] or current[1] == current[3]:
    #        to_delete.append(i)
    # obj_proposals = np.delete(obj_proposals, to_delete, axis=0)
    print 'after deletion', obj_proposals.shape

    # Detect all object classes and regress object bounds
    timer = Timer()
    timer.tic()
    scores, boxes = im_detect(net, im, obj_proposals)
    timer.toc()
    print ('Detection took {:.3f}s for '
           '{:d} object proposals').format(timer.total_time, boxes.shape[0])

    # Visualize detections for each class
    CONF_THRESH = 0.8
    NMS_THRESH = 0.3
    for cls in classes:
        cls_ind = CLASSES.index(cls)
        cls_boxes = boxes[:, 4*cls_ind:4*(cls_ind + 1)]
        cls_scores = scores[:, cls_ind]
        dets = np.hstack((cls_boxes,
                          cls_scores[:, np.newaxis])).astype(np.float32)
        # keep = nms(dets, NMS_THRESH)
        # dets = dets[keep, :]
        print 'All {} detections with p({} | box) >= {:.1f}'.format(cls, cls,
                                                                    CONF_THRESH)
        vis_detections(im, cls, dets, thresh=CONF_THRESH)

def parse_args():
    """Parse input arguments."""
    parser = argparse.ArgumentParser(description='Train a Fast R-CNN network')
    parser.add_argument('--gpu', dest='gpu_id', help='GPU device id to use [0]',
                        default=0, type=int)
    parser.add_argument('--cpu', dest='cpu_mode',
                        help='Use CPU mode (overrides --gpu)',
                        action='store_true')
    parser.add_argument('--net', dest='demo_net', help='Network to use [vgg16]',
                        choices=NETS.keys(), default='vgg16')
    parser.add_argument('--caffemodel', dest='caffemodel',
                        help='Path to network caffemodel weights',
                        default="")

    args = parser.parse_args()

    return args

if __name__ == '__main__':
    args = parse_args()

    prototxt = os.path.join('models', NETS[args.demo_net][0], 'test.prototxt')
    # caffemodel = os.path.join('data', 'caffenet_fast_rcnn_iter_10000.caffemodel')
    if not args.caffemodel:
        caffemodel = os.path.join('data', 'fast_rcnn_models', NETS[args.demo_net][1])
    else:
	caffemodel = args.caffemodel

    if not os.path.isfile(caffemodel):
        raise IOError(('{:s} not found.\nDid you run ./data/script/'
                       'fetch_fast_rcnn_models.sh?').format(caffemodel))

    if args.cpu_mode:
        caffe.set_mode_cpu()
    else:
        caffe.set_mode_gpu()
    caffe.set_device(args.gpu_id)
    net = caffe.Net(prototxt, caffemodel, caffe.TEST)

    print '\n\nLoaded network {:s}'.format(caffemodel)

    print '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
    print 'Running logo demo:'
    logo_demo(net, '1165690', CLASSES[1:])
    logo_demo(net, '2127104125', CLASSES[1:])
    logo_demo(net, '4509418', CLASSES[1:])
    logo_demo(net, '779301', CLASSES[1:])
    logo_demo(net, '82814', CLASSES[1:])
    logo_demo(net, '88384321', CLASSES[1:])
    logo_demo(net, 'Heineken-Logo', CLASSES[1:])
    logo_demo(net, 'starbucks', CLASSES[1:])
    logo_demo(net, 'starbucks3', CLASSES[1:])
    logo_demo(net, 'corona', CLASSES[1:])

    plt.show()
