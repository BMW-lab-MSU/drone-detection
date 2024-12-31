#!/bin/bash

classifiers=(\
    "AdaBoost"\
    "RUSBoost"\
    "CNN1d1Layer"\
    "CNN1d3Layer"\
    "CNN1d5Layer"\
    "CNN1d7Layer"\
    "LinearSVM"\
    "StatsNeuralNetwork1Layer"\
    "StatsNeuralNetwork3Layer"\
    "StatsNeuralNetwork5Layer"\
    "StatsNeuralNetwork7Layer")


for classifier in "${classifiers[@]}"; do

    if [ "${classifier}" == "AdaBoost" ] || [ "${classifier}" == "RUSBoost" ]; then
        output=`sbatch createBoostedTreesHyperparamSearchRange.slurm`
        jobid2=`echo "${output}" | cut -d' ' -f4`
    else
        output=`sbatch create"${classifier}"HyperparamSearchRange.slurm`
        jobid2=`echo "${output}" | cut -d' ' -f4`
    fi

done

