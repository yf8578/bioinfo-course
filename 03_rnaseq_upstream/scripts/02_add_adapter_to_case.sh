#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COURSE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

FASTQ_DIR="${FASTQ_DIR:-${COURSE_DIR}/sim_case_control/fastq}"
KEEP_ORIGINAL_FASTQ="${KEEP_ORIGINAL_FASTQ:-0}"

R1_ADAPTER="AGATCGGAAGAGCACACGTCTGAACTCCAGTCA"
R2_ADAPTER="AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT"

cd "${FASTQ_DIR}"

for i in 1 2 3
do
    SAMPLE="CASE_${i}"

    echo "[INFO] Adding artificial adapter to ${SAMPLE}"

    gunzip -f "${SAMPLE}_R1.fq.gz"
    gunzip -f "${SAMPLE}_R2.fq.gz"

    cp "${SAMPLE}_R1.fq" "${SAMPLE}_R1.original.fq"
    cp "${SAMPLE}_R2.fq" "${SAMPLE}_R2.original.fq"

    # 每 4 条 read 中人为污染 1 条，保留前 116 bp + 34 bp adapter = 150 bp
    awk -v ADP="${R1_ADAPTER}" '{
      if (NR % 4 == 2) {
        if ((int(NR/4)) % 4 == 0) {
          print substr($0, 1, 116) ADP
        } else {
          print $0
        }
      } else if (NR % 4 == 0) {
        if ((int(NR/4)) % 4 == 0) {
          print substr($0, 1, 116) "IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
        } else {
          print $0
        }
      } else {
        print $0
      }
    }' "${SAMPLE}_R1.original.fq" > "${SAMPLE}_R1.fq"

    awk -v ADP="${R2_ADAPTER}" '{
      if (NR % 4 == 2) {
        if ((int(NR/4)) % 4 == 0) {
          print substr($0, 1, 116) ADP
        } else {
          print $0
        }
      } else if (NR % 4 == 0) {
        if ((int(NR/4)) % 4 == 0) {
          print substr($0, 1, 116) "IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
        } else {
          print $0
        }
      } else {
        print $0
      }
    }' "${SAMPLE}_R2.original.fq" > "${SAMPLE}_R2.fq"

    gzip -f "${SAMPLE}_R1.fq" "${SAMPLE}_R2.fq"

    if [ "${KEEP_ORIGINAL_FASTQ}" = "1" ]; then
        gzip -f "${SAMPLE}_R1.original.fq" "${SAMPLE}_R2.original.fq"
    else
        rm -f "${SAMPLE}_R1.original.fq" "${SAMPLE}_R2.original.fq"
    fi

done

echo "[INFO] Adapter contamination added to CASE samples."
