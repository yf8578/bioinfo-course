# 生物信息学入门课程：云平台实践教程

> 镜像内置课程数据目录：`/opt/bioinfo_course`  
> 学生实际操作目录：`/data/work/bioinfo_course`

本课程所有示例数据、参考文件、索引、脚本和 Notebook 均默认已经整理在：

```bash
/opt/bioinfo_course
```

上课或练习时，**第一步统一把课程数据从 `/opt` 复制到 `/data/work`**：

```bash
cd /data/work

rm -rf /data/work/bioinfo_course

cp -r /opt/bioinfo_course /data/work/bioinfo_course

cd /data/work/bioinfo_course

tree -L 2
```

后续所有命令均默认在 `/data/work/bioinfo_course` 下运行，不再重复说明数据路径。

---

# 0. 课程目录结构

```text
bioinfo_course/
├── 00_docs/
│   ├── bioinfo_course_tutorial.md
│   └── part1.md
├── 01_linux_shell/
│   ├── bash.sh
│   └── Linux/
├── 02_qc_fastqc/
│   ├── simdata/
│   └── qc_report/
├── 03_rnaseq_upstream/
│   ├── ref/
│   ├── scripts/
│   └── sim_case_control/
├── 04_rnaseq_matrix/
│   ├── 00_simdata.ipynb
│   ├── 01_RNA-seq_annotated.ipynb
│   ├── teaching_results/
│   └── teaching_figures/
└── 05_matrixeqtl/
    └── 01_MatrixEQTL_demo_notebook.ipynb
```

---

# 一、Linux 与 Shell 基础

## 1.1 基本命令练习

1. https://book.ncrnalab.org/teaching/part-i.-programming-skills/1.linux/1.1.linux-basic-command
2. https://www.runoob.com/linux/linux-command-manual.html

```bash
cd /data/work/bioinfo_course

pwd

ls

ls -lh

tree -L 2

du -sh *

df -h
```

常用命令：

```bash
pwd
ls
cd
mkdir
cp
mv
rm
head
tail
less
cat
grep
find
du
df
```

示例：

```bash
find . -name "*.fq" | head

find . -name "*.sh" | sort

du -sh 02_qc_fastqc 03_rnaseq_upstream
```

---

## 1.2 Shell 脚本练习
练习参考链接：
1. https://book.ncrnalab.org/teaching/part-i.-programming-skills/1.linux/1.3.linux-bash

进入 Shell 练习目录：

```bash
cd /data/work/bioinfo_course/01_linux_shell

ls -lh

less bash.sh

bash bash.sh
```

循环示例：

```bash
for file in ../02_qc_fastqc/simdata/*.fq
do
  echo "${file}"
done
```

---

# 二、下机数据质检质控：FastQC

本部分使用模拟 FASTQ 数据演示下机数据质量评估。数据包括一组原始模拟 reads，以及一组人为添加 adapter 的 reads，用于观察接头污染在 FastQC 报告中的表现。

## 2.1 进入质控目录

```bash
cd /data/work/bioinfo_course/02_qc_fastqc

tree
```

主要文件：

```text
simdata/sim_hg38_1.fq
simdata/sim_hg38_2.fq
simdata/sim_hg38_1.adapter.fq
simdata/sim_hg38_2.adapter.fq
```

---

## 2.2 查看 FASTQ 文件结构

```bash
head simdata/sim_hg38_1.fq
```

FASTQ 每条 read 由 4 行组成：

```text
第 1 行：read ID
第 2 行：碱基序列
第 3 行：+
第 4 行：碱基质量值
```

---

## 2.3 运行 FastQC

创建结果目录：

```bash
mkdir -p qc_report/fastqc_raw
```

对无 adapter 数据运行 FastQC：

```bash
fastqc \
  simdata/sim_hg38_1.fq \
  simdata/sim_hg38_2.fq \
  -o qc_report/fastqc_raw
```

对带 adapter 数据运行 FastQC：

```bash
fastqc \
  simdata/sim_hg38_1.adapter.fq \
  simdata/sim_hg38_2.adapter.fq \
  -o qc_report/fastqc_raw
```

查看结果：

```bash
ls -lh qc_report/fastqc_raw
```

输出文件包括：

```text
*_fastqc.html
*_fastqc.zip
```

重点观察：

```text
Basic Statistics
Per base sequence quality
Per sequence quality scores
Per base sequence content
Per sequence GC content
Sequence Length Distribution
Overrepresented sequences
Adapter Content
```

---

# 三、RNA-seq 上游流程：FASTQ 到干净表达矩阵

