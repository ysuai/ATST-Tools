#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --cpus-per-task=4
#SBATCH -J AutoNEB-ABACUS
#SBATCH -o running_autoneb.out
#SBATCH -e running_autoneb.err
#SBATCH -p C064M0256G
#SBATCH --qos=low

# JamesMisaka in 2023-11-02
# workflow of abacus-neb2sella method

# in developer's PKU-WM2 server
source /lustre/home/2201110432/apps/miniconda3/etc/profile.d/conda.sh
conda activate ase
module load abacus/3.7.1-icx

# variable
INIT="STRU_IS" 
FINAL="STRU_FS"
FORMAT="abacus"

# Job state 
echo $SLURM_JOB_ID > JobRun.state
echo "Start at $(date)" >> JobRun.state

# Job Starting
echo "===== NEB2Sella Job Starting =====" 

# run neb
echo "===== Running NEB2Sella ====="

python neb2sella_abacus.py $INIT $FINAL $FORMAT

echo "===== Done ! ====="

# Job State
echo "End at $(date)" >> JobRun.state
