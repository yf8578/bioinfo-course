# RNA-seq reference files

The full hg38 FASTA and HISAT2 index are not stored directly in this Git repository because the files are too large for normal GitHub files.

To download and prepare them, run this command from the repository root:

```bash
bash download_rnaseq_ref.sh
```

The script temporarily downloads the split course archive from GitHub Release, checks the SHA-256 checksums, extracts only `03_rnaseq_upstream/ref/`, and then removes the downloaded parts and temporary archive.

Expected files after extraction:

```text
03_rnaseq_upstream/ref/hg38.fa
03_rnaseq_upstream/ref/hg38.refGene.gtf.gz
03_rnaseq_upstream/ref/hisat2_index/hg38.*.ht2
```
