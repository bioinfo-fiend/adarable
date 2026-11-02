# Test reads

Real paired-end human RNA-seq (SRA run SRR5665260, 142 bp), taken from the
[nf-core/test-datasets](https://github.com/nf-core/test-datasets/tree/rnavar) `rnavar` branch (MIT).
Reads map to the 40 kb chr22 slice in that branch (`genome/genome.fasta`), used as the test reference from phase 02.

The original 4,159 pairs are split in two halves so the samplesheet can list one sample as two runs:

| file | reads |
|---|---|
| `rnavar_run1_R{1,2}.fastq.gz` | first 2,079 pairs |
| `rnavar_run2_R{1,2}.fastq.gz` | remaining 2,080 pairs |

`rnavar_se` reuses `rnavar_run1_R1` as a single-end sample.
