#!/bin/bash

DIRECTORY=$(cd `dirname $0` && pwd)

ROOT_DIR=$(cd "${DIRECTORY}/../../../" && pwd)
STRAINS_FILE=${ROOT_DIR}/Sequencing_Consortium_Strains-MASTER.txt
FASTQ_DIR=${ROOT_DIR}/fastq
ORIGINAL_BAM_DIR=${ROOT_DIR}/original_bam

function process_batch {
    HONG_FASTQ_FILES=""
    ORIGINAL_BAM_FILES=""
    for strain in "${strain_batch[@]}"; do
        HONG_FASTQ_FILES+=`find "${FASTQ_DIR}" -name "$strain*.fastq.gz" | xargs echo`
        HONG_FASTQ_FILES+=" "
        HONG_ORIGINAL_BAM_FILES+=`find "${ORIGINAL_BAM_DIR}" -name "$strain*.bam" | xargs echo`
        HONG_ORIGINAL_BAM_FILES+=" "
    done
    export HONG_FASTQ_FILES
    echo $HONG_FASTQ_FILES
    export HONG_ORIGINAL_BAM_FILES
    echo $HONG_ORIGINAL_BAM_FILES
    echo "make -n -f ${DIRECTORY}/botseq_hong_mapping.mk -j 5"
    echo ""
}
 
strain_list=()
while IFS=$'\t' read -r -a fields
do
    genus_species=${fields[1]}
    individual_name=${fields[4]}
    number=${fields[11]}
    if [[ $number == 3-* ]]; then
        echo "$number $individual_name $genus_species - SELECTED"
        strain_list+=("$number")
    fi
done < $STRAINS_FILE

strain_batch=()
i=0
for strain in "${strain_list[@]}"; do
    strain_batch+=("$strain")
    i=$i+1
    if [[ $i -eq 10 ]]; then
        echo ${strain_batch[@]}
        process_batch
        strain_batch=()
        i=0
    fi
done
echo ${strain_batch[@]}
process_batch

exit

#${DIRECTORY}/botseq_lte_merge_bam.py > ${DIRECTORY}/botseq_combine_bam.mk
#make -f ${DIRECTORY}/botseq_combine_bam.mk -j 4

