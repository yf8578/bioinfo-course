# 生物信息学入门课程：云平台实践教程

> 推荐固定数据目录：`/opt/bioinfo_course`  
> 推荐学生工作目录：`/data/work/bioinfo_course`

`/opt/bioinfo_course` 作为镜像内置只读或半只读课程数据目录，学生每次上课先复制到 `/data/work` 再操作，避免破坏原始数据。

---

## 0. 课程数据目录结构

建议整理后的目录如下：

```text
/opt/bioinfo_course/
├── 00_docs/
│   └── part1.md
├── 01_linux_shell/
│   ├── bash.sh
│   └── Linux/
├── 02_qc_fastqc/
│   ├── simdata/
│   │   ├── sim_hg38_1.fq
│   │   ├── sim_hg38_2.fq
│   │   ├── sim_hg38_1.adapter.fq
│   │   └── sim_hg38_2.adapter.fq
│   └── qc_report/
├── 03_rnaseq_upstream/
│   ├── scripts/
│   │   ├── 01_generate_art_simdata.sh
│   │   ├── 02_add_adapter_to_case.sh
│   │   └── run_fastp_hisat2_featurecounts.sh
│   ├── sim_case_control/
│   │   ├── fastq/
│   │   ├── sample.list
│   │   └── group.txt
│   └── ref/
│       ├── hg38.fa
│       ├── hg38.refGene.gtf.gz
│       ├── hg38.knownGene.gtf.gz
│       └── hisat2_index/
├── 04_rnaseq_matrix/
│   ├── 00_simdata.ipynb
│   ├── 01_RNA-seq_annotated.ipynb
│   ├── teaching_results/
│   └── teaching_figures/
└── 05_matrixeqtl/
    └── 01_MatrixEQTL_demo_notebook.ipynb
```

---

# 一、云平台使用

## 1.1 进入工作目录

```bash
cd /data/work
pwd
ls
```

如果课程数据已经内置在 `/opt/bioinfo_course`，建议复制一份到工作目录：

```bash
cp -r /opt/bioinfo_course /data/work/bioinfo_course
cd /data/work/bioinfo_course
tree -L 2
```

---

## 1.2 Linux 基本命令

练习参考链接：

1. https://book.ncrnalab.org/teaching/part-i.-programming-skills/1.linux/1.1.linux-basic-command
2. https://www.runoob.com/linux/linux-command-manual.html

常用命令：

```bash
pwd
ls
ls -lh
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
du -sh
df -h
```

示例：

```bash
cd /data/work/bioinfo_course
ls -lh
du -sh *
find . -name "*.fq" | head
```

---

## 1.3 Shell 基础

练习参考链接：

1. https://book.ncrnalab.org/teaching/part-i.-programming-skills/1.linux/1.3.linux-bash

常见用法：

```bash
for file in *.fq
do
  echo "${file}"
done
```

查看脚本内容：

```bash
less 01_linux_shell/bash.sh
```

运行脚本：

```bash
bash 01_linux_shell/bash.sh
```

---

# 二、conda / mamba 环境

> 本课程镜像中建议预装好生物信息学基础环境。由于云平台网络可能受限，课堂上不建议从零安装 conda。

如果需要从零安装 Miniforge，可以参考：

```bash
# 下载 Miniforge
# 注意：Linux 平台应下载 Linux 版本，不是 MacOSX 版本
wget https://github.com/conda-forge/miniforge/releases/download/26.3.2-2/Miniforge3-Linux-x86_64.sh

# 添加执行权限
chmod +x Miniforge3-Linux-x86_64.sh

# 安装
bash Miniforge3-Linux-x86_64.sh

# 刷新环境
source ~/.bashrc

# 检查
conda --version
mamba --version
```

本课程建议环境包含：

```text
fastqc
multiqc
fastp
hisat2
samtools
subread/featureCounts
R
DESeq2
clusterProfiler
org.Hs.eg.db
MatrixEQTL
```

检查软件：

```bash
which fastqc
which multiqc
which fastp
which hisat2
which samtools
which featureCounts
R --version
```

---

# 三、下机数据质检质控：FastQC / MultiQC

## 3.1 数据说明

示例数据位置：

```bash
/opt/bioinfo_course/02_qc_fastqc/simdata
```

复制到工作目录：

```bash
cd /data/work
cp -r /opt/bioinfo_course/02_qc_fastqc ./02_qc_fastqc
cd 02_qc_fastqc
tree
```

其中：

```text
sim_hg38_1.fq           # 原始模拟 R1
sim_hg38_2.fq           # 原始模拟 R2
sim_hg38_1.adapter.fq   # 人工添加 adapter 的 R1
sim_hg38_2.adapter.fq   # 人工添加 adapter 的 R2
```

这组数据用于演示：

1. FASTQ 文件结构；
2. FastQC 质控报告；
3. adapter 污染对质控报告的影响；
4. MultiQC 汇总多个 FastQC 结果。

