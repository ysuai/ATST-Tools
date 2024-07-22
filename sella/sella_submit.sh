#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --cpus-per-task=4
#SBATCH -J Sella-ABACUS
#SBATCH -o running_sella.out
#SBATCH -e running_sella.err
#SBATCH -p C064M0256G
#SBATCH --qos=low

# JamesMisaka in 2023-11-14
# workflow of ase-abacus-sella method
# for one calculator, ntasks-per-node for mpi, cpus-per-task for openmp

# in developer's PKU-WM2 server
source /lustre/home/2201110432/apps/miniconda3/etc/profile.d/conda.sh
conda activate ase
module load abacus/3.7.1-icx

# if one just done neb calculation and done neb_post.py
# python neb2dimer.py neb_latest.traj # or neb.traj

# Job state 
echo $SLURM_JOB_ID > JobRun.state
echo "Start at $(date)" >> JobRun.state

# just do dimer by run !
# do check your ntasks(mpi) and cpu(omp) setting is right
python sella_run.py

echo "===== Sella Calculation Done at $(date)! ====="

# Job State
echo "End at $(date)" >> JobRun.state