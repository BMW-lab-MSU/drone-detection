# drone-detection


# Data setup
You can specify the locations of the data and results folders in the `beehiveDataSetup.m` script. By default, the scripts uses the following relative path setup, where `code` is a folder containing this repository:
```
├── code
├── data
│   ├── combined
│   ├── preprocessed
│   ├── raw
│   │   ├── 2022-06-23
│   │   ├── 2022-06-24
│   │   ├── 2022-07-28
│   │   ├── 2022-07-29
│   ├── testing
│   ├── training
│   └── validation
└── results
    ├── changepoint-results
    │   └── runtimes
    ├── testing
    └── training
        ├── classifiers
        ├── data-sampling
        ├── default-params
        └── hyperparameter-tuning
```


# Running the code

> [!IMPORTANT]
> In general, you need to call `pathSetup.m` first before running anything, as that script adds all the folders in this repo to your MATLAB path. Additionally, if you use the default relative data path setup described above, you must run all of your code from the root of this repository, not the subfolders; if you specify full paths in `beehiveDataSetup.m`, then you can run the code from anywhere.

> [!TIP]
> This code is designed to run on a computing cluster. If you have access to a computing cluster that uses slurm, you can update and use the scripts in the `slurm` folder. The code will still run perfectly fine on a normal desktop computer&mdash;it will just take longer.

The folder icons (📁) after the headings link to the relevant folder in the repository.

There are three main portions of code, listed below. You have to run the data preparation first, but the supervised learning and changepoint detection sections are independent. Use the following links to jump to the sections.