---

## 3.2 查看 FASTQ 文件

```bash
head simdata/sim_hg38_1.fq
```

FASTQ 每条 read 占 4 行：

```text
第 1 行：read ID
第 2 行：碱基序列
第 3 行：+
第 4 行：碱基质量值
```

---

## 3.3 FastQC 分析无 adapter 数据

```bash
mkdir -p qc_report/fastqc_raw

fastqc \
  simdata/sim_hg38_1.fq \
  simdata/sim_hg38_2.fq \
  -o qc_report/fastqc_raw
```

查看结果：

```bash
ls -lh qc_report/fastqc_raw
```

输出包括：

```text
*_fastqc.html
*_fastqc.zip
```

---

## 3.4 FastQC 分析带 adapter 数据

```bash
fastqc \
  simdata/sim_hg38_1.adapter.fq \
  simdata/sim_hg38_2.adapter.fq \
  -o qc_report/fastqc_raw
```

比较普通数据和 adapter 数据的 FastQC 报告，重点看：

```text
Adapter Content
Overrepresented sequences
Per base sequence quality
Sequence Length Distribution
```

---

## 3.5 MultiQC 汇总报告

```bash
mkdir -p qc_report/multiqc_raw

multiqc qc_report/fastqc_raw -o qc_report/multiqc_raw
```

查看：

```bash
ls -lh qc_report/multiqc_raw
```

打开：

```text
multiqc_report.html
```

---

## 3.6 adapter 是如何人工添加的？

R1 adapter 示例：

```bash
awk '{
  if (NR % 4 == 2) {
    if ((int(NR/4)) % 4 == 0) {
      print substr($0, 1, 116) "AGATCGGAAGAGCACACGTCTGAACTCCAGTCA"
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
}' sim_hg38_1.fq > sim_hg38_1.adapter.fq
```

R2 adapter 示例：

```bash
awk '{
  if (NR % 4 == 2) {
    if ((int(NR/4)) % 4 == 0) {
      print substr($0, 1, 116) "AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT"
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
}' sim_hg38_2.fq > sim_hg38_2.adapter.fq
```

说明：

- `NR % 4 == 2` 表示 FASTQ 的序列行；
- `NR % 4 == 0` 表示 FASTQ 的质量值行；
- 每 4 条 read 中人为污染 1 条；
- 保留前 116 bp，再拼接 34 bp adapter，总长度仍为 150 bp。

---

# 四、RNA-seq 上游分析流程

> 当前部分可先完成目录和样本表教学；HISAT2 全基因组索引如果仍在构建，等索引完整后再运行比对。

## 4.1 数据说明

示例 paired-end 数据位置：

```bash
/opt/bioinfo_course/03_rnaseq_upstream/sim_case_control/fastq
```

样本表：

```bash
/opt/bioinfo_course/03_rnaseq_upstream/sim_case_control/sample.list
```

分组表：

```bash
/opt/bioinfo_course/03_rnaseq_upstream/sim_case_control/group.txt
```

样本设计：

```text
CTRL_1, CTRL_2, CTRL_3
CASE_1, CASE_2, CASE_3
```

查看样本表：

```bash
cat /opt/bioinfo_course/03_rnaseq_upstream/sim_case_control/sample.list
cat /opt/bioinfo_course/03_rnaseq_upstream/sim_case_control/group.txt
```

`sample.list` 三列分别为：

```text
sample_id    R1.fastq.gz    R2.fastq.gz
```

---

## 4.2 HISAT2 index 完整性检查

完整的 HISAT2 小索引通常应包含：

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

检查：

```bash
ls -lh /opt/bioinfo_course/03_rnaseq_upstream/ref/hisat2_index
```

如果缺少 `hg38.5.ht2` 或 `hg38.6.ht2`，说明索引未构建完成，不要直接运行 HISAT2。

构建索引命令：

```bash
mkdir -p /data/work/hisat2_index

hisat2-build \
  -p 8 \
  /opt/bioinfo_course/03_rnaseq_upstream/ref/hg38.fa \
  /data/work/hisat2_index/hg38
```

构建完成后，脚本中的 index 前缀应为：

```bash
/data/work/hisat2_index/hg38
```

注意：不要加 `.1.ht2` 后缀。

---

## 4.3 上游分析流程步骤

流程包括：

```text
FASTQ
↓
fastp 去 adapter / 质量过滤
↓
HISAT2 比对
↓
samtools 转 BAM / 排序 / 建索引
↓
featureCounts 定量
↓
MultiQC 汇总
```

运行示例：

```bash
cd /data/work

cp -r /opt/bioinfo_course/03_rnaseq_upstream ./03_rnaseq_upstream

bash 03_rnaseq_upstream/scripts/run_fastp_hisat2_featurecounts.sh \
  03_rnaseq_upstream/sim_case_control/sample.list \
  03_rnaseq_upstream/pipeline_result
```

结果目录：

