#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Generate one analysis shell script for each paired-end sample
#
# Input:
#   sample.list
#
# sample.list format:
#   sample_id    read1.fq.gz    read2.fq.gz
#
# Usage:
#   bash make_sample_shells.sh sample.list output_dir
#
# Example:
#   bash make_sample_shells.sh \
#     /data/work/sim_case_control/sample.list \
#     /data/work/sim_case_control/pipeline_result
# ============================================================

SAMPLE_LIST=$1
OUTDIR=$2

THREADS=8

# Reference settings
HISAT2_INDEX="/data/work/ref/hisat2_index/hg38"

# Output directories
SHELL_DIR="${OUTDIR}/shell"
FASTP_DIR="${OUTDIR}/01_fastp"
ALIGN_DIR="${OUTDIR}/02_hisat2"
LOG_DIR="${OUTDIR}/logs"

mkdir -p \
  "${SHELL_DIR}" \
  "${FASTP_DIR}" \
  "${ALIGN_DIR}" \
  "${LOG_DIR}"

# Check sample list
if [ ! -f "${SAMPLE_LIST}" ]; then
    echo "[ERROR] sample.list not found: ${SAMPLE_LIST}"
    exit 1
fi

# Check HISAT2 index
if [ ! -f "${HISAT2_INDEX}.1.ht2" ] || \
   [ ! -f "${HISAT2_INDEX}.2.ht2" ] || \
   [ ! -f "${HISAT2_INDEX}.3.ht2" ] || \
   [ ! -f "${HISAT2_INDEX}.4.ht2" ] || \
   [ ! -f "${HISAT2_INDEX}.5.ht2" ] || \
   [ ! -f "${HISAT2_INDEX}.6.ht2" ] || \
   [ ! -f "${HISAT2_INDEX}.7.ht2" ] || \
   [ ! -f "${HISAT2_INDEX}.8.ht2" ]; then
    echo "[ERROR] HISAT2 index is incomplete: ${HISAT2_INDEX}"
    exit 1
fi

# Generate one shell per sample
while read -r SAMPLE FQ1 FQ2
do
    # skip empty lines
    [ -z "${SAMPLE}" ] && continue

    SAMPLE_FASTP_DIR="${FASTP_DIR}/${SAMPLE}"
    SAMPLE_ALIGN_DIR="${ALIGN_DIR}/${SAMPLE}"

    mkdir -p "${SAMPLE_FASTP_DIR}" "${SAMPLE_ALIGN_DIR}"

    SAMPLE_SH="${SHELL_DIR}/${SAMPLE}.run.sh"

    cat > "${SAMPLE_SH}" <<EOS
#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Sample-level upstream analysis
#
# Sample:
#   ${SAMPLE}
#
# Steps:
#   1. fastp adapter trimming / quality filtering
#   2. HISAT2 alignment
#   3. samtools SAM -> sorted BAM -> BAM index
# ============================================================

SAMPLE="${SAMPLE}"
FQ1="${FQ1}"
FQ2="${FQ2}"

THREADS=${THREADS}

HISAT2_INDEX="${HISAT2_INDEX}"

SAMPLE_FASTP_DIR="${SAMPLE_FASTP_DIR}"
SAMPLE_ALIGN_DIR="${SAMPLE_ALIGN_DIR}"
LOG_DIR="${LOG_DIR}"

mkdir -p "\${SAMPLE_FASTP_DIR}" "\${SAMPLE_ALIGN_DIR}" "\${LOG_DIR}"

echo "============================================================"
echo "[INFO] Start sample: \${SAMPLE}"
echo "[INFO] R1: \${FQ1}"
echo "[INFO] R2: \${FQ2}"
echo "[INFO] Start time: \$(date)"
echo "============================================================"

# -----------------------------
# Check input FASTQ
# -----------------------------

if [ ! -f "\${FQ1}" ]; then
    echo "[ERROR] R1 file not found: \${FQ1}"
    exit 1
fi

if [ ! -f "\${FQ2}" ]; then
    echo "[ERROR] R2 file not found: \${FQ2}"
    exit 1
fi

# -----------------------------
# Check software
# -----------------------------

for tool in fastp hisat2 samtools
do
    if ! command -v "\${tool}" >/dev/null 2>&1; then
        echo "[ERROR] \${tool} not found in PATH"
        exit 1
    fi
done

# -----------------------------
# Step 1. fastp
# -----------------------------

CLEAN_R1="\${SAMPLE_FASTP_DIR}/\${SAMPLE}.clean.R1.fq.gz"
CLEAN_R2="\${SAMPLE_FASTP_DIR}/\${SAMPLE}.clean.R2.fq.gz"

echo "[INFO] Step 1: fastp"

fastp \\
  -i "\${FQ1}" \\
  -I "\${FQ2}" \\
  -o "\${CLEAN_R1}" \\
  -O "\${CLEAN_R2}" \\
  --detect_adapter_for_pe \\
  --thread "\${THREADS}" \\
  --qualified_quality_phred 20 \\
  --unqualified_percent_limit 40 \\
  --length_required 30 \\
  --html "\${SAMPLE_FASTP_DIR}/\${SAMPLE}.fastp.html" \\
  --json "\${SAMPLE_FASTP_DIR}/\${SAMPLE}.fastp.json" \\
  > "\${LOG_DIR}/\${SAMPLE}.fastp.log" 2>&1

# -----------------------------
# Step 2. HISAT2 alignment
# -----------------------------

SAM="\${SAMPLE_ALIGN_DIR}/\${SAMPLE}.sam"
SORTED_BAM="\${SAMPLE_ALIGN_DIR}/\${SAMPLE}.sorted.bam"

echo "[INFO] Step 2: HISAT2"

hisat2 \\
  -p "\${THREADS}" \\
  -x "\${HISAT2_INDEX}" \\
  -1 "\${CLEAN_R1}" \\
  -2 "\${CLEAN_R2}" \\
  -S "\${SAM}" \\
  --summary-file "\${SAMPLE_ALIGN_DIR}/\${SAMPLE}.hisat2.summary.txt" \\
  > "\${LOG_DIR}/\${SAMPLE}.hisat2.log" 2>&1

# -----------------------------
# Step 3. SAM to sorted BAM
# -----------------------------

echo "[INFO] Step 3: samtools sort/index"

samtools view -@ "\${THREADS}" -bS "\${SAM}" | \\
  samtools sort -@ "\${THREADS}" -o "\${SORTED_BAM}"

samtools index "\${SORTED_BAM}"

rm -f "\${SAM}"

echo "============================================================"
echo "[INFO] Finished sample: \${SAMPLE}"
echo "[INFO] End time: \$(date)"
echo "[INFO] Output BAM: \${SORTED_BAM}"
echo "============================================================"

EOS

    chmod +x "${SAMPLE_SH}"

    echo "[INFO] Generated: ${SAMPLE_SH}"

done < "${SAMPLE_LIST}"

echo "============================================================"
echo "[INFO] All sample shell scripts generated."
echo "[INFO] Shell directory: ${SHELL_DIR}"
echo "============================================================"

