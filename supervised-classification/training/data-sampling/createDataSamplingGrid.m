% SPDX-License-Identifier: BSD-3-Clause
function createDataSamplingGrid

dataSetup;

% Setup undersampling and augmentation ranges
params.UndersamplingRatio = [0 0.25 0.5 0.75];
params.NSynthetic = [0,1,10];

samplingGrid = formatGridSearchParams(params);

save(trainingDataDir + filesep + "samplingGridRowBased", 'samplingGrid');

end
