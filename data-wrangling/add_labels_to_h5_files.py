import h5py
import os
import glob
from scipy.io.matlab import loadmat

for directory in os.listdir():
    # skip this python file
    if directory.endswith(".py"):
        continue

    print(directory + '...')
    rangebin_labels = loadmat(directory + os.sep + 'target_label.mat')['label']

    for h5filename in glob.glob(directory + os.sep + "*.hdf5"):
        print('\t' + h5filename)
        with h5py.File(h5filename, 'r+') as h5file:
            try:
                h5file['parameters']['rangebin_labels/labels'] = rangebin_labels
                h5file['parameters']['rangebin_labels/classes'] = ['nothing', 'drone', 'wall']
            except OSError as e:
                print(e)


