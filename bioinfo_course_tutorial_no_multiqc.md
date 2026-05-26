# 生物信息学入门课程：云平台实践教程

> 课程根目录：`bioinfo_course/`

本教程后续命令默认从课程根目录 `bioinfo_course/` 开始运行。为了兼容 Codespaces、Colab 和其他 Linux 环境，正文尽量使用相对路径。

---

# 0. 数据准备与路径约定

## 0.1 使用其他环境

如果不使用课程镜像，可以直接从 GitHub Release 下载课程数据：

```bash
curl -L https://raw.githubusercontent.com/yf8578/bioinfo-course/main/download_bioinfo_course.sh -o download_bioinfo_course.sh

bash download_bioinfo_course.sh

tar -xzf bioinfo_course.tar.gz

cd bioinfo_course

tree -L 2
```

如果当前环境没有 `tree`，可以先跳过，或安装：

```bash
apt-get update

apt-get install -y tree
```

## 0.2 在 Colab 中打开 Notebook

为了方便上课，本仓库已经把 Notebook 小文件单独放在 GitHub 仓库中：

```text
04_rnaseq_matrix/00_simdata.ipynb
04_rnaseq_matrix/01_RNA-seq_annotated.ipynb
04_rnaseq_matrix/00_simdata_and_RNAseq_analysis.ipynb
05_matrixeqtl/01_MatrixEQTL_demo_notebook.ipynb
```

可以在 Colab 中选择：

```text
File -> Open notebook -> GitHub
```

然后输入仓库地址：

```text
https://github.com/yf8578/bioinfo-course
```

04 章节的 Notebook 有仿真数据生成代码，可以支撑后续矩阵分析；使用时主要需要配置好 R 环境，并安装 Notebook 中需要的 R / Bioconductor 包。合并版 `00_simdata_and_RNAseq_analysis.ipynb` 已经在开头写入自动安装缺失包的代码。

如果使用普通 Linux/Jupyter 环境，可以先创建并激活 `bioinfo` 环境，或者在 Jupyter 中选择 `R bioinfo` 内核。

## 0.3 手动下载、合并和解压数据

如果需要手动处理分卷文件，可以使用下面的命令。三个 `part-*` 文件合并后就是完整的 `bioinfo_course.tar.gz`：

```bash
mkdir -p bioinfo_course_download

cd bioinfo_course_download

curl -L -C - -O https://github.com/yf8578/bioinfo-course/releases/download/v1.0.0/bioinfo_course.tar.gz.part-00

curl -L -C - -O https://github.com/yf8578/bioinfo-course/releases/download/v1.0.0/bioinfo_course.tar.gz.part-01

curl -L -C - -O https://github.com/yf8578/bioinfo-course/releases/download/v1.0.0/bioinfo_course.tar.gz.part-02

curl -L -O https://github.com/yf8578/bioinfo-course/releases/download/v1.0.0/SHA256SUMS

sha256sum -c SHA256SUMS

cat bioinfo_course.tar.gz.part-* > ../bioinfo_course.tar.gz

cd ..

tar -xzf bioinfo_course.tar.gz

cd bioinfo_course
```

在 macOS 或部分系统中，如果没有 `sha256sum`，可以改用：

```bash
shasum -a 256 -c SHA256SUMS
```

## 0.4 后续命令的路径规则

完成上述任意一种准备方式后，当前目录应为：

```bash
bioinfo_course
```

后续章节默认从这里开始执行命令。每个章节开始前，先确认自己位于课程根目录。文档中的路径是教学示例，实际运行时需要根据自己的环境、数据所在位置和输出目录进行修改。进入子目录时使用相对路径，例如：

```bash
cd 02_qc_fastqc
```

如果已经进入其他子目录，先回到课程根目录：

```bash
cd /path/to/bioinfo_course
```

---

# 1. 软件环境准备

如果使用课程指定镜像，通常已经预装了本课程需要的软件，可以直接进入后续章节。如果使用 Colab、普通 Linux 服务器或新环境，可以按下面步骤安装 Miniforge 并创建 `bioinfo` 环境。

## 1.1 下载并安装 Miniforge

下载 Miniforge 安装脚本：

```bash
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
```

静默安装到当前用户目录：

```bash
bash "Miniforge3-$(uname)-$(uname -m).sh" -b -p "${HOME}/miniforge3"
```

加载 conda：

```bash
source "${HOME}/miniforge3/etc/profile.d/conda.sh"
```

可选：把 conda 初始化到 shell。Linux/Colab 常用 bash：

```bash
conda init bash
```

macOS 终端如果使用 zsh，可以运行：

```bash
conda init zsh
```

配置频道：

```bash
conda config --add channels conda-forge

conda config --add channels bioconda

conda config --set channel_priority strict
```

## 1.2 创建 bioinfo 环境

创建课程环境：

```bash
conda create -y -n bioinfo -c conda-forge -c bioconda \
  fastqc \
  fastp \
  hisat2 \
  subread \
  samtools \
  r-base \
  r-irkernel \
  r-tidyverse \
  r-ggplot2 \
  r-pheatmap \
  r-biocmanager \
  bioconductor-deseq2 \
  bioconductor-clusterprofiler \
  bioconductor-org.hs.eg.db \
  bioconductor-enrichplot
```

