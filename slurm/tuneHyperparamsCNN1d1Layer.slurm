#!/bin/bash
##
## Lines starting with #SBATCH are read by Slurm. Lines starting with ## are comments.
## All other lines are read by the shell.
##
## Basic parameters
##
#SBATCH --account=group-bradwhitaker
#SBATCH --partition=gpuunsafe

#SBATCH --cpus-per-task=32               # number of cores to allocate
#SBATCH --mem=250G                        # ammount of Memory allocated
#SBATCH --time=0-16:00:00               # maximum job run time in days-hours:minutes:secconds

#SBATCH --gres=gpu:a100:4


#SBATCH --job-name=cnn1d1layer-hyperparam-tuning              # job name
#SBATCH --output=log/%x-%A-%a.out         # standard output from job
#SBATCH --error=log/%x-%A-%a.err          # standard error from job

module load cuDNN/8.9.7.29-CUDA-12.3.0

module load math/matlab/2023a

cd ../

matlab -batch "pathSetup; tuneHyperparamsRowDataMethod(\"CNN1d1Layer\",@CNN1d,UseGPU=true,UseParallel=true)" 
