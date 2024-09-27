function precomputeTrainingFeatures

% SPDX-License-Identifier: BSD-3-Clause

%% Setup
if isempty(gcp('nocreate'))
    parpool();
end

dataSetup;

%% Load data
load(trainingDataDir + filesep + "trainingDataRaw", 'trainingData',...
    'trainingLabels', 'trainingTimestamps', 'trainingMetadata',...
    'holdoutPartition','cvPartition')


%% Extract features
trainingFeatures = cell(size(trainingData));

parfor i = 1:numel(trainingData)
    % Compute the average PRF; downstream feature extraction functions
    % need to know the sampling frequency
    fs = averagePRF(trainingTimestamps{i});

    trainingFeatures{i} = extractFeatures(trainingData{i},fs);
end
    

%% Save data 
save(trainingDataDir + filesep + "trainingFeatures.mat", ...
    'trainingFeatures', 'trainingLabels', 'trainingTimestamps', ...
    'trainingMetadata', 'holdoutPartition', 'cvPartition', '-v7.3');
