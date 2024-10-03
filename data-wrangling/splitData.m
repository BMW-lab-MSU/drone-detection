function splitData
% splitData split data into training and testing sets.

% SPDX-License-Identifier: BSD-3-Clause


%% Setup
% Set random number generator properties for reproducibility
rng(0, 'twister');

SEC_PER_NS = 1e-9;

dataSetup;

DATA_FOLDERS = ["stan-fpv-feather", "stan-fpv-feather-prop-only"];

N_IMAGES = 32;

%% Find all the h5 files
h5Filenames = DATA_FOLDERS(1) + filesep + ...
    string({dir(rawDataDir + filesep + DATA_FOLDERS(1) + filesep + "*.hdf5").name});
h5Filenames = [h5Filenames, DATA_FOLDERS(2) + filesep + ...
    string({dir(rawDataDir + filesep + DATA_FOLDERS(2) + filesep + "*.hdf5").name})];

nFiles = numel(h5Filenames);

%% Create the training and testing partition splits
TESTING_PCT = 0.2;
holdoutPartition = cvpartition(nFiles, "Holdout", TESTING_PCT);

N_FOLDS = 5;
cvPartition = cvpartition(holdoutPartition.TrainSize, "KFold", N_FOLDS);

trainingFiles = h5Filenames(training(holdoutPartition));
testingFiles = h5Filenames(test(holdoutPartition));


%% Load the data and put it into training and testing sets
% The original data is in h5 files, but we need the data to be organized as
% cell arrays. Each cell array contains one image. The data cell
% array has associated rangebin label vectors in separate cell array as well
% as associated metadata in separate cell array.
%
% Each h5 file has 32 images in it, which are all collected under the same
% experimental parameters (e.g., tilt angle, propeller speed, etc.). These
% 32 images are all very similar to each other, and so they should be kept
% together to keep the training and testing sets disjoint.


for i = 1:2

    if i == 1
        setSize = holdoutPartition.TrainSize;
        files = trainingFiles;
    else
        setSize = holdoutPartition.TestSize;
        files = testingFiles;
    end

    data = cell(1, setSize * N_IMAGES);
    timestamps = cell(1, setSize * N_IMAGES);
    labels = cell(1, setSize * N_IMAGES);
    meta = cell(1, setSize * N_IMAGES);

    for fileNum = progress(1:setSize)
        h5file = rawDataDir + filesep + files(fileNum);

        [h5data, h5meta] = loadh5(h5file);

        metadata=struct();

        % The labels are the same for each image in the h5 file.
        rangebinLabels = h5data.parameters.rangebin_labels.labels;

        % Remove the labels from the parameters struct so they don't get put
        % in our metadata struct.
        h5data.parameters.rangebin_labels = rmfield(h5data.parameters.rangebin_labels, 'labels');

        % Get and format the metadata. The metadata is the same for all images.

        % All the fields in the parameters struct go in our metadata struct.
        % Field names are converted from snake_case to TitleCase because MATLAB's
        % style for struct fields uses TitleCase, whereas the field names in the h5
        % file are snake_case.
        fieldNames = string(fields(h5data.parameters));

        for fieldName = fieldNames.'
            titleCaseFieldName = snakeCase2TitleCase(fieldName);

            % If the struct field is also a struct, convert the nested
            % struct's field names
            if isstruct(h5data.parameters.(fieldName))
                nestedFields = string(fields(h5data.parameters.(fieldName)));
                for innerField = nestedFields.'
                    titleCaseInnerField = snakeCase2TitleCase(innerField);

                    metadata.(titleCaseFieldName).(titleCaseInnerField) = ...
                        h5data.parameters.(fieldName).(innerField);
                end
            else
                metadata.(titleCaseFieldName) = h5data.parameters.(fieldName);
            end
        end

        metadata.DataUnits = h5meta.data.data.units;
        metadata.DimensionLabels = h5meta.data.data.DIMENSION_LABELS;
        metadata.TimeUnits = h5meta.data.timestamps.units;
        
        % Some of the h5 files have the calibrated distance in them, but some
        % don't because we didn't run the data collection code with distance
        % conversion enabled.
        if isfield(h5data.data, 'distance')
            metadata.Distance = h5data.data.distance;
        end


        for imageNum = 1:N_IMAGES
            cellIdx = (fileNum - 1)*N_IMAGES + imageNum;

            data{cellIdx} = h5data.data.data(imageNum,:,:);
            timestamps{cellIdx} = h5data.data.timestamps(imageNum,:) * SEC_PER_NS;
            labels{cellIdx} = rangebinLabels;
            meta{cellIdx} = metadata;
        end
    end
    


    disp("Saving data...")
    if i == 1
        trainingData = data;
        trainingLabels = labels;
        trainingTimestamps = timestamps;
        trainingMetadata = meta;

        if ~exist(trainingDataDir, "dir")
            mkdir(baseDataDir, "training");
        end
        save(trainingDataDir + filesep + "trainingDataRaw.mat", ...
            'trainingData', 'trainingLabels', 'trainingTimestamps', ...
            'trainingMetadata', 'holdoutPartition', 'cvPartition', '-v7.3');

        clear 'trainingData' 'trainingLabels' 'trainingTimestamps' ...
            'trainingMetadata';
    else
        testingData = data;
        testingLabels = labels;
        testingTimestamps = timestamps;
        testingMetadata = meta;

        if ~exist(testingDataDir, "dir")
            mkdir(baseDataDir, "testing");
        end
        save(testingDataDir + filesep + "testingDataRaw.mat", ...
            'testingData', 'testingLabels', 'testingTimestamps', ...
            'testingMetadata', 'holdoutPartition', '-v7.3');

end

end