激活环境：

```bash
conda activate bioinfo
```

说明：`featureCounts` 在 conda 中由 `subread` 包提供。

如果需要在 Jupyter Notebook 中使用这个 R 环境，可以注册 R kernel：

```bash
Rscript -e 'IRkernel::installspec(name = "bioinfo-r", displayname = "R bioinfo")'
```

## 1.3 安装 MatrixEQTL

`MatrixEQTL` 可以在 R 中从 CRAN 安装：

```bash
Rscript -e 'install.packages("MatrixEQTL", repos = "https://cloud.r-project.org")'
```

如果后续做富集分析时发现 Bioconductor 包缺失，可以在 `bioinfo` 环境中补装：

```bash
Rscript -e 'BiocManager::install(c("clusterProfiler", "org.Hs.eg.db", "enrichplot", "DESeq2"), ask = FALSE, update = FALSE)'
```

## 1.4 检查软件是否可用

```bash
conda activate bioinfo

fastqc --version

fastp --version

hisat2 --version

featureCounts -v

R --version

Rscript -e 'library(DESeq2); library(clusterProfiler); library(org.Hs.eg.db); library(enrichplot); library(MatrixEQTL); sessionInfo()'
```

---

# 2. 课程目录结构

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
│   ├── 00_simdata_and_RNAseq_analysis.ipynb
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
cd 01_linux_shell

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
cd 02_qc_fastqc

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
cd 03_rnaseq_upstream

tree -L 3
```

---

## 3.2 运行前注意事项：检查脚本路径

RNA-seq 上游流程会调用多个 shell 脚本。运行前一定要先检查脚本中的输入和输出路径，确认它们与当前课程目录一致。文档中的路径不一定适用于所有平台；如果数据、参考文件或输出目录放在其他位置，需要按实际情况修改脚本路径。

重点检查：

1. FASTQ 输入路径是否来自 `sim_case_control/sample.list`。
2. 参考基因组路径是否指向 `ref/hg38.fa`。
3. HISAT2 index 前缀是否指向 `ref/hisat2_index/hg38`。
4. GTF 注释文件是否指向 `ref/hg38.refGene.gtf.gz` 或课程中实际使用的 GTF。
5. 输出目录是否写到 `sim_case_control/pipeline_result/` 下。
6. 脚本中是否还有旧的绝对路径，例如 `/data/work/...`、`/opt/...` 或其他个人目录。

可以用下面的命令快速检查脚本中的路径：

```bash
sed -n '1,220p' scripts/make_sample_shells.sh

sed -n '1,220p' scripts/run_featurecounts_clean_matrix.sh

if [ -f scripts/run_all_sample_shells.sh ]; then
  sed -n '1,220p' scripts/run_all_sample_shells.sh
fi
```

也可以直接搜索脚本里的常见路径关键词：

```bash
grep -RInE '/data/work|/opt|/home|/Users|hg38|hisat2_index|refGene|pipeline_result|sample.list' scripts
```

如果是在 Codespaces、Colab 或自己的服务器中运行，建议优先使用相对路径，避免把脚本写死到某个固定目录。

---

## 3.3 检查样本列表

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

## 3.4 检查参考基因组、GTF 和 HISAT2 index

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

## 3.5 检查上游分析脚本

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

## 3.6 生成每个样本独立 shell

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

## 3.7 运行所有样本 shell

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

## 3.8 检查样本级结果

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

## 3.9 生成最终干净表达矩阵

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
cd 04_rnaseq_matrix
```

推荐优先打开合并版 Notebook，选择 R 内核：

```text
00_simdata_and_RNAseq_analysis.ipynb
```

该 Notebook 可以在 Colab 或其他 Jupyter 环境中运行，不需要提前准备 04 章节的数据文件；运行时会自行安装缺失包并生成模拟数据。

同时保留原始拆分版 Notebook：

```text
00_simdata.ipynb
01_RNA-seq_annotated.ipynb
```

该 Notebook 包含：

1. 安装缺失的 R / Bioconductor 包；
2. 生成仿真 RNA-seq count matrix 和样本信息；
3. 读取 count matrix 和样本信息；
4. 样本层面 QC；
5. library size；
6. detected genes；
7. DESeq2 标准化；
8. VST；
9. PCA；
10. disease vs control 差异分析；
11. 火山图；
12. GO Biological Process 富集分析。

主要输出：

```text
teaching_results/
teaching_figures/
```

---

# 五、MatrixEQTL 教学

进入目录：

```bash
cd 05_matrixeqtl
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

# 六、提醒

1. 下载解压后进入 `bioinfo_course/`，后续命令按相对路径运行。
2. `03_rnaseq_upstream` 的 FASTQ 来自 hg38 全基因组模拟 reads，用于上游流程教学，不用于解释真实差异表达。
3. 真正的差异分析教学使用 `04_rnaseq_matrix` 中的模拟 RNA-seq count matrix。
4. `featureCounts` 最终只讲一个文件：`gene_counts.clean_matrix.tsv`。
