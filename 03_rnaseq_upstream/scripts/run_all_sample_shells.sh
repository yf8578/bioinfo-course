#!/usr/bin/env bash
set -euo pipefail

SHELL_DIR=$1

if [ ! -d "${SHELL_DIR}" ]; then
    echo "[ERROR] shell directory not found: ${SHELL_DIR}"
    exit 1
fi

N=$(find "${SHELL_DIR}" -name "*.run.sh" | wc -l)

echo "[INFO] Shell directory: ${SHELL_DIR}"
echo "[INFO] Number of sample scripts: ${N}"

if [ "${N}" -eq 0 ]; then
    echo "[ERROR] No *.run.sh found in ${SHELL_DIR}"
    exit 1
fi

for sh in $(find "${SHELL_DIR}" -name "*.run.sh" | sort)
do
    echo "============================================================"
    echo "[INFO] Running: ${sh}"
    echo "[INFO] Start time: $(date)"
    echo "============================================================"

    bash "${sh}"

    echo "============================================================"
    echo "[INFO] Finished: ${sh}"
    echo "[INFO] End time: $(date)"
    echo "============================================================"
done

echo "[INFO] All sample scripts finished."
