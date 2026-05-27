# 生物信息学入门课程：云平台实践教程

> 镜像内置课程目录：`/opt/bioinfo_course`  
> 学生实际运行目录：`/data/work/bioinfo_course`

推荐每次上课先复制课程目录：

```bash
cp -r /opt/bioinfo_course /data/work/bioinfo_course
cd /data/work/bioinfo_course
```

---

# 0. 课程目录结构

```text
bioinfo_course/
├── 00_docs/
├── 01_linux_shell/
├── 02_qc_fastqc/
├── 03_rnaseq_upstream/
├── 04_rnaseq_matrix/
└── 05_matrixeqtl/
```

| 目录 | 内容 |
|---|---|
| `00_docs` | 课程说明文档 |
| `01_linux_shell` | Linux / Shell 练习 |
| `02_qc_fastqc` | FastQC / MultiQC 下机数据质控 |
| `03_rnaseq_upstream` | FASTQ 到干净 count matrix 的上游流程 |
| `04_rnaseq_matrix` | RNA-seq 矩阵数据分析 Notebook |
| `05_matrixeqtl` | MatrixEQTL 教学 Notebook |

---

# 1. 数据整理和保存到 /opt

## 1.1 重新整理课程文件

在 `/data/work` 下运行：

```bash
cd /data/work
bash organize_bioinfo_course_data_v2.sh
```

该脚本会重新整理：

```text
/data/work/bioinfo_course
```

并复制：

- FastQC 示例数据；
- RNA-seq 上游模拟 FASTQ；
- hg38 参考基因组；
- HISAT2 index；
- GTF 注释文件；
- 上游分析脚本；
- 上游流程结果；
- 最终干净矩阵；
- RNA-seq 矩阵分析 Notebook；
- MatrixEQTL Notebook。

## 1.2 保存到 /opt

```bash
sudo rm -rf /opt/bioinfo_course
sudo cp -a /data/work/bioinfo_course /opt/bioinfo_course
```

检查：

```bash
tree -L 3 /opt/bioinfo_course
du -sh /opt/bioinfo_course
```

---

# 2. Linux / Shell 基础

```bash
cd /data/work/bioinfo_course
pwd
ls -lh
tree -L 2
du -sh *
```

Shell 练习：

```bash
cd 01_linux_shell
less bash.sh
bash bash.sh
```

---

# 3. FastQC / MultiQC 下机数据质控

进入目录：

```bash
cd /data/work/bioinfo_course/02_qc_fastqc
```

示例文件：

```text
simdata/sim_hg38_1.fq
simdata/sim_hg38_2.fq
simdata/sim_hg38_1.adapter.fq
simdata/sim_hg38_2.adapter.fq
```

运行 FastQC：

```bash
mkdir -p qc_report/fastqc_raw

fastqc \
  simdata/sim_hg38_1.fq \
  simdata/sim_hg38_2.fq \
  -o qc_report/fastqc_raw

fastqc \
  simdata/sim_hg38_1.adapter.fq \
  simdata/sim_hg38_2.adapter.fq \
  -o qc_report/fastqc_raw
```

运行 MultiQC：

```bash
mkdir -p qc_report/multiqc_raw

multiqc qc_report/fastqc_raw -o qc_report/multiqc_raw
```

查看报告：

```text
qc_report/multiqc_raw/multiqc_report.html
```

重点观察：

```text
Adapter Content
Overrepresented sequences
Per base sequence quality
Sequence Length Distribution
```

---

# 4. RNA-seq 上游流程：FASTQ 到干净矩阵

> 注意：本部分 FASTQ 来自 hg38 全基因组模拟 reads，主要用于教学演示上游流程；不用于解释真实表达差异。

进入目录：

```bash
cd /data/work/bioinfo_course/03_rnaseq_upstream
```

## 4.1 检查数据和索引

样本表：

```bash
cat sim_case_control/sample.list
```

分组表：

```bash
cat sim_case_control/group.txt
```

检查参考文件：

