function writeGridSearchResultsToTxtFile(classifierName,rowResults,samplingParams,classifierParams)

% SPDX-License-Identifier: BSD-3-Clause

arguments
    classifierName (1,1) string
    rowResults (1,1)
    samplingParams (1,1)
    classifierParams (1,1)
end

% Setup data paths
dataSetup;

% Open output file
fd = fopen(samplingResultsDir + filesep + classifierName + "Results.txt", "w");

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

fprintf(fd,"Sampling parameters:\n");

fprintf(fd,"Undersample ratio = %f\n",samplingParams.UndersampleRatio);
fprintf(fd,"# synthetic  = %f\n",samplingParams.NOversample);

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

