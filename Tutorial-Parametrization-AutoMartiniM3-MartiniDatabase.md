Prerequisites: You need to have GROMACS installed on your machine!


# Installing Auto-MartiniM3
```bash 
homedir=`pwd`
git clone https://github.com/Martini-Force-Field-Initiative/Automartini_M3.git
cd Automartini_M3
conda env create -f environment.yaml
``` 
This will create a conda environment called `automartiniM3` which you can activate with
```bash 
conda activate automartiniM3
```

### Testing

To run the test cases and validate your installation, you will need to have [pytest](https://docs.pytest.org/en/stable/getting-started.html) 
installed. If you installed `auto_martiniM3` with conda, then pytest should already be available in your environment.
```bash 
cd auto_martiniM3 
pytest -v tests
```
All tests should pass within few minutes.

To use AutomartiniM3:
```bash 
python -m auto_martiniM3 [mode] [options]
```

## Hands on tutorial

### Download needed files to execute the tutorial
```bash
cd ${homedir}
git clone https://github.com/M2BMI-Lab/Workshop-MartiniOdyssey.git
cd Workshop-MartiniOdyssey/Tutorial-Parametrization-datafiles/
```

# Creating Coarse-Grained model with Auto-MartiniM3

We will need a unique SMILES string of each molecule of interest, like caffeine (1,3,7-trimethyl-1H-purine-2,6(3H,7H)-dione). To obtain the SMILE string, from your pdb or direct drawing using [OpenBabel server](https://www.cheminfo.org/Chemistry/Cheminformatics/FormatConverter/index.html).


By taking the example of caffeine molecule, the smile is `CN1C=NC2=C1C(=O)N(C(=O)N2C)C`  

There are two approaches to generate a coarse-grained (CG) model of a small ligand using AutoMartini3:

 - From a SMILES code:  
```bash 
python -m auto_martiniM3 --smi "CN1C=NC2=C1C(=O)N(C(=O)N2C)C" --mol CAFF --aa CAFF_aa.gro
``` 

 - From a SDF file:  
```bash  
python -m auto_martiniM3 --sdf caffeine.sdf --mol CAF_SD
``` 

<p align="center">
  <img src="./images/caffeine_AA.png" alt="Caffeine molecule" width="220">  
  <img src="./images/caffeine_CG.png" alt="Caffeine molecule CG" width="320">  
</p>
<p align="center">
  <em>Figure 1 | Structure of the caffeine molecule</em>
</p>  

 - __Check the generated files using texteditor and VMD. What are the differences ?__
   
   
# Testing the model in a water box

Run the commands with GROMACS in bash:

*   insert one molecule parametrized with Auto Martini M3 into the water box.
```bash 
gmx solvate -cp CAFF.gro -cs Water_CG.gro -o CAFF_CG_BW.gro -box 5 5 5
```    
## Creating the topology file

*  Now, you need to create a topology file (.top). Use the file system_init.top provided.
   Pay attention to the Martini path—it must point to the corresponding file.
   If it does not, adjust the Martini path accordingly.
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
gmx grompp -p system.top -c CAFF_CG_BW.gro -f em-Wat-lig.mdp -o 1-min_CAFF_CG.tpr -po 1-min.mdp  -maxwarn 3
gmx mdrun -v -deffnm 1-min_CAFF_CG >> mdrun.log 2>&1
```

*  __Equilibration (NVT)__  
```bash
gmx grompp -p system.top -c 1-min_CAFF_CG.gro -f eq-Wat-lig.mdp -o 2-eq_CAFF_CG.tpr  -po 2-eq.mdp  -maxwarn 3
gmx mdrun -v -deffnm 2-eq_CAFF_CG  >> mdrun.log 2>&1
```

*  __Production (NPT)__
```bash     
gmx grompp -p system.top -c 2-eq_CAFF_CG.gro -f run-Wat-lig.mdp -o 3-run_CAFF_CG.tpr -po 3-run.mdp  -maxwarn 3
gmx mdrun -v -deffnm 3-run_CAFF_CG
```
 __If the simulation in a water box will finish without any problems, we can go on and work with more complicated system.__

### Visualize your simulation of Caffein in water  

 - You could center the ligand in th midlle of the water box. To do so, you can use the following command:
```bash    
gmx trjconv -f 3-run_CAFF_CG.xtc -s 3-run_CAFF_CG.tpr -o 3-run_CAFF_CG_centered.xtc -center -pbc mol
```
   the flag `-pbc mol` puts the center of mass of molecules in the box.
   
     

### What if the simulation crashes?
 
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

## Going further...
You can try out the automatically created coarse grain model in a more applied research, like simulating it with a transmembrane protein.

# Simulation with Adenosine 2 receptor embedded in POPC membrane

First, let's create a system with the protein embedded in the POPC membrane, with ligand (here it would be caffeine) in the solvent.  
We simulate without a priori, so that we could see if any interactions occur by themselves.

*  Go to repository with all needed files (remember to move the topology and coordinates files of the liand with you)
```bash

cd ${homedir}/Tutorial-Simulation-with-GPCR-datafiles/
cp ${homedir}/Tutorial-Parametrization-datafiles/CAFF* .
```

*   Add 10 molecules of ligand to already prepared protein-membrane-solvent system
     
```bash
gmx_mpi insert-molecules -f 3rfm_popc.gro -ci CAFF.gro -nmol 10 -try 500 -o 3rfm_popc_CAFF.gro -replace W
```
<p align="center">
  <img src="./images/A2A-caff-binding.jpg" alt="Caffeine in A2A Protein" width="960">  
</p>
<p align="center">
  <em>Figure 2 | Visualisation of caffeine molecules with A2A receptor in POPC membrane</em>
</p>
    

*   Make necessary changes to the topology file, by recounting water beads and adding ligand molecules  

```bash
cp 3rfm_popc.top 3rfm_popc_CAFF.top
```
*   In the new topology just create  you have change the string ```LIGAND``` by the name of your molecule.
    In this example, replace `LIGAND` with `CAFF`

```bash
sed -i "s/LIGAND/CAFF/g" 3rfm_popc_CAFF.top
```
    
*   Then, determine the number of sodium ions, chloride ions, and water molecules in the newly created structure file, either manually or by using the following small script:
```bash
solvent_lines=$(grep W 3rfm_popc_CAFF.gro | wc -l)
solvent_molecules=$((solvent_lines - 1))
NA_molecules=$(grep NA 3rfm_popc_CAFF.gro | wc -l)
CL_molecules=$(grep CL 3rfm_popc_CAFF.gro | wc -l)

echo "W              ${solvent_molecules}" >> 3rfm_popc_CAFF.top
echo "NA             ${NA_molecules}" >> 3rfm_popc_CAFF.top
echo "CL             ${CL_molecules}" >> 3rfm_popc_CAFF.top
echo "CAFF            10" >> 3rfm_popc_CAFF.top
```

*   create index file for handling NPT and NVT for distinct groups of molecules in the system
     
```bash
{
    echo "del 2-18"  
    echo "r W | r ION | r CAFF"  
    echo "name 2 Solvent"
    echo "r POPC"
    echo "name 3 Bilayer"
    echo "1 | r TW"
    echo "q"
    } > index-selection.txt
```
```bash    
    gmx_mpi make_ndx -f 3rfm_popc_CAFF.gro -o 3rfm_popc_CAFF.ndx < index-selection.txt
```

With system ready, verify if you have all needed input files : topology files, mdp files with GROMACS parameters, etc.
 
Launch minimization, 4 steps of equilibration where at each step we increase the size of time step, and production of 2 microseconds.

* __Minimization__
```bash  
gmx_mpi grompp -f min-A2A-lig.mdp -c 3rfm_popc_CAFF.gro -r 3rfm_popc_CAFF.gro -p 3rfm_popc_CAFF.top -n 3rfm_popc_CAFF.ndx -o 3rfm_popc_CAFF_min.tpr -maxwarn 2
gmx_mpi mdrun -deffnm 3rfm_popc_CAFF_min -v
```
* __4 steps of equilibration where at each step we increase the size of time step__
```bash      
## equilibration 1
gmx_mpi grompp -f eq0-A2A-lig.mdp -c 3rfm_popc_CAFF_min.gro -r 3rfm_popc_CAFF.gro -p 3rfm_popc_CAFF.top -n 3rfm_popc_CAFF.ndx -o 3rfm_popc_CAFF_eq0.tpr -maxwarn 3
gmx_mpi mdrun -deffnm 3rfm_popc_CAFF_eq0 -v
## equilibration 2
gmx_mpi grompp -f eq1-A2A-lig.mdp -c 3rfm_popc_CAFF_eq0.gro -r 3rfm_popc_CAFF.gro -p 3rfm_popc_CAFF.top -n 3rfm_popc_CAFF.ndx -o 3rfm_popc_CAFF_eq1.tpr -maxwarn 3
gmx_mpi mdrun -deffnm 3rfm_popc_CAFF_eq1 -v
## equilibration 3    
gmx_mpi grompp -f eq2-A2A-lig.mdp -c 3rfm_popc_CAFF_eq1.gro -r 3rfm_popc_CAFF.gro -p 3rfm_popc_CAFF.top -n 3rfm_popc_CAFF.ndx -o 3rfm_popc_CAFF_eq2.tpr -maxwarn 3
gmx_mpi mdrun -deffnm 3rfm_popc_CAFF_eq2 -v
## equilibration 4     
gmx_mpi grompp -f eq3-A2A-lig.mdp -c 3rfm_popc_CAFF_eq2.gro -r 3rfm_popc_CAFF.gro -p 3rfm_popc_CAFF.top -n 3rfm_popc_CAFF.ndx -o 3rfm_popc_CAFF_eq3.tpr -maxwarn 3 
gmx_mpi mdrun -deffnm 3rfm_popc_CAFF_eq3 -v
```
* __Production of 2 microseconds__
```bash  
gmx_mpi grompp -f md-A2A-lig.mdp -c 3rfm_popc_CAFF_eq3.gro -r 3rfm_popc_CAFF.gro -p 3rfm_popc_CAFF.top -n 3rfm_popc_CAFF.ndx -o 3rfm_popc_CAFF_md.tpr -maxwarn 3
gmx_mpi mdrun -deffnm 3rfm_popc_CAFF_md -v -cpi 3rfm_popc_CAFF_md.cpt -noappend
```

## Center the system around protein with GROMACS commands 
```bash
gmx_mpi trjconv -s 3rfm_popc_CAFF_md.tpr -f 3rfm_popc_CAFF_md.part0001.xtc -o 3rfm_popc_CAFF_md_centered.xtc -pbc mol -center
```


# Visualization of the simulation with VMD

Create pdb file for pretty visualisation of bonds
```bash
echo 0 | gmx_mpi trjconv -f 3rfm_popc_CAFF_md.part0001.gro -s 3rfm_popc_CAFF_md.tpr -conect -o 3rfm_popc_CAFF_md-conect.pdb -pbc whole

sed -i '/ENDMDL/d'  3rfm_popc_CAFF_md-conect.pdb
```

Visualize the system with VMD by loading the trajectory
```bash
    vmd  3rfm_popc_CAFF_md-conect.pdb 3rfm_popc_CAFF_md_centered.xtc 
```

### Commands in VMD
 
focus view on protein's backbone
 

    Extensions -> Analysis -> RMSD Trajectory Tool type "type BB" and click ALIGN on Top reference mol (by default)



Display settings for better view
 

    Display -> Orthographic Display -> check Antialiasing only Display -> Axes -> Off Display -> Rendermode -> GLSL

Show components of interest - protein backbone, lipid heads and ligand molecules
 

    Graphics -> Representations ...
    Create Rep -> type BB -> Drawing Method -> VMD (Sphere Scale 0.4) -> Coloring Method -> ResType
    Create Rep -> type BB -> Drawing Method -> DynamicBonds (Distance Cutoff 4.6 ; Bond Radius 0.6) -> Coloring Method -> ResType
    Create Rep -> type PO4 -> Drawing Method -> VMD (Sphere Scale 1) -> Coloring Method -> ColorID -> 6 (Silver)
    Create Rep -> resname CAFF -> Drawing Method -> VMD (Sphere Scale 1) -> Coloring Method -> ColorID -> 13(Mauve)

Change Background
 

    Graphics -> Colors... -> Display -> Background -> 8 (white)

Enhance representation with skin settings
 

    Graphics -> Materials -> Opaque Ambient 0.5 Diffuse 0.75 Opacity 0.32 Outline 1.5 OutlineWidth 0.5

### Some quantitative analysis in VMD
 
VolMap - creates volumetric maps based on the molecular data.  We will use the density mode, which creates a map of the weighted atomic density at each gridpoint, calculated with a normalized gaussian distribution. For more information, see [VMD documentation](https://www.ks.uiuc.edu/Research/vmd/vmd-1.9.1/ug/node153.html).
 

    Extensions -> Analysis -> VolMap Tool ; selection: resname CAFF ; volmap type: density ; resolution: 1.0 A ; atom size: 1.0 x radius ; weights: mass ; check compute for all frames, and combine using avg ; click Create Map

### References
[1](https://www.nature.com/articles/s41592-021-01098-3) Souza, P.C.T., Alessandri, R., Barnoud, J. et al. Martini 3: a general purpose force field for coarse-grained molecular dynamics. Nat Methods 18, 382–388 (2021).
[2](https://doi.org/10.1002/adts.202100391) Alessandri, R., Barnoud, J., Gertsen, A.S., Patmanidis, I., de Vries, A.H., Souza, P.C.T. and Marrink, S.J. (2022), Martini 3 Coarse-Grained Force Field: Small Molecules. Adv. Theory Simul., 5: 2100391. 
[3](https://doi.org/10.1038/s41467-020-17437-5) Souza, P.C.T., Thallmair, S., Conflitti, P. et al. Protein–ligand binding with the coarse-grained Martini model. Nat Commun 11, 3714 (2020).
[4](https://doi.org/10.1016/0263-7855(96)00018-5) William Humphrey, Andrew Dalke, Klaus Schulten, VMD: Visual molecular dynamics, Journal of Molecular Graphics, Volume 14, Issue 1, 1996, Pages 33-38.