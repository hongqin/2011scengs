# Run BWA to map Hong Qiu data to S288C Genome
#
.DELETE_ON_ERROR:
ROOT_DIR?=/ndata/botlabseq/seqshare
include ${ROOT_DIR}/src/config.mk
include ${ROOT_DIR}/src/data_curation/botseq_convert2fastq.mk

REFERENCE_INDEX?=${ROOT_DIR}/reference_genomes/saccharomyces_cerevisiae_s288c_saccer3/saccharomyces_cerevisiae_s288c_saccer3.fasta
BWA_ALN_OPTIONS?=-t 2
BWA_SAMPE_OPTIONS?=

FASTQ_DIR?=${ROOT_DIR}/fastq
HONG_MAPPED_BAM_DIR=${ROOT_DIR}/hong_analysis/mapped_bam

HONG_READ1_FASTQ_FILES?=$(wildcard ${FASTQ_DIR}/3-*read-1.fastq.gz)
HONG_FASTQ_FILES?=$(wildcard ${FASTQ_DIR}/3-*.fastq.gz)
HONG_SAI_FILES=$(addprefix ${HONG_MAPPED_BAM_DIR}/, $(patsubst %.fastq.gz, %_aln_sa.sai, $(notdir ${HONG_FASTQ_FILES})))
HONG_SAM_FILES=$(addprefix ${HONG_MAPPED_BAM_DIR}/, $(patsubst %_read-1.fastq.gz,%_aln.sam,$(notdir ${HONG_READ1_FASTQ_FILES})))
HONG_BAM_FILES=$(addprefix ${HONG_MAPPED_BAM_DIR}/, $(patsubst %.sam,%.bam,$(notdir ${HONG_SAM_FILES})))
HONG_SORTEDBAM_FILES=$(addprefix ${HONG_MAPPED_BAM_DIR}/, $(patsubst %.bam,%_sorted.bam,$(notdir ${HONG_BAM_FILES})))
HONG_BAI_FILES=$(addprefix ${HONG_MAPPED_BAM_DIR}/, $(addsuffix .bai,$(notdir ${HONG_SORTEDBAM_FILES})))

.DEFAULT_GOAL:=hongall
hongall: ${HONG_BAI_FILES}

hongtest: ${HONG_MAPPED_BAM_DIR}/3-001_M1-2_lib1_aln_sorted.bam.bai

${HONG_MAPPED_BAM_DIR}:
	mkdir -p $@ 

.INTERMEDIATE: ${HONG_SAI_FILES}
${HONG_SAI_FILES}: ${HONG_MAPPED_BAM_DIR}/%_aln_sa.sai: ${FASTQ_DIR}/%.fastq.gz | ${HONG_MAPPED_BAM_DIR}
	${BWA_BIN} aln ${BWA_ALN_OPTIONS} ${REFERENCE_INDEX} $< > $@

space :=
space +=
.INTERMEDIATE: ${HONG_BAM_FILES}
${HONG_BAM_FILES}: ${HONG_MAPPED_BAM_DIR}/%_aln.bam: ${HONG_MAPPED_BAM_DIR}/%_read-1_aln_sa.sai ${HONG_MAPPED_BAM_DIR}/%_read-2_aln_sa.sai ${FASTQ_DIR}/%_read-1.fastq.gz ${FASTQ_DIR}/%_read-2.fastq.gz
	$(eval WORDLIST=$(subst _,$(space),$(notdir $@)))
	$(eval NUMWORDS=$(words ${WORDLIST}))
	$(eval ID=$(firstword ${WORDLIST}))
	$(eval LIBLIST=$(subst $(lastword ${WORDLIST}),,${WORDLIST}))
	$(eval LIB=$(lastword ${LIBLIST}))
	$(eval SAMPLE=$(subst $(space),_,$(strip $(subst $(lastword ${LIBLIST}),,$(wordlist 2,${NUMWORDS},$(filter-out LTE,${LIBLIST}))))))
	${BWA_BIN} sampe ${BWA_SAMPE_OPTIONS} -r '@RG\tID:${ID}_${LIB}\tLB:${LIB}\tSM:${SAMPLE}' ${REFERENCE_INDEX} $^ | ${SAMTOOLS_BIN} view -bS - > $@

${HONG_SORTEDBAM_FILES}: ${HONG_MAPPED_BAM_DIR}/%_sorted.bam: ${HONG_MAPPED_BAM_DIR}/%.bam
	java -Xmx2g -jar ${PICARD_DIR}/SortSam.jar VALIDATION_STRINGENCY=LENIENT INPUT=$< OUTPUT=${HONG_MAPPED_BAM_DIR}/$*_sorted.bam SORT_ORDER=coordinate

${HONG_BAI_FILES}: ${HONG_MAPPED_BAM_DIR}/%.bai: ${HONG_MAPPED_BAM_DIR}/%
	${SAMTOOLS_BIN} index $<
