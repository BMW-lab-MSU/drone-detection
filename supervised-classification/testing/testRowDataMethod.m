function testRowDataMethod(classifierName)
% testRowDataMethod test row- and data-based algorithm on the testing set
%
%   testRowDataMethod(classifierName) tests the classifer referred to by
%   classifierName. 
% 
%   classifierName is the classifer name used when saving files,
%   not the name of the class that implements the classifier, e.g.
%   CNN1D5Layer, not CNN1D.

% SPDX-License-Identifier: BSD-3-Clause

arguments
    classifierName (1,1) string
end

% Setup paths
dataSetup;

% Load in the classifier
load(finalClassifierDir + filesep + classifierName,"classifier");

% Load in the testing data and labels
load(testingDataDir + filesep + "testingDataRaw","testingLabels","testingData");

results.Row.TrueLabels = classifier.formatLabels(testingLabels);

% Predict the row labels
results.Row.PredictedLabels = predict(classifier,testingData);

% Compute the row results
results.Row.Confusion = confusionmat(results.Row.TrueLabels,...
    results.Row.PredictedLabels);

[a, p, r, f2, ~, mcc] = analyzeConfusion(results.Row.Confusion);
results.Row.Accuracy = a;
results.Row.Precision = p;
results.Row.Recall = r;
results.Row.F2 = f2;
results.Row.MCC = mcc;

% Display results
disp('Row results')
disp(results.Row.Confusion)
disp(results.Row)

% Save results
if ~exist(testingResultsDir,"dir")
    mkdir(baseResultsDir,"testing");
end

save(testingResultsDir + filesep + classifierName + "Results","results","-v7.3");

writeResultsToTxtFile(classifierName,results,testingResultsDir);

end
