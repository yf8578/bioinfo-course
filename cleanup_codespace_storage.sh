#!/usr/bin/env bash
set -euo pipefail

# Clean files that are safe to regenerate in a GitHub Codespace.
# By default this keeps the downloaded reference files under 03_rnaseq_upstream/ref.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "[INFO] Disk usage before cleanup:"
df -h .

rm -rf .download_rnaseq_ref
rm -f Miniforge3-*.sh

if command -v conda >/dev/null 2>&1; then
  conda clean -afy || true
fi

rm -rf 03_rnaseq_upstream/sim_case_control/pipeline_result

if [ "${REMOVE_RNASEQ_REF:-0}" = "1" ]; then
  rm -rf 03_rnaseq_upstream/ref/hg38.fa \
         03_rnaseq_upstream/ref/hg38.refGene.gtf \
         03_rnaseq_upstream/ref/hg38.refGene.gtf.gz \
         03_rnaseq_upstream/ref/hisat2_index
fi

echo "[INFO] Disk usage after cleanup:"
df -h .

echo "[INFO] Largest course directories:"
du -sh . 00_docs 01_linux_shell 02_qc_fastqc 03_rnaseq_upstream 04_rnaseq_matrix 05_matrixeqtl 2>/dev/null | sort -h
