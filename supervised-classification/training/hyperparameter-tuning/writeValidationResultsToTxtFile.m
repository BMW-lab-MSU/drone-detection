function writeValidationResultsToTxtFile(classifierName,results,validationLabels,classifierParams)

% SPDX-License-Identifier: BSD-3-Clause

arguments
    classifierName (1,1) string
    results (1,1)
    validationLabels
    classifierParams (1,1)
end

% Setup data paths
dataSetup;

% Open output file
fd = fopen(hyperparameterResultsDir + filesep + classifierName + "Results.txt", "w");

% Find the results with the minimum objective
minIdx = results.IndexOfMinimumTrace(end);
rowResults = results.UserDataTrace{minIdx};

% Load in the sampling results (if it exists) to check if the default
% parameters performed better than the parameters tried by bayesopt
filepath = samplingResultsDir + filesep + classifierName + "BestParams.mat";
if exist(filepath,"file")

    load(filepath,"classificationResults");
    
    if classificationResults.MCC > rowResults.MCC
        rowResults = classificationResults;
    end
end

if contains(classifierName,"CNN1d")
    trueLabels = DeepLearning1dClassifier.formatLabels(validationLabels);
else
    trueLabels = StatsToolboxClassifier.formatLabels(validationLabels);
end

% Write the classification results to the output text file
fprintf(fd,"Row results:\n");

fprintf(fd,"Confusion\n");
fprintf(fd,"\t%6u\t%6u\n",rowResults.Confusion(1,1),rowResults.Confusion(1,2));
fprintf(fd,"\t%6u\t%6u\n",rowResults.Confusion(2,1),rowResults.Confusion(2,2));

fprintf(fd,"Precision = %.3f\n",rowResults.Precision);
fprintf(fd,"Recall = %.3f\n",rowResults.Recall);
fprintf(fd,"F2 = %.3f\n",rowResults.F2);
fprintf(fd,"MCC = %.3f\n",rowResults.MCC);
fprintf(fd,"Accuracy = %.3f\n",rowResults.Accuracy);

fprintf(fd,"\n\n");

fprintf(fd,"Hyperparameters:\n");

for field = string(fieldnames(classifierParams))'
    if isnumeric(classifierParams.(field)) | islogical(classifierParams.(field))
        n = numel(classifierParams.(field));
        format = "%s =";
        for i = 1:n
            format = format + " %g";
        end
        format = format + "\n";
        fprintf(fd,format,field,classifierParams.(field));
    elseif ischar(classifierParams.(field)) | isstring(classifierParams.(field))
        fprintf(fd,"%s = %s\n",field,classifierParams.(field));
    elseif iscategorical(classifierParams.(field))
        fprintf(fd,"%s = %s\n",field,string(classifierParams.(field)));
    else
        error("we didn't handle this hyperparameter type: %s",class(classifierParams.(field)))
    end
end

fclose(fd);

end