> 说明：本部分 FASTQ 是基于 hg38 全基因组模拟的 reads，更适合用于教学演示上游流程。它不是严格的 RNA-seq 模拟数据，因此最终 count matrix 不应用于解释真实疾病差异表达。

本部分流程：

```text
sample.list
↓
为每个样本生成独立 shell
↓
fastp 去接头与质量过滤
↓
HISAT2 比对
↓
samtools 生成 sorted BAM
↓
featureCounts 汇总所有 BAM
↓
输出干净表达矩阵 gene_counts.clean_matrix.tsv
```

---

## 3.1 进入 RNA-seq 上游流程目录

```bash
cd /data/work/bioinfo_course/03_rnaseq_upstream

tree -L 3
```

---

## 3.2 检查样本列表

```bash
cat sim_case_control/sample.list
```

`sample.list` 为三列格式：

```text
sample_id    read1.fq.gz    read2.fq.gz
```

如果需要重新生成样本列表，可以运行：

```bash
cat > sim_case_control/sample.list <<'EOF'
CTRL_1 sim_case_control/fastq/CTRL_1_R1.fq.gz sim_case_control/fastq/CTRL_1_R2.fq.gz
CTRL_2 sim_case_control/fastq/CTRL_2_R1.fq.gz sim_case_control/fastq/CTRL_2_R2.fq.gz
CTRL_3 sim_case_control/fastq/CTRL_3_R1.fq.gz sim_case_control/fastq/CTRL_3_R2.fq.gz
CASE_1 sim_case_control/fastq/CASE_1_R1.fq.gz sim_case_control/fastq/CASE_1_R2.fq.gz
CASE_2 sim_case_control/fastq/CASE_2_R1.fq.gz sim_case_control/fastq/CASE_2_R2.fq.gz
CASE_3 sim_case_control/fastq/CASE_3_R1.fq.gz sim_case_control/fastq/CASE_3_R2.fq.gz
EOF
```

检查 FASTQ 是否存在：

```bash
for fq in $(awk '{print $2"\n"$3}' sim_case_control/sample.list)
do
  if [ -f "$fq" ]; then
    echo "[OK] $fq"
  else
    echo "[MISS] $fq"
  fi
done
```

---

## 3.3 检查参考基因组、GTF 和 HISAT2 index

```bash
ls -lh ref/hg38.fa

ls -lh ref/hg38.refGene.gtf.gz

ls -lh ref/hisat2_index/hg38.*.ht2
```

确认 HISAT2 index 数量：

```bash
ls ref/hisat2_index/hg38.*.ht2 | wc -l
```

正常应输出：

```text
8
```

完整索引应包括：

```text
hg38.1.ht2
hg38.2.ht2
hg38.3.ht2
hg38.4.ht2
hg38.5.ht2
hg38.6.ht2
hg38.7.ht2
hg38.8.ht2
```

---

## 3.4 检查上游分析脚本

```bash
ls -lh scripts
```

至少应包含：

```text
make_sample_shells.sh
run_featurecounts_clean_matrix.sh
```

如果 `scripts` 目录中缺少“运行所有样本 shell”的脚本，可以临时创建：

```bash
cat > scripts/run_all_sample_shells.sh <<'EOF'
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
EOF

chmod +x scripts/run_all_sample_shells.sh
```

---

## 3.5 生成每个样本独立 shell

运行：

```bash
bash scripts/make_sample_shells.sh \
  sim_case_control/sample.list \
  sim_case_control/pipeline_result
```

查看生成的样本脚本：

```bash
ls -lh sim_case_control/pipeline_result/shell
```

应包含：

```text
CTRL_1.run.sh
CTRL_2.run.sh
CTRL_3.run.sh
CASE_1.run.sh
CASE_2.run.sh
CASE_3.run.sh
```

---

## 3.6 运行所有样本 shell

直接顺序运行所有样本：

```bash
bash scripts/run_all_sample_shells.sh \
  sim_case_control/pipeline_result/shell
```

后台运行：

```bash
nohup bash scripts/run_all_sample_shells.sh \
  sim_case_control/pipeline_result/shell \
  > sim_case_control/pipeline_result/run_all_samples.log 2>&1 &
```

查看日志：

```bash
tail -f sim_case_control/pipeline_result/run_all_samples.log
```

每个样本脚本内部执行：

```text
fastp
↓
HISAT2
↓
samtools view/sort/index
```

---

## 3.7 检查样本级结果

查看 fastp 结果：

```bash
find sim_case_control/pipeline_result/01_fastp \
  -name "*.fastp.html" | sort
```

查看 BAM 结果：

```bash
find sim_case_control/pipeline_result/02_hisat2 \
  -name "*.sorted.bam" | sort
```

