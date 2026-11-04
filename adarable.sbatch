#!/bin/bash
#SBATCH -J adarable
#SBATCH -c 2
#SBATCH --mem=8G
#SBATCH -o adarable-%j.out
# Nextflow head job for ADARable on Slurm. Each task runs as its own Slurm job, pinned to the node
# this job lands on, because the repo, work dir and reference cache can sit on node-local disks.
#
# Usage, from the folder that should hold results/ and the Nextflow log:
#   sbatch [--nodelist=<node>] /path/to/adarable/adarable.sbatch --input samplesheet.csv --genome GRCh38 [-resume] [params]
#
# Override with environment variables (they reach the job; sbatch exports your environment):
#   NXF_WORK                 task work dirs        default /data/local/$USER/adarable/work
#   NXF_APPTAINER_CACHEDIR   container images      default /data/local/$USER/adarable/apptainer
#   ADARABLE_REF_CACHE       prepared references   default /data/local/$USER/adarable/ref_cache
#   ADARABLE_PROFILE         Nextflow profiles     default slurm,apptainer
#
# Smoke test (--genome on the command line beats the default genome in conf/local.config):
#   ADARABLE_PROFILE=slurm,apptainer,test sbatch /path/to/adarable/adarable.sbatch --genome test_rnavar
set -euo pipefail

# sbatch runs a spooled copy of this file; the original's folder is the pipeline
repo=$(dirname "$(scontrol show job "$SLURM_JOB_ID" | awk -F= '/^ *Command=/ { split($2, a, " "); print a[1] }')")
base=/data/local/$USER/adarable
export NXF_WORK=${NXF_WORK:-$base/work}
export NXF_APPTAINER_CACHEDIR=${NXF_APPTAINER_CACHEDIR:-$base/apptainer}
mkdir -p "$NXF_WORK" "$NXF_APPTAINER_CACHEDIR"

# Local genomes (git-ignored), see conf/local.example.config
local_conf=()
[[ -f $repo/conf/local.config ]] && local_conf=(-c "$repo/conf/local.config")

echo "ADARable from $repo on $SLURMD_NODENAME, work dir $NXF_WORK"
nextflow run "$repo/main.nf" \
    -profile "${ADARABLE_PROFILE:-slurm,apptainer}" \
    "${local_conf[@]}" \
    --node "$SLURMD_NODENAME" \
    --ref_cache "${ADARABLE_REF_CACHE:-$base/ref_cache}" \
    "$@"
