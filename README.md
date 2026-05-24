# Bioinfo Course

This repository contains course notes and download helpers for the bioinformatics course dataset.

The full dataset archive is distributed through GitHub Releases because the archive is about 5 GB and is too large for normal Git tracking.

## Download in Google Colab

After the first release is uploaded, run this in Colab:

```python
!bash <(curl -L https://raw.githubusercontent.com/OWNER/bioinfo-course/main/download_bioinfo_course.sh)
```

Replace `OWNER` with the GitHub account or organization that owns the repository.

The script downloads all release parts, verifies the SHA-256 checksum if available, and reconstructs:

```text
bioinfo_course.tar.gz
```

Then extract it:

```python
!tar -xzf bioinfo_course.tar.gz
```

## Local Upload Workflow

From this repository directory:

```bash
bash prepare_release_assets.sh
gh auth login -h github.com
gh repo create bioinfo-course --public --source=. --remote=origin --push
gh release create v1.0.0 release-assets/bioinfo_course.tar.gz.part-* release-assets/SHA256SUMS --title "Bioinfo course dataset" --notes "Split release assets for Colab download."
```

GitHub Release assets have a per-file size limit, so the archive is split before upload.
