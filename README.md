# Bioinfo Course

生物信息学入门课程材料。

## 使用 GitHub Codespaces

推荐学生先 fork 本仓库，然后在自己的仓库里启动 Codespace：

```text
Code -> Codespaces -> Create codespace on main
```

进入 Codespace 后，打开终端，下载课程数据：

```bash
bash download_bioinfo_course.sh
```

解压数据：

```bash
tar -xzf bioinfo_course.tar.gz
```

进入课程目录：

```bash
cd bioinfo_course
```

查看目录：

```bash
ls -lh
```

## 课程文档

课程 Markdown 文档：

```text
bioinfo_course_tutorial_no_multiqc.md
```

## Notebook

仓库中保留了可直接打开的 Notebook：

```text
04_rnaseq_matrix/00_simdata.ipynb
04_rnaseq_matrix/01_RNA-seq_annotated.ipynb
05_matrixeqtl/01_MatrixEQTL_demo_notebook.ipynb
```

## 数据说明

完整数据包通过 GitHub Release 分卷保存，`download_bioinfo_course.sh` 会自动下载、校验并合并为：

```text
bioinfo_course.tar.gz
```

如果下载中断，重新运行同一条命令即可继续下载：

```bash
bash download_bioinfo_course.sh
```
