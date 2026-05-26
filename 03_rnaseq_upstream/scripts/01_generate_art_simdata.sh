#!/usr/bin/env bash
set -euo pipefail

# =========================
# 0. Basic settings
# =========================

REF="/data/Public/DCS_Reference_hg38/reference/hg38.fa"

WORKDIR="/data/work/sim_case_control"
FASTQ_DIR="${WORKDIR}/fastq"
SCRIPT_DIR="${WORKDIR}/scripts"
LOG_DIR="${WORKDIR}/logs"

mkdir -p "${FASTQ_DIR}" "${SCRIPT_DIR}" "${LOG_DIR}"

cd "${FASTQ_DIR}"

# =========================
# 1. Check software and reference
# =========================

echo "[INFO] Checking art_illumina..."
which art_illumina

echo "[INFO] Checking reference..."
if [ ! -f "${REF}" ]; then
    echo "[ERROR] Reference not found: ${REF}"
    exit 1
fi

# =========================
# 2. Simulation parameters
# =========================

SEQ_SYS="HS25"     # HiSeq 2500
READ_LEN=150      # PE150
MEAN_FRAG=350     # mean fragment length
SD_FRAG=50        # fragment length SD

# 为了教学，不要覆盖度太高，否则 FASTQ 会很大
# control 和 case 可以设置略有不同 coverage，用于模拟数据量差异
CTRL_COV=0.001
CASE_COV=0.0012

# =========================
# 3. Generate 3 control samples
# =========================

for i in 1 2 3
do
    SAMPLE="CTRL_${i}"
    SEED=$((1000 + i))

    echo "[INFO] Generating ${SAMPLE}"

    art_illumina \
        -ss "${SEQ_SYS}" \
        -p \
        -i "${REF}" \
        -l "${READ_LEN}" \
        -f "${CTRL_COV}" \
        -m "${MEAN_FRAG}" \
        -s "${SD_FRAG}" \
        -rs "${SEED}" \
        -o "${SAMPLE}_"

    mv "${SAMPLE}_1.fq" "${SAMPLE}_R1.fq"
    mv "${SAMPLE}_2.fq" "${SAMPLE}_R2.fq"

done

# =========================
# 4. Generate 3 case samples
# =========================

for i in 1 2 3
do
    SAMPLE="CASE_${i}"
    SEED=$((2000 + i))

    echo "[INFO] Generating ${SAMPLE}"

    art_illumina \
        -ss "${SEQ_SYS}" \
        -p \
        -i "${REF}" \
        -l "${READ_LEN}" \
        -f "${CASE_COV}" \
        -m "${MEAN_FRAG}" \
        -s "${SD_FRAG}" \
        -rs "${SEED}" \
        -o "${SAMPLE}_"

    mv "${SAMPLE}_1.fq" "${SAMPLE}_R1.fq"
    mv "${SAMPLE}_2.fq" "${SAMPLE}_R2.fq"

done

# =========================
# 5. Compress FASTQ files
# =========================

echo "[INFO] Compressing FASTQ files..."
gzip -f *.fq

# =========================
# 6. Generate sample.list
# 格式：sample_id fq1 fq2
# 这个格式与你上传的流程脚本一致
# =========================

cd "${WORKDIR}"

cat > sample.list <<EOF2
CTRL_1 ${FASTQ_DIR}/CTRL_1_R1.fq.gz ${FASTQ_DIR}/CTRL_1_R2.fq.gz
CTRL_2 ${FASTQ_DIR}/CTRL_2_R1.fq.gz ${FASTQ_DIR}/CTRL_2_R2.fq.gz
CTRL_3 ${FASTQ_DIR}/CTRL_3_R1.fq.gz ${FASTQ_DIR}/CTRL_3_R2.fq.gz
CASE_1 ${FASTQ_DIR}/CASE_1_R1.fq.gz ${FASTQ_DIR}/CASE_1_R2.fq.gz
CASE_2 ${FASTQ_DIR}/CASE_2_R1.fq.gz ${FASTQ_DIR}/CASE_2_R2.fq.gz
CASE_3 ${FASTQ_DIR}/CASE_3_R1.fq.gz ${FASTQ_DIR}/CASE_3_R2.fq.gz
EOF2

# =========================
# 7. Generate group file
# =========================

cat > group.txt <<EOF2
sample	group
CTRL_1	control
CTRL_2	control
CTRL_3	control
CASE_1	case
CASE_2	case
CASE_3	case
EOF2

echo "[INFO] Done."
echo "[INFO] FASTQ files: ${FASTQ_DIR}"
echo "[INFO] Sample list: ${WORKDIR}/sample.list"
echo "[INFO] Group file: ${WORKDIR}/group.txt"
