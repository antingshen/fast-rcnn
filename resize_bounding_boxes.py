import numpy as np
import os.path
import PIL.Image
import scipy.io

input_file = 'voc_logo_trainval'
mat = scipy.io.loadmat(input_file + '.mat')

for i in range(mat['images'].shape[0]):
    im_file = mat['images'][i][0][0]
    im = PIL.Image.open(os.path.join('VOCdevkitLOGO', 'VOCLOGO', 'JPEGImages', im_file + '.jpg'))
    mat['boxes'][i][0] = np.matrix([1, 1, im.size[0], im.size[1]])
    print im

scipy.io.savemat(input_file + '_full_bbox.mat', mat)
