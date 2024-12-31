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

% There are some reflections in the data after the wall which are messing up the
% features for the "nothing" class. That is, some of the "nothing" rows look
% like the corresponding "drone" and "wall" rows. We will truncate the images
% after the wall, since the wall was basically always at the same range bin
% and there is definitely nothing past the wall... The last wall row in the
% labels was 146. TRUNCATE_ROW gives a bit of margin after 146.
TRUNCATE_ROW = 150;

%% Find all the h5 files
h5Filenames = DATA_FOLDERS(1) + filesep + ...
    string({dir(rawDataDir + filesep + DATA_FOLDERS(1) + filesep + "*.hdf5").name});
h5Filenames = [h5Filenames, DATA_FOLDERS(2) + filesep + ... 
    string({dir(rawDataDir + filesep + DATA_FOLDERS(2) + filesep + "*.hdf5").name})];

nFiles = numel(h5Filenames);

%% Create the training and testing partition splits
TESTING_PCT = 0.2;
holdoutPartition = cvpartition(nFiles, "Holdout", TESTING_PCT);

% 25% of the testing data is equal to 20% of the total data
VALIDATION_PCT = 0.25;
validationPartition = cvpartition(holdoutPartition.TrainSize, "Holdout", VALIDATION_PCT);

trainValFiles = h5Filenames(training(holdoutPartition));
trainingFiles = trainValFiles(training(validationPartition));
validationFiles = trainValFiles(test(validationPartition));

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


for i = 1:3

    if i == 1
        setSize = validationPartition.TrainSize;
        files = trainingFiles;
    elseif i == 2
        setSize = validationPartition.TestSize;
        files = validationFiles;
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

        metad3ta=struct();

        % The labels are the same for each image in the h5 file.
        rangebinLabels = h5data.parameters.rangebin_labels.labels;

        % The labels are 0 = nothing, 1 = drone, and 2 = wall. However, I want
        % to do a binary classification, so the wall labels need to be set to 0
        rangebinLabels(rangebinLabels == 2) = 0;

        % Elsewhere in the code, the labels are expected to be boolean. In
        % particular, the 1D CNN expects false/true label names.
        rangebinLabels = logical(rangebinLabels);

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

            data{cellIdx} = squeeze(h5data.data.data(imageNum,1:TRUNCATE_ROW,:));
            timestamps{cellIdx} = h5data.data.timestamps(imageNum,:) * SEC_PER_NS;
            labels{cellIdx} = rangebinLabels(1:TRUNCATE_ROW);
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
            'trainingMetadata', 'holdoutPartition', 'validationPartition', '-v7.3');

        clear 'trainingData' 'trainingLabels' 'trainingTimestamps' ...
            'trainingMetadata';
    elseif i == 2
        validationData = data;
        validationLabels = labels;
        validationTimestamps = timestamps;
        validationMetadata = meta;

        if ~exist(validationDataDir, "dir")
            mkdir(baseDataDir, "validation");
        end
        save(validationDataDir + filesep + "validationDataRaw.mat", ...
            'validationData', 'validationLabels', 'validationTimestamps', ...
            'validationMetadata', 'holdoutPartition', 'validationPartition', '-v7.3');

        clear 'validationData' 'validationLabels' 'validationTimestamps' ...
            'validationMetadata';
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

