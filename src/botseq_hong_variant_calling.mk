# Run freebayes on bam files
#
.DELETE_ON_ERROR:

ROOT_DIR?=/ndata/botlabseq/seqshare
include ${ROOT_DIR}/src/config.mk
include ${ROOT_DIR}/src/hong_analysis/botseq_hong_mapping.mk

REFERENCE_INDEX?=${ROOT_DIR}/reference_genomes/saccharomyces_cerevisiae_s288c_saccer3/saccharomyces_cerevisiae_s288c_saccer3.fasta

HONG_VCF_DIR=${ROOT_DIR}/hong_analysis/vcf

HONG_VCF_FILES=$(addprefix ${HONG_VCF_DIR}/, $(patsubst %.bam,%.vcf,$(notdir ${HONG_SORTEDBAM_FILES})))

HONG_VCF_GZ_FILES=$(addsuffix .gz, ${HONG_VCF_FILES})
HONG_VCF_INDEX_FILES=$(addsuffix .tbi, ${HONG_VCF_GZ_FILES})

.DEFAULT_GOAL:=hongvcall
hongvcall: ${HONG_VCF_INDEX_FILES}

${HONG_VCF_DIR}:
	mkdir ${HONG_VCF_DIR}

.SECONDARY: ${HONG_VCF_FILES}
${HONG_VCF_FILES}: ${HONG_VCF_DIR}/%.vcf: ${HONG_MAPPED_BAM_DIR}/%.bam | ${HONG_VCF_DIR}
	${FREEBAYES} --fasta ${REFERENCE_INDEX} --pooled $< > $@

${HONG_VCF_GZ_FILES}: ${HONG_VCF_DIR}/%.gz: ${HONG_VCF_DIR}/% 
	${BGZIP} $<

${HONG_VCF_INDEX_FILES}: ${HONG_VCF_DIR}/%.tbi: ${HONG_VCF_DIR}/% 
	${TABIX} $<

hongvctest:
	@echo ${HONG_VCF_INDEX_FILES}