统计 BAM 数量：

```bash
find sim_case_control/pipeline_result/02_hisat2 \
  -name "*.sorted.bam" | wc -l
```

正常应为：

```text
6
```

检查 BAM 完整性：

```bash
for bam in sim_case_control/pipeline_result/02_hisat2/*/*.sorted.bam
do
  echo "========== ${bam} =========="
  samtools quickcheck "${bam}" && echo "OK" || echo "BAD"
done
```

查看 HISAT2 比对 summary：

```bash
for f in sim_case_control/pipeline_result/02_hisat2/*/*.hisat2.summary.txt
do
  echo "========== ${f} =========="
  cat "$f"
done
```

---

## 3.8 生成最终干净表达矩阵

所有 BAM 都生成后，运行：

```bash
bash scripts/run_featurecounts_clean_matrix.sh \
  sim_case_control/pipeline_result
```

查看最终矩阵：

```bash
ls -lh sim_case_control/pipeline_result/03_featureCounts

head sim_case_control/pipeline_result/03_featureCounts/gene_counts.clean_matrix.tsv
```

最终只需要关注：

```text
sim_case_control/pipeline_result/03_featureCounts/gene_counts.clean_matrix.tsv
```

矩阵格式：

```text
Geneid    CTRL_1    CTRL_2    CTRL_3    CASE_1    CASE_2    CASE_3
```

---

# 四、RNA-seq 矩阵形式数据分析

进入目录：

```bash
/data/work/bioinfo_course/04_rnaseq_matrix
```

打开 Notebook，选择内核为`R 4.4.3`：

```text
01_RNA-seq_annotated.ipynb
```

该 Notebook 包含：

1. 读取 count matrix 和样本信息；
2. 样本层面 QC；
3. library size；
4. detected genes；
5. DESeq2 标准化；
6. VST；
7. PCA；
8. disease vs control 差异分析；
9. 火山图；
10. GO Biological Process 富集分析。

主要输出：

```text
teaching_results/
teaching_figures/
```

---

# 五、MatrixEQTL 教学

进入目录：

```bash
/data/work/bioinfo_course/05_matrixeqtl
```

打开 Notebook,选择内核为`R 4.4.3`：

```text
01_MatrixEQTL_demo_notebook.ipynb
```

该 Notebook 使用 `MatrixEQTL` 自带示例数据，演示：

1. 读取 SNP genotype/dosage matrix；
2. 读取 gene expression matrix；
3. 读取 covariate matrix；
4. 读取 SNP 和 gene 位置信息；
5. 设置 cis 距离；
6. 运行 `Matrix_eQTL_main()`；
7. 查看 cis/trans eQTL 结果；
8. 绘制 P 值分布；
9. 展示 top cis-eQTL 的 genotype-expression 散点图。

---

# 六、教师维护：更新课程数据到 /opt

如果你在 `/data/work/bioinfo_course` 中更新了课程数据，需要保存回镜像目录：

```bash
sudo rm -rf /opt/bioinfo_course

sudo cp -a /data/work/bioinfo_course /opt/bioinfo_course

cd /opt/bioinfo_course

# 删除上游流程已有结果
sudo rm -rf 03_rnaseq_upstream/sim_case_control/pipeline_result
sudo mkdir -p 03_rnaseq_upstream/sim_case_control/pipeline_result

# 删除 FastQC 已有结果
sudo rm -rf 02_qc_fastqc/qc_report
sudo mkdir -p 02_qc_fastqc/qc_report

# 删除矩阵分析已有结果
sudo rm -rf 04_rnaseq_matrix/teaching_results
sudo rm -rf 04_rnaseq_matrix/teaching_figures
sudo mkdir -p 04_rnaseq_matrix/teaching_results
sudo mkdir -p 04_rnaseq_matrix/teaching_figures

# 开放学生可读权限
sudo chmod -R a+rX /opt/bioinfo_course

# 检查
tree -L 3 /opt/bioinfo_course
```

检查：

```bash
tree -L 3 /opt/bioinfo_course

du -sh /opt/bioinfo_course
```

---

# 七、提醒

1. `/opt/bioinfo_course` 是镜像内置课程数据目录，应复制到 `/data/work` 后操作。
2. `03_rnaseq_upstream` 的 FASTQ 来自 hg38 全基因组模拟 reads，用于上游流程教学，不用于解释真实差异表达。
3. 真正的差异分析教学使用 `04_rnaseq_matrix` 中的模拟 RNA-seq count matrix。
4. `featureCounts` 最终只讲一个文件：`gene_counts.clean_matrix.tsv`。