```bash
ls -lh ref/hg38.fa
ls -lh ref/hg38.refGene.gtf.gz
ls -lh ref/hisat2_index/hg38.*.ht2
```

HISAT2 index 应包含：

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

## 4.2 生成每个样本独立 shell

```bash
bash scripts/make_sample_shells.sh \
  sim_case_control/sample.list \
  sim_case_control/pipeline_result
```

查看：

```bash
ls -lh sim_case_control/pipeline_result/shell
```

---

## 4.3 直接运行所有样本 shell

不限制并发，直接顺序执行所有样本脚本：

```bash
bash scripts/run_all_sample_shells.sh \
  sim_case_control/pipeline_result/shell
```

如果要后台运行：

```bash
nohup bash scripts/run_all_sample_shells.sh \
  sim_case_control/pipeline_result/shell \
  > sim_case_control/pipeline_result/run_all_samples.log 2>&1 &
```

查看日志：

```bash
tail -f sim_case_control/pipeline_result/run_all_samples.log
```

---

## 4.4 检查 BAM 是否生成

```bash
find sim_case_control/pipeline_result/02_hisat2 \
  -name "*.sorted.bam" | sort

find sim_case_control/pipeline_result/02_hisat2 \
  -name "*.sorted.bam" | wc -l
```

应有 6 个 BAM。

检查 BAM 完整性：

```bash
for bam in sim_case_control/pipeline_result/02_hisat2/*/*.sorted.bam
do
  echo "========== ${bam} =========="
  samtools quickcheck "${bam}" && echo "OK" || echo "BAD"
done
```

---

## 4.5 生成最终干净表达矩阵

```bash
bash scripts/run_featurecounts_clean_matrix.sh \
  sim_case_control/pipeline_result
```

最终只关注：

```text
sim_case_control/pipeline_result/03_featureCounts/gene_counts.clean_matrix.tsv
```

查看：

```bash
head sim_case_control/pipeline_result/03_featureCounts/gene_counts.clean_matrix.tsv
```

矩阵格式：

```text
Geneid    CTRL_1    CTRL_2    CTRL_3    CASE_1    CASE_2    CASE_3
```

---

## 4.6 运行 MultiQC 汇总上游流程结果

```bash
bash scripts/run_multiqc_summary.sh \
  sim_case_control/pipeline_result
```

查看报告：

```text
sim_case_control/pipeline_result/04_multiqc/multiqc_report.html
```

MultiQC 会汇总：

- fastp 报告；
- HISAT2 summary；
- featureCounts 日志；
- samtools 相关结果，如果日志格式可识别。

---

# 5. RNA-seq 矩阵数据分析

进入目录：

```bash
cd /data/work/bioinfo_course/04_rnaseq_matrix
```

打开 Notebook：

```text
01_RNA-seq_annotated.ipynb
```

内容：

1. 读取 count matrix 和 sample info；
2. 样本 QC；
3. library size；
4. detected genes；
5. DESeq2 标准化；
6. VST；
7. PCA；
8. disease vs control 差异分析；
9. 火山图；
10. GOBP 富集。

---

# 6. MatrixEQTL 教学

进入目录：

```bash
cd /data/work/bioinfo_course/05_matrixeqtl
```

打开 Notebook：

```text
01_MatrixEQTL_demo_notebook.ipynb
```

内容：

1. 读取 SNP genotype/dosage matrix；
2. 读取 gene expression matrix；
3. 读取 covariates；
4. 读取 SNP/gene 位置；
5. 设置 cis 距离；
6. 运行 MatrixEQTL；
7. 查看 cis/trans eQTL；
8. 绘制 P 值分布；
9. 展示 top eQTL 散点图。

---

# 7. 教学提醒

1. `03_rnaseq_upstream` 用于上游流程教学，不用于真实差异表达解释。
2. 差异分析教学使用 `04_rnaseq_matrix`。
3. featureCounts 最终只讲 `gene_counts.clean_matrix.tsv`。
4. MultiQC 已加入上游流程，用于汇总 fastp、hisat2、featureCounts 等结果。
