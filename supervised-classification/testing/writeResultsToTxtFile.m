function writeResultsToTxtFile(classifierName,results,dir)
% writeResultsToTxtFile write testing results to a text file for easier viewing.
%
%   writeResultsToTxtfile(classifierName,results,dir) saves the results struct
%   as <classifierName>Results.txt in dir.
%
%   Using a text file is easier than loading a mat file to view the results.

% SPDX-License-Identifier: BSD-3-Clause

arguments
    classifierName (1,1) string
    results (1,1) struct
    dir (1,1) string
end

fd = fopen(dir + filesep + classifierName + "Results.txt", "w");

fprintf(fd,"Row results:\n");

fprintf(fd,"Confusion\n");
fprintf(fd,"\t%6u\t%6u\n",results.Row.Confusion(1,1),results.Row.Confusion(1,2));
fprintf(fd,"\t%6u\t%6u\n",results.Row.Confusion(2,1),results.Row.Confusion(2,2));

fprintf(fd,"Precision = %.3f\n",results.Row.Precision);
fprintf(fd,"Recall = %.3f\n",results.Row.Recall);
fprintf(fd,"F2 = %.3f\n",results.Row.F2);
fprintf(fd,"MCC = %.3f\n",results.Row.MCC);
fprintf(fd,"Accuracy = %.3f\n",results.Row.Accuracy);


fclose(fd);

end
