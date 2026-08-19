#!/usr/bin/env bash
set -euo pipefail

# One-command runner for the full RNA-seq upstream teaching workflow in GitHub Codespaces.
# It is storage-aware: no intermediate SAM files are written, clean FASTQ files are removed
# by default, and temporary download files are not kept on disk.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

THREADS="${THREADS:-2}"
export THREADS
export KEEP_CLEAN_FASTQ="${KEEP_CLEAN_FASTQ:-0}"

echo "============================================================"
echo "[INFO] Bioinfo course RNA-seq upstream workflow"
echo "[INFO] Root directory: ${ROOT_DIR}"
echo "[INFO] THREADS=${THREADS}"
echo "[INFO] KEEP_CLEAN_FASTQ=${KEEP_CLEAN_FASTQ}"
echo "============================================================"

echo "[INFO] Disk usage at start:"
df -h .

if [ "${SKIP_CLEANUP:-0}" != "1" ]; then
  echo "[INFO] Cleaning regenerable files before running..."
  bash cleanup_codespace_storage.sh
else
  echo "[INFO] Skip cleanup because SKIP_CLEANUP=1"
fi

if [ -f "${HOME}/miniforge3/etc/profile.d/conda.sh" ]; then
  # shellcheck disable=SC1091
  source "${HOME}/miniforge3/etc/profile.d/conda.sh"
elif command -v conda >/dev/null 2>&1; then
  eval "$(conda shell.bash hook)"
else
  echo "[ERROR] conda was not found."
  echo "[ERROR] Install Miniforge and create the bioinfo environment first, or run the setup commands in README section 1."
  exit 1
fi

if ! conda env list | awk '{print $1}' | grep -qx "bioinfo"; then
  echo "[ERROR] conda environment 'bioinfo' was not found."
  echo "[ERROR] Create it first with the commands in README section 1.2."
  exit 1
fi

conda activate bioinfo

echo "[INFO] Checking required tools..."
for tool in curl python3 fastp hisat2 samtools featureCounts; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "[ERROR] Required tool not found in PATH: $tool"
    exit 1
  fi
done

echo "[INFO] Downloading/checking reference files..."
bash download_rnaseq_ref.sh

cd 03_rnaseq_upstream

echo "[INFO] Checking sample list and FASTQ files..."
cat sim_case_control/sample.list

for fq in $(awk '{print $2"\n"$3}' sim_case_control/sample.list); do
  if [ ! -f "$fq" ]; then
    echo "[ERROR] FASTQ not found: $fq"
    exit 1
  fi
done

echo "[INFO] Generating sample-level shell scripts..."
bash scripts/make_sample_shells.sh \
  sim_case_control/sample.list \
  sim_case_control/pipeline_result

echo "[INFO] Running all sample-level shell scripts..."
bash scripts/run_all_sample_shells.sh \
  sim_case_control/pipeline_result/shell \
  2>&1 | tee sim_case_control/pipeline_result/run_all_samples.log

echo "[INFO] Running featureCounts and generating clean count matrix..."
bash scripts/run_featurecounts_clean_matrix.sh \
  sim_case_control/pipeline_result

echo "[INFO] Final output:"
ls -lh sim_case_control/pipeline_result/03_featureCounts/gene_counts.clean_matrix.tsv
head sim_case_control/pipeline_result/03_featureCounts/gene_counts.clean_matrix.tsv

cd "$ROOT_DIR"

echo "[INFO] Disk usage at end:"
df -h .
du -sh 03_rnaseq_upstream 03_rnaseq_upstream/sim_case_control/pipeline_result 2>/dev/null

echo "============================================================"
echo "[INFO] Done."
echo "[INFO] Clean matrix:"
echo "03_rnaseq_upstream/sim_case_control/pipeline_result/03_featureCounts/gene_counts.clean_matrix.tsv"
echo "============================================================"
