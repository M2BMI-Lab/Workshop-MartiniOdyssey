#!/bin/bash
# script by Magdalena Szczuka
### use : ./commands.sh molname

#source /usr/local/gromacs/bin/gmx
source /opt/gromacs/bin/GMXRC
mol=$1

#############################
##### CREATE SIMULATION #####

#### create ${mol} molecule ####
#python -m auto_martini --smi "Cn1cnc2n(C)c(=O)n(C)c(=O)c8" --mol ${mol}

#### add molecule ####
gmx insert-molecules -f 3rfm_popc.gro -ci ${mol}.gro -nmol 10 -try 500 -o 3rfm_popc_${mol}.gro -replace W

cp 3rfm_popc.top 3rfm_popc_${mol}.top
sed -i s"/molname/${mol}/" 3rfm_popc_${mol}.top

solvent_lines=$(grep W 3rfm_popc_${mol}.gro | wc -l)
solvent_molecules=$((solvent_lines - 1))
NA_molecules=$(grep NA 3rfm_popc_${mol}.gro | wc -l)
CL_molecules=$(grep CL 3rfm_popc_${mol}.gro | wc -l)

echo "W              ${solvent_molecules}" >> 3rfm_popc_${mol}.top
echo "NA             ${NA_molecules}" >> 3rfm_popc_${mol}.top
echo "CL             ${CL_molecules}" >> 3rfm_popc_${mol}.top
echo "${mol}            10" >> 3rfm_popc_${mol}.top

#### create index file ###
                    {
                        echo "del 2-18"
                        echo "r W | r ION | r ${mol:0:4}"
                        echo "name 2 Solvent"
                        echo "r POPC"
                        echo "name 3 Bilayer"
                        echo "1 | r TW"
                        echo "q"
                    } > index-selection.txt

gmx make_ndx -f 3rfm_popc_${mol}.gro -o 3rfm_popc_${mol}.ndx < index-selection.txt


#############################
##### LAUNCH SIMULATION #####

gmx grompp -f min-A2A-lig.mdp -c 3rfm_popc_${mol}.gro -r 3rfm_popc_${mol}.gro -p 3rfm_popc_${mol}.top -n 3rfm_popc_${mol}.ndx -o 3rfm_popc_${mol}_min.tpr -maxwarn 2

gmx mdrun -deffnm 3rfm_popc_${mol}_min -ntmpi 8  -v

gmx grompp -f eq0-A2A-lig.mdp -c 3rfm_popc_${mol}_min.gro -r 3rfm_popc_${mol}.gro -p 3rfm_popc_${mol}.top -n 3rfm_popc_${mol}.ndx -o 3rfm_popc_${mol}_eq0.tpr -maxwarn 3

gmx mdrun -deffnm 3rfm_popc_${mol}_eq0 -ntmpi 8  -v

gmx grompp -f eq1-A2A-lig.mdp -c 3rfm_popc_${mol}_eq0.gro -r 3rfm_popc_${mol}.gro -p 3rfm_popc_${mol}.top -n 3rfm_popc_${mol}.ndx -o 3rfm_popc_${mol}_eq1.tpr -maxwarn 3

gmx mdrun -deffnm 3rfm_popc_${mol}_eq1 -ntmpi 8  -v

gmx grompp -f eq2-A2A-lig.mdp -c 3rfm_popc_${mol}_eq1.gro -r 3rfm_popc_${mol}.gro -p 3rfm_popc_${mol}.top -n 3rfm_popc_${mol}.ndx -o 3rfm_popc_${mol}_eq2.tpr -maxwarn 3

gmx mdrun -deffnm 3rfm_popc_${mol}_eq2 -ntmpi 8  -v

gmx grompp -f eq3-A2A-lig.mdp -c 3rfm_popc_${mol}_eq2.gro -r 3rfm_popc_${mol}.gro -p 3rfm_popc_${mol}.top -n 3rfm_popc_${mol}.ndx -o 3rfm_popc_${mol}_eq3.tpr -maxwarn 3

gmx mdrun -deffnm 3rfm_popc_${mol}_eq3 -ntmpi 8  -v

### short simulation (2 ms) ###
gmx grompp -f md-A2A-lig.mdp -c 3rfm_popc_${mol}_eq3.gro -r 3rfm_popc_${mol}.gro -p 3rfm_popc_${mol}.top -n 3rfm_popc_${mol}.ndx -o 3rfm_popc_${mol}_md.tpr -maxwarn 3

gmx mdrun -deffnm 3rfm_popc_${mol}_md -ntmpi 8  -v -cpi 3rfm_popc_${mol}_md.cpt -noappend


#### center the system ####
echo -e "1\n0\n" |gmx trjconv -s 3rfm_popc_${mol}_md.tpr -f 3rfm_popc_${mol}_md.part0001.xtc -o 3rfm_popc_${mol}_md_centered.xtc -pbc mol -center

#### create pdb file for pretty visualisation of bonds ####
echo 0 | gmx trjconv -f 3rfm_popc_${mol}_md.part0001.gro -s 3rfm_popc_${mol}_md.tpr -conect -o 3rfm_popc_${mol}_md-conect.pdb -pbc whole

sed -i '/ENDMDL/d'  3rfm_popc_${mol}_md-conect.pdb
