#!/bin/bash
##
## Lines starting with #SBATCH are read by Slurm. Lines starting with ## are comments.
## All other lines are read by the shell.
##
## Basic parameters
##
#SBATCH --account=group-bradwhitaker
#SBATCH --partition=gpuunsafe

#SBATCH --cpus-per-task=32 
#SBATCH --mem=250G        
#SBATCH --time=0-16:00:00 

#SBATCH --array=1-12

#SBATCH --gres=gpu:2

#SBATCH --job-name=cnn1d3layer-sampling-search              # job name
#SBATCH --output=log/%x-%A-%a.out         # standard output from job
#SBATCH --error=log/%x-%A-%a.err          # standard error from job

module load cuDNN/8.9.7.29-CUDA-12.3.0
module load math/matlab/2023a

cd ../

matlab -batch "pathSetup; p.FilterSize=[16,16,16]; p.NFilters=[20,20,20]; evalSamplingGridRowDataMethod(@CNN1d,${SLURM_ARRAY_TASK_ID},ClassifierParams=p,UseParallel=true,UseGPU=true)"
