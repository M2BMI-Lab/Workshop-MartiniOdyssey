#!/bin/bash

source /usr/local/gromacs/bin/GMXRC

#### TO DO BEFORE:
# check:
# 1. system.top
# 2. em-Wat-lig.mdp, eq-Wat-lig.mdp, run-Wat-lig.mdp

#  Needs 1 x SOLUTE MOLECULE file and a SOLVENT BOX file
#  e.g.
#$ ./prepare_CG_1mol_system.sh MOL box.gro W 1

#  Check if the files have been passed to the script
solute_name="$1"
solvent_box="$2"
solvent_name="$3"
solvent_atoms="$4"
size_1=${#solute}
size_2=${#solvent_box}
size_3=${#solvent_name}
size_4=${#solvent_atoms}

cp system_init.top system.top

gmx solvate -cp ${solute_name}.gro -cs ${solvent_box} -o initial_${solute_name}.gro -box 5 5 5 # NEW!

solvent_lines=$(grep $solvent_name initial_${solute_name}.gro | wc -l)
solvent_molecules=$(expr $solvent_lines / $solvent_atoms )
echo "$solute_name               1" >> system.top
echo "$solvent_name               $solvent_molecules" >> system.top
sed -i'' -e  s"/xxx.itp/${solute_name}.itp/"g system.top
sed -i'' -e  s"/ABC/${solute_name}/"g system.top

gmx grompp -p system.top -c initial_${solute_name}.gro -f martini_em.mdp  -o 1-min_${solute_name}.tpr -po 1-min.mdp  -maxwarn 3
gmx mdrun -v -deffnm 1-min_${solute_name} -nt 8 >> mdrun.log 2>&1

gmx grompp -p system.top -c 1-min_${solute_name}.gro   -f martini_eq.mdp  -o 2-eq_${solute_name}.tpr  -po 2-eq.mdp  -maxwarn 3
gmx mdrun -v -deffnm 2-eq_${solute_name}  -nt 8  >> mdrun.log 2>&1

gmx grompp -p system.top -c 2-eq_${solute_name}.gro    -f martini_run.mdp -o 3-run_${solute_name}.tpr -po 3-run.mdp  -maxwarn 3
gmx mdrun -v -deffnm 3-run_${solute_name}  -nt 12

echo -e "2\n0\n" | gmx trjconv -f 3-run_${solute_name}.xtc -s 3-run_${solute_name}.tpr -o 3-run_${solute_name}_centered.xtc -center -pbc mol
#python3 ../trjconv.py -r ${solute_name}

