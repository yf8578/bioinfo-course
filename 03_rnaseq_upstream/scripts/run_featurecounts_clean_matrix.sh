#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Run featureCounts and output a clean gene count matrix only
#
# Usage:
#   bash run_featurecounts_clean_matrix.sh output_dir
#
# Input:
#   output_dir/02_hisat2/*/*.sorted.bam
#
# Output:
#   output_dir/03_featureCounts/gene_counts.clean_matrix.tsv
#
# Matrix format:
#   Geneid    sample1    sample2    sample3 ...
# ============================================================

OUTDIR=$1

THREADS="${THREADS:-2}"

GTF_GZ="${GTF_GZ:-ref/hg38.refGene.gtf.gz}"

ALIGN_DIR="${OUTDIR}/02_hisat2"
COUNT_DIR="${OUTDIR}/03_featureCounts"
LOG_DIR="${OUTDIR}/logs"
GTF="${COUNT_DIR}/hg38.refGene.gtf"

mkdir -p "${COUNT_DIR}" "${LOG_DIR}"

# -----------------------------
# 1. Prepare GTF
# -----------------------------

if [ -f "${GTF_GZ}" ]; then
    echo "[INFO] Decompressing GTF into ${COUNT_DIR}..."
    gunzip -c "${GTF_GZ}" > "${GTF}"
elif [ ! -f "${GTF}" ]; then
    echo "[ERROR] GTF.gz not found: ${GTF_GZ}"
    exit 1
fi

# -----------------------------
# 2. Check software
# -----------------------------

if ! command -v featureCounts >/dev/null 2>&1; then
    echo "[ERROR] featureCounts not found in PATH"
    exit 1
fi

if ! command -v python >/dev/null 2>&1; then
    echo "[ERROR] python not found in PATH"
    exit 1
fi

# -----------------------------
# 3. Collect BAM files
# -----------------------------

BAM_LIST="${COUNT_DIR}/bam.list"

find "${ALIGN_DIR}" -name "*.sorted.bam" | sort > "${BAM_LIST}"

N_BAM=$(wc -l < "${BAM_LIST}")

echo "[INFO] Number of BAM files found: ${N_BAM}"

if [ "${N_BAM}" -eq 0 ]; then
    echo "[ERROR] No sorted BAM files found in ${ALIGN_DIR}"
    exit 1
fi

cat "${BAM_LIST}"

# -----------------------------
# 4. Run featureCounts
# -----------------------------

TMP_COUNTS="${COUNT_DIR}/.featureCounts.tmp.txt"

echo "[INFO] Running featureCounts..."

featureCounts \
  -T "${THREADS}" \
  -p \
  -B \
  -C \
  -t exon \
  -g gene_id \
  -a "${GTF}" \
  -o "${TMP_COUNTS}" \
  $(cat "${BAM_LIST}") \
  > "${LOG_DIR}/featureCounts.log" 2>&1

echo "[INFO] featureCounts finished."

# -----------------------------
# 5. Generate clean matrix
# -----------------------------

cd "${COUNT_DIR}"

python - <<'PY'
import csv
from pathlib import Path

tmp_file = Path(".featureCounts.tmp.txt")
out_file = Path("gene_counts.clean_matrix.tsv")

annotation_cols = ["Geneid", "Chr", "Start", "End", "Strand", "Length"]
with tmp_file.open() as fh, out_file.open("w", newline="") as out:
    reader = csv.reader((line for line in fh if not line.startswith("#")), delimiter="\t")
    writer = csv.writer(out, delimiter="\t", lineterminator="\n")
    header = next(reader)
    count_indexes = [i for i, name in enumerate(header) if name not in annotation_cols]
    writer.writerow(["Geneid"] + [Path(header[i]).name.replace(".sorted.bam", "") for i in count_indexes])
    n = 0
    for row in reader:
        writer.writerow([row[0]] + [row[i] for i in count_indexes])
        n += 1

print("[INFO] Clean matrix generated:", out_file)
print("[INFO] Number of genes:", n)
PY

# 删除临时 featureCounts 原始输出，只保留干净矩阵
rm -f "${TMP_COUNTS}" "${TMP_COUNTS}.summary" "${GTF}"

echo "============================================================"
echo "[INFO] Done."
echo "[INFO] Clean matrix:"
echo "${COUNT_DIR}/gene_counts.clean_matrix.tsv"
echo "============================================================"
