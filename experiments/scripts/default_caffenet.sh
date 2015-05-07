#!/bin/bash

set -x
set -e

export PYTHONUNBUFFERED="True"

LOG="experiments/logs/default_caffenet.txt.`date +'%Y-%m-%d_%H-%M-%S'`"
exec &> >(tee -a "$LOG")
echo Logging output to "$LOG"

time ./tools/train_net.py --gpu 0 \
  --solver models/CaffeNet/solver.prototxt \
  --weights data/imagenet_models/CaffeNet.v2.caffemodel \
  --imdb voc_logo_trainval

time ./tools/test_net.py --gpu 0 \
  --def models/CaffeNet/test.prototxt \
  --net output/default/voc_logo_trainval/caffenet_fast_rcnn_iter_40000.caffemodel \
  --imdb voc_logo_test
