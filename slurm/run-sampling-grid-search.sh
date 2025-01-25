#!/bin/bash

#classifiers=(\
#    "AdaBoost"\
#    "RUSBoost"\
#    "CNN1d1Layer"\
#    "CNN1d3Layer"\
#    "CNN1d5Layer"\
#    "CNN1d7Layer"\
#    "LinearSVM"\
#    "StatsNeuralNetwork1Layer"\
#    "StatsNeuralNetwork3Layer"\
#    "StatsNeuralNetwork5Layer"\
#    "StatsNeuralNetwork7Layer")
classifiers=(\
    "CNN1d3Layer"\
    "CNN1d5Layer")

#output=`sbatch createDataSamplingGrid.slurm`
#jobid_grid=`echo "${output}" | cut -d' ' -f4`

for classifier in "${classifiers[@]}"; do
    output=`sbatch samplingGridSearch"${classifier}".slurm`
    #output=`sbatch --dependency=afterok:${jobid_grid} samplingGridSearch"${classifier}".slurm`
    jobid=`echo "${output}" | cut -d' ' -f4`

    output=`sbatch --dependency=afterok:"${jobid}" selectBestSamplingParams"${classifier}".slurm`
    jobid1=`echo "${output}" | cut -d' ' -f4`
done

