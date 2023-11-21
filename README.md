# ATST-Tools
Advanced ASE Transition State Tools for ABACUS, including:
- NEB and improvement, like Dynamic NEB
- CI-NEB, IT-NEB and others
- AutoNEB
- Dimer

Version v1.1.2

## Dependencies:
- [ASE](https://wiki.fysik.dtu.dk/ase/about.html)
- [ABACUS](https://abacus.deepmodeling.com/en/latest/)
- [ASE-ABACUS interface](https://gitlab.com/1041176461/ase-abacus)
- [GPAW](https://wiki.fysik.dtu.dk/gpaw/install.html) if one wants to run NEB images relaxation in parallel

Notice: GPAW and ABACUS should be dependent on same MPI and libraries environments. 
For instance, if your ABACUS is installed by Intel-OneAPI toolchain, your GPAW should NOT be dependent on gcc-toolchain like OpenMPI and OpenBLAS.

## Workflow

![ATST-workflow](img/ATST-workflow.png)

## NEB workflow
### Usage
The NEB workflow is based on 3 main python scripts and 1 workflow submit script. Namely:

- `neb_make.py` will make initial guess for NEB calculation, which is based on ABACUS (and other calculator) output files of initial and final state. This script will generate `init_neb_chain.traj` for neb calculation. Also, You can do continuation calculation by using this script. You can get more usage by `python neb_make.py`. 
- `neb_run.py` is the key running script of NEB, which will run NEB calculation based on `init_neb_chain.traj` generated by `neb_make.py`. This script will generate `neb.traj` for neb calculation. Users should edit this file to set parameters for NEB calculation. sereal running can be performed by `python neb_run.py`, while parallel running can be performed by `mpirun gpaw python neb_run.py`.
When running, the NEB trajectory will be output to `neb.traj`, and NEB images calculation will be doing in `NEB-rank{i}` directory for each rank which do calculation of each image. 
- `neb_post.py` will post-process the NEB calculation result, which will based on `neb.traj` from neb calculation. This script will generate nebplots.pdf to view neb calculation result, and also print out the energy barrier and reaction energy. You can get more usage by `python neb_post.py`. Meanwhile, users can also view result by `ase -T gui neb.traj` or `ase -T gui neb.traj@-{n_images}:` by using ASE-GUI
- `neb_submit.sh` will do all NEB process in one workflow scripts and running NEB calculation in parallel. Users should edit this file to set parameters for NEB calculation. Also this submit script can be used as a template for job submission in HPC. the Default setting is for `slurm` job submission system.

The workflow also support use `AutoNEB` method in ASE
- `autoneb_run.py` is the key running script for `AutoNEB` method, which is like `neb_run.py` but the NEB workflow in `AutoNEB` is enhanced and the I/O logic have some difference. Users can use it with `mpirun gpaw python autoneb_run.py` by existing `init_neb_chain.traj` which can only contain initial and final state or contain some initial-guess.
- `autoneb_submit.sh` will do all AutoNEB process in one workflow and running AutoNEB calculation in parallel. Users should edit this file to set parameters for AutoNEB calculation. Also this submit script can be used as a template for job submission in HPC. the Default setting is for `slurm` job submission system.
- `neb_make.py` and `neb_post.py` can be used for `AutoNEB` method, but the workflow have slight difference. 

Users can run NEB each step respectively: 
1. `python neb_make.py [INIT/result] [FINAL/result] [n_max]` to create initial guess of neb chain
   1. Also You can use `python neb_make.py -i [input_traj_file] [n_max]` to create initial guess from existing traj file, which can be used for continuation calculation.
2. `python neb_run.py` or `mpirun -np [nprocs] gpaw python neb_run.py` to run NEB calculation
3. `python neb_post.py [traj_file] [n_max]` to post-process NEB calculation result

Users can run AutoNEB each step respectively:
1. `python neb_make.py [INIT/result] [FINAL/result] [nprocs]` to create initial guess of neb chain
2. `mpirun -np [nprocs] gpaw python autoneb_run.py` to run AutoNEB calculation
3. `python neb_post.py --autoneb ([autoneb_traj_files])` to post-process NEB calculation result

Also, user can run each step in one script `neb_submit.sh` by `bash neb_submit.sh` or `sbatch neb_submit.sh`. AutoNEB scripts usage is like that. 

Because ATST is originally based on ASE, the trajectory file can be directly read, view and analysis by `ase gui` and other ASE tools. Abide by `neb_post.py`, We also offer some scripts to help you:
- `neb_dist.py`: This script will give distance between initial and final state, which is good for you to check whether the atoms in two image is correspondent, and is also a reference for setting number of n_max
- `traj_transform.py`: This script can transfer traj files into other format like `extxyz`, `abacus`(STRU), `cif` and so on (coming soon). Also if user specify `--neb` option, this script will automatically detect and cut the NEB trajectory when doing format transform. This script will be helpful for analysis and visualization of NEB trajectory.

> Notice: Before you start neb calculation process, make sure that you have check the nodes and cpus setting in `neb_submit.sh` and `neb_run.py` to make sure that you can reach the highest performance !!!  

### Method
- For serial NEB calculation, DyNEB, namely dynamic NEB method `ase.mep.neb.DyNEB` is for default used.
- For parallel NEB calculation, `ase.mep.neb.NEB` traditional method is for default used, and `ase.mep.autoneb.AutoNEB` method should be independently used. 
- The Improved Tangent NEB method `IT-NEB` and Climbing Image NEB method `CI-NEB` in ASE are also default used in this workflow, which is highly recommended by Sobervea. In `AutoNEB`, `eb` method is used for default, but Improved Tangent method is also recommended.
- Users can change lots of parameter for different NEB setting. one can refer to [ASE NEB calculator](https://wiki.fysik.dtu.dk/ase/ase/neb.html#module-ase.neb) for more details: 
- Notice: in surface calculation and hexangonal system, the vaccum and c-axis should be set along y-direction but not z-direction, which is much more efficient for ABACUS calculation.

## Dimer workflow
### Usage
The Dimer workflow is based on 2 main python scripts and 2 workflow submit script. Namely:
- `neb2dimer.py` can be used by `python neb2dimer [neb.traj] ([n_max])`, which will transform NEB trajetory `neb.traj` or NEB result trajectory `neb_result.traj` to Dimer input files,  including:
- - `dimer_init.traj` for initial state of Dimer calculation, which is the highest energy image, namely, TS state. 
- - `displacement_vector.npy` for displacement vector of Dimer calculation, which will be generated from position minus of the nearest image before and after TS point, and be normalized to 0.01 Angstrom. 
- `dimer_run.py` is the key running script of Dimer calculation, which will run Dimer calculation based on `dimer_init.traj` and `displacement_vector.npy` generated by `neb2dimer.py` or based on other setting. This script will generate `dimer.traj` for Dimer calculation trajectory. Users should edit this file to set parameters for Dimer calculation, and run Dimer calculation by `python dimer_run.py`. When running, any Dimer images calculation will be doing in `Dimer` directory.
- `dimer_submit.sh` will do Dimer workflow in one scripts. The Default setting is for `slurm` job submission system.
- `neb-dimer_srun.sh` is a try to run NEB + Dimer calculation in one server scripts. The Default setting is for `slurm` job submission system.

### Method
(Waiting for update)

## Notice
Some property should be get via specific way from trajectory files, and some will be lost in trajetory files, 
- Stress property will not be stored in trajetory file
- In NEB calculation, the Force property for fixed atoms and Stress property will NOT be stored in trajectroy file.
- in Dimer calculation, the Energy, Forces and Stress property will NOT be stored in trajetory file.
- in AutoNEB calculation, all property in processing trajectory will be stored in AutoNEB_iter directory, but in the result `run_autoneb???.traj`, the forces and stress information will be lost.



## Examples
The example below need to be more concise, which have much more data in there
- Li-diffu-Si: Li diffusion in Si, an example for running ASE-NEB-ABACUS based on existing ABACUS input files of initial and final state, using ABACUS as SCF calculator and ASE as optimizer and NEB calculator.  Also, an dflow example is proposed from DeepModeling community.
- H2-Au111: H2 dissociation on Au(111) surface, an example for running ASE-NEB-ABACUS based on existing ABACUS input files of initial and final state, use ABACUS as SCF calculator,use ASE for initial and final state optimization and use ASE as NEB calculator. 
- N2-Cu111 : N2 dissociation on Cu(111) surface, an example for running ASE-NEB-ABACUS based on existing ABACUS input files of initial and final state, use ABACUS as SCF calculator, use ABACUS as optimizer for optimization of initial state and final state, use ASE as NEB calculator
- CO-Pt111 : CO dissociation on Pt(111) surface, an example for running ASE-NEB-ABACUS based on existing ABACUS input files of initial and final state, use ABACUS as SCF calculator, use ABACUS as optimizer for optimization of initial state and final state, use ASE as NEB calculator
- Cy-Pt_graphene: Cyclohexane dehydrogenation on Pt-doped graphene surface, an example for running ASE-NEB-ABACUS based on existing ABACUS input files of initial and final state, use ABACUS as optimizer for optimization of initial state and final state, use ASE as NEB calculator

AutoNEB example ix on update, Dimer example is preparing

## Next Examples
- FTS Fe5C2-510: FTS process on Fe5C2(510) surface. Which is the final goal, in this example we will focus on setting `magmom` during NEB calculation, which is important for spin-polarized magnetic system.
- - CO dissocation process and C vacancy generation process
- - C-C coupling process
- TS of MTM process by H2O2 in Cu/Ag-ZSM5 system, which is a example of large catalysis system. will including:
- - proton transfer process
- - CH4 dissociation process
- - CH3OH generation process
- - H2O2 dissociation process



## Developing
- [x] Use interface to read ABACUS STRU file and ABACUS output
- [x] Flexible input for different NEB method in ASE
- [x] `DyNEB` implementation and test
- [x] Now used optimum option: idpp-guess + IT-NEB + CI-NEB parallel method
- [x] Make bottom atom fixed when read from `running*.log` of ABACUS
- [x] Give an initial guess print-out of NEB images
- [x] Decoupling to init-guess -> NEB calculation -> result post-process
- [x] More test in surface reaction system
- [x] Parallel computing during images relaxation by `gpaw python`
- [x] `AutoNEB` implementation
- [x] Connected to Dimer method
- [x] More test in magnetic surface reaction system
- [ ] put calculation setting in an independent file (decoupling run*.py)


