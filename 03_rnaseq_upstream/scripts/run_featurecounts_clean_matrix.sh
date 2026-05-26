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

THREADS=8

GTF_GZ="/data/work/hg38.refGene.gtf.gz"
GTF="/data/work/hg38.refGene.gtf"

ALIGN_DIR="${OUTDIR}/02_hisat2"
COUNT_DIR="${OUTDIR}/03_featureCounts"
LOG_DIR="${OUTDIR}/logs"

mkdir -p "${COUNT_DIR}" "${LOG_DIR}"

# -----------------------------
# 1. Prepare GTF
# -----------------------------

if [ ! -f "${GTF}" ]; then
    if [ -f "${GTF_GZ}" ]; then
        echo "[INFO] Decompressing GTF..."
        gunzip -c "${GTF_GZ}" > "${GTF}"
    else
        echo "[ERROR] GTF not found: ${GTF}"
        echo "[ERROR] GTF.gz also not found: ${GTF_GZ}"
        exit 1
    fi
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
import pandas as pd
from pathlib import Path

tmp_file = Path(".featureCounts.tmp.txt")
out_file = Path("gene_counts.clean_matrix.tsv")

df = pd.read_csv(tmp_file, sep="\t", comment="#")

annotation_cols = ["Geneid", "Chr", "Start", "End", "Strand", "Length"]
count_cols = [c for c in df.columns if c not in annotation_cols]

clean = df[["Geneid"] + count_cols].copy()

# 将 BAM 路径列名转换为样本名
new_cols = ["Geneid"]
for c in count_cols:
    sample = Path(c).name.replace(".sorted.bam", "")
    new_cols.append(sample)

clean.columns = new_cols

# 只输出干净矩阵
clean.to_csv(out_file, sep="\t", index=False)

print("[INFO] Clean matrix generated:", out_file)
print("[INFO] Matrix shape:", clean.shape)
print(clean.head())
PY

# 删除临时 featureCounts 原始输出，只保留干净矩阵
rm -f "${TMP_COUNTS}" "${TMP_COUNTS}.summary"

echo "============================================================"
echo "[INFO] Done."
echo "[INFO] Clean matrix:"
echo "${COUNT_DIR}/gene_counts.clean_matrix.tsv"
echo "============================================================"