- [Data preparation](#data-preparation)
- [Supervised learning](#supervised-learning)
- [Changepoint detection](#changepoint-detection)


## Data preparation [📁](data-wrangling)

0. (optional) Convert the csv label files into .mat files using `convertAllLabels.m`; this has already been done in the archived dataset.
1. Combine the individual raw data files into larger groups that can then be split into training and testing sets; this is done with `combineDataForTrainingTesting.m`
2. Preprocess the data using `preprocess.m`
3. Split the preprocessed data into the training, validation, and testing sets. `spiltData.m`

<details>
<summary>Using slurm</summary>

If you have access to a slurm cluster, these steps can be done by running [`prepare-data.sh`](slurm/perpare-data.sh).

</details>

## Supervised learning [📁](supervised-classification)

### Feature extraction [📁](feature-extraction)

Before training any of the feature-based algorithms, we need to precompute the features:

- training data: `precomputeTrainingFeatures.m`
- validation data: `precomputeValidationFeatures.m`
- testing data: `precomputeTestingFeatures.m`

<details>
<summary>Using slurm</summary>

If you have access to a slurm cluster, these steps can be done by running [`precompute-features.sh`](slurm/precompute-features.sh).

</details>

### Training [📁](supervised-classification/training/)

<details>
<summary>Using slurm</summary>

If you have access to a slurm cluster, all the training and testing can be launched using [`run-row-methods.sh`](slurm/run-row.methods.sh) and [`run-image-methods.sh`](slurm/run-image-methods.sh).

</details>

#### Data sampling parameter tuning (row methods only)
For the row-based methods, we first need to create the grid search parameters using `createDataSamplingGrid.m`. Once that is done, we can perform the grid search.

For the feature-based methods, call the `evalSamplingGridRowFeatureMethod` function with the grid search index, e.g.
```matlab
evalSamplingGridRowFeatureMethod(@AdaBoost,1,UseParallel=true,UseGPU=true)
```

For the deep learning methods, call the `evalSamplingGridRowDataMethod` function with the grid search index, e.g.
```matlab
evalSamplingGridRowDataMethod(@CNN1d,1,UseParallel=true,UseGPU=true)
```

This grid search was designed to run in parallel on a computing cluster, specifically using slurm job arrays. See the `samplingGridSearch*.slurm` scripts for full details of the function calls for each of the classifiers. In particular, for the neural networks that had more than one hidden layer, we have to pass in the parameters (e.g., layer sizes) into the `evalSamplingGrid*` functions.

If you don't have access to a computing cluster, you run the grid search methods in a for loop:
```matlab
for gridIdx = 1:16
    evalSamplingGridRowFeatureMethod(@AdaBoost,1,UseParallel=true,UseGPU=true)
end
```
You could also use a parallel for loop, which may or may not be faster than running each iteration with parallel feature extraction and training (`UseParallel=true`):
```matlab
parfor gridIdx = 1:16
    evalSamplingGridRowFeatureMethod(@AdaBoost,1,UseParallel=false,UseGPU=true)
end
```


Once the grid search for an algorithm is done, run the `selectBestSamplingParams` function to save the sampling parameters that resulted in the best MCC value, e.g.:
```matlab
selectBestSamplingParams("AdaBoost")
```

#### Train default 2D CNNs (image methods only) [📁](supervised-classification/training/cnn2d-default-training/)
For the image-based methods (2D CNNs), we need to train networks with the default hyperparameters. This is because the default hyperparameters might perform better than the parameters found during tuning, and thus we would prefer to use the default parameters for the final training.

The default 2D CNNS can be trained with the `trainCNN2dManualParams` function. See the trainDefaultCNN2d*.slurm scripts to see the relevant function call for each 2D CNN.

For example, here's the code used to train the default 3-layer 2D CNN:
```matlab
p.FilterSize=[16,2;,16,2;16,2];
p.Nfilters=[20,20,20];
trainCNN2dManualParams(@CNN2d,UseGPU=true,ClassifierParams=p) 
```

#### Model hyperparameter tuning [📁](supervised-classification/training/hyperparameter-tuning/)

##### Create hyperparameter search values
First, we need to create mat files that contain the model's hyperparameter search values. Each model has a separate function to create it's associated hyperparameter search values, except AdaBoost and RUSBoost, which use the same search values.

Examples:
```matlab
# For AdaBoost and RUSBoost
createBoostTreesHyperparamSearchRange
```
```matlab
createCNN2d1LayerHyperparamSearchRange
```

See [hyperparameter-tuning](supervised-classification/training/hyperparameter-tuning/) for the functions that create the hyperparameter search values.

##### Tune hyperparameters

There are three different hyperparameter tuning functions, one for each of the algorithm types:
- feature engineering methods: `tuneHyperparamsRowFeatureMethod`
- 1D CNNs: `tuneHyperparamsRowDataMethod`
- 2D CNNs: `tuneHyperparamsImageMethod`

Examples:
```matlab
tuneHyperparamsRowFeatureMethod("StatsNeuralNetwork1Layer",@StatsNeuralNetwork,UseParallel=true);
tuneHyperparamsRowDataMethod("CNN1d1Layer",@CNN1d,UseGPU=true,UseParallel=true);
tuneHyperparamsImageMethod("CNN2d3Layer",@CNN2d,UseGPU=true);
```

See the tuneHyperparams*.slurm scripts in the [`slurm`](slurm) folder to see the function calls for each method.

#### Final training [📁](supervised-classification/training/final-training/)

After hyperparameter tuning is done, the algorithms need to be trained one final time on the entire training/validation set.

Similar to the hyperparameter tuning, there are three different training functions, one for each of the algorithm types:
- feature engineering methods: `trainRowFeatureMethod`
- 1D CNNs: `trainRowDataMethod`
- 2D CNNs: `trainImageMethod`
Each of the methods take the classifier name as a string.

Examples:
```matlab
trainRowFeatureMethod("AdaBoost");
trainRowDataMethod("CNN1d5Layer");
trainImageMethod("CNN2d3Layer");
```

### Testing [📁](supervised-classification/testing/)

<details>
<summary>Using slurm</summary>

Again, if you have access to a slurm cluster, all the training and testing code can be launched using [`run-row-methods.sh`](slurm/run-row.methods.sh) and [`run-image-methods.sh`](slurm/run-image-methods.sh).

</details>

Similar to the hyperparameter tuning, there are three different testing functions, one for each of the algorithm types:
- feature engineering methods: `testRowFeatureMethod`
- 1D CNNs: `testRowDataMethod`
- 2D CNNs: `testImageMethod`
Each of the methods take the classifier name as a string.

Examples:
```matlab
testRowFeatureMethod("AdaBoost");
testRowDataMethod("CNN1d5Layer");
testImageMethod("CNN2d3Layer");
```

See the train*.slurm scripts in the [`slurm`](slurm) folder to see the function calls for each method.


## Changepoint detection [📁](changepoint-detection)

There are two different changepoint detection methods (gfpop and MATLAB's `findchangepts`); for each method, there are three different procedures: analyzing the rows, analyzing the columns, or analyzing both the rows and columns.

<details>
<summary>Using slurm</summary>

If you have access to a slurm cluster, you can run all the changepoint algorithms with [`run-changepoint-methods.sh`](slurm/run-changepoint-methods.sh). The `gfpop` mex wrapper still needs to be [compiled](#gfpop) before launching the slurm jobs.

</details>

### MATLAB `findchangepts`
`findchangepts` requires MATLAB's Signal Processing Toolbox. To run the algorithms, the [data must be prepared](#data-preparation) already.

The row, column, and "both" algorithms are run with the following scripts:
- rows: `matlabChptsRows`
- columns: `matlabChptsCols`
- both: `matlabChptsBoth`

### gfpop [📁](changepoint-detection/gfpop/)

Before running the `gfpop` algorithm, you must compile the [mex](https://www.mathworks.com/help/matlab/call-mex-file-functions.html) file, `gfpop_mex.cpp`. This can be done by going to the `changepoint-detection/gfpop` folder and running `mex`:
```bash
cd changepoint-detection/gfpop
mex gfpop_mex.cpp
```

Once the mex file is compiled, you can run the row, column, and "both" algorithms:
- rows: `gfpopRows`
- columns: `gfpopCols`
- both: `gfpopBoth`

### Analyzing results
Once all the scripts have been run, the results can be analyzed and collected by running `changepointAnalysis.m`.

## Figures [📁](figures)
For information on recreating the figures, please see the [figures](figures) folder.

# License
All code in this repository, except the [`gfpop`](changepoint-detection/gfpop) code, is licensed under the BSD 3-Clause License. `gfpop` is licensed under the MIT License.
