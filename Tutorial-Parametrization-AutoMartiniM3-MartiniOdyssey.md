Prerequisites: You need to have GROMACS installed on your machine!


# Installing Auto-MartiniM3 (without creating conda environment)
<!-- 
    git clone https://github.com/Martini-Force-Field-Initiative/Automartini_M3.git
    cd Automartini_M3
    pip install .
-->
    git clone https://github.com/M2BMI-Lab/Workshop-MartiniOdyssey.git
    cd Workshop-MartiniOdyssey
    bash setup.sh
    source Workshop_AutoM3/bin/activate 
    cd ./Tutorial-Parametrization-datafiles/  
    
To use AutomartiniM3

    python -m auto_martiniM3 [mode] [options]

    
## Creating Coarse-Grained model with Auto-MartiniM3

We will need a unique SMILES string of each molecule of interest, like caffeine (1,3,7-trimethyl-1H-purine-2,6(3H,7H)-dione). To obtain the SMILE string, from your pdb or direct drawing using [OpenBabel server](https://www.cheminfo.org/Chemistry/Cheminformatics/FormatConverter/index.html).


On the example of caffeine molecule, the smile is `CN1C=NC2=C1C(=O)N(C(=O)N2C)C`  

There are two approaches to generate a coarse-grained (CG) model of a small ligand using AutoMartini3:

 - From a SMILES code:  
   
       python -m auto_martiniM3 --smi "CN1C=NC2=C1C(=O)N(C(=O)N2C)C" --mol CAFF --aa CAFF_aa.gro

 - From a SDF file:  
   
       python -m auto_martiniM3 --sdf caffeine.sdf --mol CAF_SD

<p align="center">
  <img src="./image/caffeine_AA.png" alt="Caffeine molecule" width="220">  
  <img src="./image/caffeine_CG.png" alt="Caffeine molecule CG" width="320">  
</p>
<p align="center">
  <em>Figure 1 | Structure of the caffeine molecule</em>
</p>  

 - __Check the generated files using texteditor and VMD. What are the differences ?__
   
   
# Testing the model in a water box
 
Run the commands with GROMACS in bash:
 

*   insert one molecule parametrized with Auto Martini M3 into the water box
```bash 
gmx_mpi solvate -cp CAFF.gro -cs Water_CG.gro -o CAFF_CG_BW.gro -box 5 5 5
```    
## Creating the topology file

*  Now, you need to create a topology file (.top). Use the file system_init.top provided.
   Pay attention to the Martini path—it must point to the corresponding file.
   If it does not, adjust the Martini path accordingly
```bash 
cp system_init.top system.top
```
   
*  To generate a correct topology file, include the `itp` file previously created with Auto Martini M3.
You must also determine the number of water molecules present in your system. The following command lines can be used:
```bash
water_mols=$(grep W  CAFF_CG_BW.gro | wc -l)
echo "CAFF               1" >> system.top
echo "W               $water_mols" >> system.top
sed -i -e  s"/LIGAND/CAFF/"g system.top
```

## All stages from energy minimization through equilibration to production

*  __Minimization__
```bash     
gmx_mpi grompp -p system.top -c CAFF_CG_BW.gro -f em-Wat-lig.mdp -o 1-min_CAFF_CG.tpr -po 1-min.mdp  -maxwarn 3
gmx_mpi mdrun -v -deffnm 1-min_CAFF_CG >> mdrun.log 2>&1
```

*  __Equilibration (NVT)__  
```bash
gmx_mpi grompp -p system.top -c 1-min_CAFF_CG.gro -f eq-Wat-lig.mdp -o 2-eq_CAFF_CG.tpr  -po 2-eq.mdp  -maxwarn 3
gmx_mpi mdrun -v -deffnm 2-eq_CAFF_CG  >> mdrun.log 2>&1
```

*  __Production (NPT)__
```bash     
gmx_mpi grompp -p system.top -c 2-eq_CAFF_CG.gro -f run-Wat-lig.mdp -o 3-run_CAFF_CG.tpr -po 3-run.mdp  -maxwarn 3
gmx_mpi mdrun -v -deffnm 3-run_CAFF_CG
```
 __If the simulation in a water box will finish without any problems, we can go on and work with more complicated system.__

### Visualize your simulation of Caffein in water  

 - You could center the ligand in th midlle of the water box. To do so, you can use the following command:
```bash    
gmx_mpi trjconv -f 3-run_CAFF_CG.xtc -s 3-run_CAFF_CG.tpr -o 3-run_CAFF_CG_centered.xtc -center -pbc mol
```
   the flag `-pbc mol` puts the center of mass of molecules in the box,
   
     

### What if my simulation crashes?
 
If your simulation crashes, you will need to adjust the molecule's topology, either manually or by using open-source tools from the [Martini Universe](https://cgmartini.nl/docs/downloads/tools/topology-structure-generation.html), such as [Bartender](https://github.com/Martini-Force-Field-Initiative/Bartender). During this workshop, we will focus on optimising molecules by hand.
#### Why small molecules are tricky
Small molecules can be quite challenging to parametrise, particularly when their structure includes aromatic rings.
##### Step 1: Smooth the equilibration process
A good first step is to divide the equilibration into 3-4 stages with gradually increasing timesteps:
Start with a very low timestep, e.g. 2 fs
Increase it incrementally with each stage

Arrive at 10 fs for the final equilibration stage
You can then run the production simulation at 10 fs, which is generally sufficient for small molecules.

##### Step 2: Model optimisation (if instabilities persist)
If the simulation remains unstable, deeper model optimisation will be required.
For larger molecules, Auto-Martini M3 generates multiple bonded parameters, including improper dihedrals, to keep the molecule together. However, these can introduce instabilities in GROMACS.

#### To troubleshoot:

* Remove all dihedrals and attempt to simulate. If the molecule is stable, reintroduce dihedral angles one by one to identify the problematic one, then exclude it from the final model. Note that having some dihedrals defined is always preferable for keeping planarity of ringed molecules.
* Review force constant values, as the defaults chosen by Auto-Martini M3 may not be optimal. You can refine them using online tools such as Bartender. This requires a special input file, which Auto-Martini M3 can generate automatically using the -bartender flag.