```text
03_rnaseq_upstream/pipeline_result/
├── 01_fastp/
├── 02_hisat2/
├── 03_featureCounts/
├── 04_multiqc/
└── logs/
```

---

# 五、矩阵形式 RNA-seq 数据分析

## 5.1 数据说明

位置：

```bash
/opt/bioinfo_course/04_rnaseq_matrix
```

主要 Notebook：

```text
00_simdata.ipynb
01_RNA-seq_annotated.ipynb
```

已有结果：

```text
teaching_results/
teaching_figures/
```

复制到工作目录：

```bash
cd /data/work
cp -r /opt/bioinfo_course/04_rnaseq_matrix ./04_rnaseq_matrix
cd 04_rnaseq_matrix
```

启动 Notebook 后打开：

```text
01_RNA-seq_annotated.ipynb
```

---

## 5.2 教学流程

该 Notebook 包含：

1. 读取 count matrix 和样本分组；
2. 样本层面 QC；
3. 测序深度统计；
4. 基因检出数统计；
5. DESeq2 标准化；
6. VST 归一化表达矩阵；
7. PCA；
8. disease vs control 差异表达；
9. 火山图；
10. GO Biological Process 富集分析。

---

## 5.3 主要输出

结果表：

```text
teaching_results/sample_qc_summary.tsv
teaching_results/vst_normalized_matrix.tsv
teaching_results/DESeq2_disease_vs_control_all.tsv
teaching_results/DESeq2_disease_vs_control_DEG.tsv
teaching_results/GOBP_enrichment_up_genes.tsv
teaching_results/GOBP_enrichment_down_genes.tsv
```

图片：

```text
teaching_figures/01_library_size.png
teaching_figures/02_detected_genes.png
teaching_figures/03_vst_expression_boxplot.png
teaching_figures/04_PCA.png
teaching_figures/05_volcano_disease_vs_control.png
teaching_figures/06_GOBP_dotplot_up_genes.png
teaching_figures/07_GOBP_dotplot_down_genes.png
```

---

# 六、xQTL / MatrixEQTL 教学

## 6.1 数据说明

位置：

```bash
/opt/bioinfo_course/05_matrixeqtl
```

Notebook：

```text
01_MatrixEQTL_demo_notebook.ipynb
```

复制到工作目录：

```bash
cd /data/work
cp -r /opt/bioinfo_course/05_matrixeqtl ./05_matrixeqtl
cd 05_matrixeqtl
```

打开 Notebook：

```text
01_MatrixEQTL_demo_notebook.ipynb
```

---

## 6.2 教学内容

MatrixEQTL Notebook 使用 `MatrixEQTL` 包自带示例数据，演示：

1. 读取 SNP genotype/dosage matrix；
2. 读取 gene expression matrix；
3. 读取 covariate matrix；
4. 读取 SNP 和 gene 位置信息；
5. 设定 cis 距离；
6. 运行 `Matrix_eQTL_main()`；
7. 查看 cis/trans eQTL 结果；
8. 绘制 P 值分布；
9. 展示 top cis-eQTL 的 genotype-expression 散点关系。

---

## 6.3 MatrixEQTL 核心概念

MatrixEQTL 的基本模型可以理解为：

```text
Gene expression ~ SNP genotype + covariates
```

其中：

- 表达矩阵：基因 × 样本；
- 基因型矩阵：SNP × 样本；
- 协变量矩阵：协变量 × 样本；
- 位置信息：用于区分 cis 和 trans；
- `beta`：SNP 对表达量的效应方向和大小；
- `pvalue`：关联显著性；
- `FDR`：多重检验校正后的显著性。

---

# 七、课程使用建议

## 7.1 学生操作建议

每次上课不要直接修改 `/opt` 目录，建议复制到 `/data/work`：

```bash
cp -r /opt/bioinfo_course /data/work/bioinfo_course
cd /data/work/bioinfo_course
```

## 7.2 教师维护建议

如果需要更新课程数据：

1. 先在 `/data/work/bioinfo_course` 中调试；
2. 确认无误后复制到 `/opt/bioinfo_course`；
3. 保存镜像。

```bash
rm -rf /opt/bioinfo_course
cp -a /data/work/bioinfo_course /opt/bioinfo_course
```

如果没有 `/opt` 写权限：

```bash
sudo rm -rf /opt/bioinfo_course
sudo cp -a /data/work/bioinfo_course /opt/bioinfo_course
```

---

# 八、当前注意事项

1. `/opt` 中的数据建议作为原始课程数据，不建议学生直接修改。
2. HISAT2 index 必须完整后才能运行比对。
3. 如果只是教学演示，建议后续制作 chr22 小参考，以减少索引构建和比对时间。
4. `hg38.fa` 文件较大，保存到镜像会增加镜像体积。
5. `sim_case_control` 中的 ART 数据更接近 DNA/WGS 风格模拟 reads，用于教学演示流程可以；不能解释为真实 RNA-seq 表达差异。
