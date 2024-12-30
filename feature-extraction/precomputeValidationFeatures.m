function precomputeValidationFeatures

% SPDX-License-Identifier: BSD-3-Clause

%% Setup
if isempty(gcp('nocreate'))
    parpool();
end

dataSetup;

%% Load data
load(validationDataDir + filesep + "validationDataRaw", 'validationData', ...
    'validationLabels', 'validationTimestamps', 'validationMetadata', ...
    'holdoutPartition', 'validationPartition')


%% Extract features
validationFeatures = cell(size(validationData));

parfor i = 1:numel(validationData)
    % Compute the average PRF; downstream feature extraction functions
    % need to know the sampling frequency
    fs = averagePRF(validationTimestamps{i});

    validationFeatures{i} = extractFeatures(validationData{i},fs);
end
    

%% Save data 
save(validationDataDir + filesep + "validationFeatures.mat", ...
    'validationFeatures', 'validationLabels', 'validationTimestamps', ...
    'validationMetadata', 'holdoutPartition', 'validationPartition', '-v7.3');