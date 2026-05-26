# Reference files

The full hg38 FASTA and HISAT2 index are not stored directly in this Git repository because the files are larger than GitHub's normal file size limit.

If you run the full RNA-seq upstream alignment workflow, prepare the reference files here or update the shell scripts to point to your own reference directory:

```text
03_rnaseq_upstream/ref/hg38.fa
03_rnaseq_upstream/ref/hg38.refGene.gtf.gz
03_rnaseq_upstream/ref/hisat2_index/hg38.*.ht2
```
