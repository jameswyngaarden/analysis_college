#!/usr/bin/env bash

maindir="/data/projects/STUDIES/social_doors_college_jw/analysis_college"
TASK=srDoorsa
cd $maindir

sub=$1
run=$2
ppi=$3 # 0 for activation, otherwise name of the roi
sm=$4
dtype=dctAROMAnonaggr

# TODO: 
# 2) add logging option if running through a second time
# 4) execute with datalad run -m "message" --input "derivatives/fmriprep/*" --output "derivatives/fsl/*" "bash run_L1stats.sh"

# set input and output and adjust for ppi

MAINOUTPUT=${maindir}/derivatives/fsl/results/lowerLv_results/sub-${sub}
DATA=/data/projects/STUDIES/social_doors_college/derivatives/fmriprep/sub-${sub}/func/sub-${sub}_task-${TASK}_run-${run}_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz
CONFOUNDEVS=${maindir}/derivatives/fsl/confounds/sub-${sub}/sub-${sub}_task-${TASK}_run-${run}_desc-fslConfounds.tsv

DESC=${maindir}/behavior/EVfiles/${sub}/doors/run-0${run}_a_decision.txt

LEFT=${maindir}/behavior/EVfiles/${sub}/doors/run-0${run}_a_Ldecision.txt

RIGHT=${maindir}/behavior/EVfiles/${sub}/doors/run-0${run}_a_Rdecision.txt

INS=${maindir}/behavior/EVfiles/${sub}/doors/run-0${run}_a_instruction.txt

COR=${maindir}/behavior/EVfiles/${sub}/doors/run-0${run}_a_correct.txt

INC=${maindir}/behavior/EVfiles/${sub}/doors/run-0${run}_a_incorrect.txt

CSF=${maindir}/behavior/EVfiles/${sub}/csf.txt

LENGTH=$5


echo $maindir



if [ "$ppi" == "0" ]; then
	TYPE=act
	OUTPUT=${MAINOUTPUT}/L1_task-${TASK}_model-01_type-${TYPE}_run-0${run}_sm-${sm}_variant-${dtype}
else
	TYPE=ppi
	OUTPUT=${MAINOUTPUT}/L1_task-${TASK}_model-01_type-${TYPE}_seed-${ppi}_run-0${run}_sm-${sm}_variant-${dtype}
fi

# check for output and skip existing
if [ -e ${OUTPUT}.feat/cluster_mask_zstat1.nii.gz ]; then
	exit
else
   echo "missing: $OUTPUT " >> ${maindir}/re-runL1.log
	rm -rf ${OUTPUT}.feat
fi

ITEMPLATE=${maindir}/code/templates/design.fsf
OTEMPLATE=${MAINOUTPUT}/L1_task-${TASK}_model-01_seed-${ppi}_run-0${run}_variant-${dtype}.fsf

if [ "$ppi" == "0" ]; then
	sed -e 's@OUTPUT@'$OUTPUT'@g' \
	-e 's@DATA@'$DATA'@g' \
	-e 's@EVDIR@'$EVDIR'@g' \
	-e 's@DESC@'$DESC'@g' \
	-e 's@LEFT@'$LEFT'@g' \
	-e 's@RIGHT@'$RIGHT'@g' \
	-e 's@INS@'$INS'@g' \
	-e 's@COR@'$COR'@g' \
	-e 's@INC@'$INC'@g' \
	-e 's@SMOOTH@'$sm'@g' \
	-e 's@CONFOUNDEVS@'$CONFOUNDEVS'@g' \
	-e 's@LENGTH@'$LENGTH'@g' \
	<$ITEMPLATE> $OTEMPLATE
else
	PHYS=${MAINOUTPUT}/ts_task-${TASK}_mask-${ppi}_run-0${run}.txt
	MASK=/data/projects/istart-socDoors/code/masks/${ppi}_func.nii.gz
	fslmeants -i $DATA -o $PHYS -m $MASK
	sed -e 's@OUTPUT@'$OUTPUT'@g' \
	-e 's@DATA@'$DATA'@g' \
	-e 's@EVDIR@'$EVDIR'@g' \
	-e 's@PHYS@'$PHYS'@g' \
	-e 's@SMOOTH@'$sm'@g' \
	-e 's@CONFOUNDEVS@'$CONFOUNDEVS'@g' \
	<$ITEMPLATE> $OTEMPLATE
fi

# runs feat on output template
feat $OTEMPLATE

# fix registration as per NeuroStars post:
# https://neurostars.org/t/performing-full-glm-analysis-with-fsl-on-the-bold-images-preprocessed-by-fmriprep-without-re-registering-the-data-to-the-mni-space/784/3
mkdir -p ${OUTPUT}.feat/reg
ln -s $FSLDIR/etc/flirtsch/ident.mat ${OUTPUT}.feat/reg/example_func2standard.mat
ln -s $FSLDIR/etc/flirtsch/ident.mat ${OUTPUT}.feat/reg/standard2example_func.mat
ln -s ${OUTPUT}.feat/mean_func.nii.gz ${OUTPUT}.feat/reg/standard.nii.gz

# delete unused files
rm -rf ${OUTPUT}.feat/stats/res4d.nii.gz
rm -rf ${OUTPUT}.feat/stats/corrections.nii.gz
rm -rf ${OUTPUT}.feat/stats/threshac1.nii.gz

if [ ! "$ppi" == "0" ]; then
	rm -rf ${OUTPUT}.feat/filtered_func_data.nii.gz
fi

