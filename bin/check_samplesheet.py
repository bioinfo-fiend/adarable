#!/usr/bin/env python3
"""Validate the samplesheet contract (docs/phases/00-overview.md) and group re-sequenced runs.

Output CSV: sample,single_end,strandedness,fastq_1,fastq_2  (multiple runs joined with ';').
File existence is checked by Nextflow, not here (paths may be URLs or unstaged).
"""
import csv
import re
import sys

STRANDS = {"auto", "forward", "reverse", "unstranded"}
FQ = re.compile(r"\.f(ast)?q\.gz$")
SAMPLE = re.compile(r"^[A-Za-z0-9_.-]+$")


def check(rows):
    samples = {}
    for n, r in enumerate(rows, start=2):
        s, f1, f2, st = (r.get(k, "").strip() for k in ("sample", "fastq_1", "fastq_2", "strandedness"))
        where = f"line {n}"
        if not SAMPLE.match(s):
            raise ValueError(f"{where}: bad sample name {s!r}")
        if not FQ.search(f1) or (f2 and not FQ.search(f2)):
            raise ValueError(f"{where}: FASTQs must end in .fastq.gz/.fq.gz")
        if st not in STRANDS:
            raise ValueError(f"{where}: strandedness {st!r} not in {sorted(STRANDS)}")
        d = samples.setdefault(s, {"se": not f2, "strand": st, "f1": [], "f2": []})
        if d["se"] != (not f2) or d["strand"] != st:
            raise ValueError(f"{where}: runs of {s} disagree on single/paired-end or strandedness")
        d["f1"].append(f1)
        if f2:
            d["f2"].append(f2)
    if not samples:
        raise ValueError("samplesheet has no rows")
    return [
        {"sample": s, "single_end": str(d["se"]).lower(), "strandedness": d["strand"],
         "fastq_1": ";".join(d["f1"]), "fastq_2": ";".join(d["f2"])}
        for s, d in samples.items()
    ]


def main(src, dst):
    with open(src, newline="") as fh:
        reader = csv.DictReader(fh)
        missing = {"sample", "fastq_1", "strandedness"} - set(reader.fieldnames or [])
        if missing:
            sys.exit(f"samplesheet missing columns: {sorted(missing)}")
        try:
            out = check(reader)
        except ValueError as e:
            sys.exit(f"samplesheet error: {e}")
    with open(dst, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(out[0]))
        w.writeheader()
        w.writerows(out)


def _selfcheck():
    ok = check([
        {"sample": "A", "fastq_1": "a1_R1.fq.gz", "fastq_2": "a1_R2.fq.gz", "strandedness": "auto"},
        {"sample": "A", "fastq_1": "a2_R1.fq.gz", "fastq_2": "a2_R2.fq.gz", "strandedness": "auto"},
        {"sample": "B", "fastq_1": "b.fastq.gz", "fastq_2": "", "strandedness": "reverse"},
    ])
    assert ok[0]["fastq_1"] == "a1_R1.fq.gz;a2_R1.fq.gz" and ok[0]["single_end"] == "false"
    assert ok[1]["single_end"] == "true" and ok[1]["fastq_2"] == ""
    for bad in (
        [{"sample": "A B", "fastq_1": "x.fq.gz", "strandedness": "auto"}],
        [{"sample": "A", "fastq_1": "x.fastq", "strandedness": "auto"}],
        [{"sample": "A", "fastq_1": "x.fq.gz", "strandedness": "sideways"}],
        [{"sample": "A", "fastq_1": "x.fq.gz", "fastq_2": "y.fq.gz", "strandedness": "auto"},
         {"sample": "A", "fastq_1": "z.fq.gz", "fastq_2": "", "strandedness": "auto"}],
    ):
        try:
            check(bad)
        except ValueError:
            continue
        raise AssertionError(f"accepted bad input {bad}")
    print("check_samplesheet: self-check ok")


if __name__ == "__main__":
    _selfcheck() if len(sys.argv) == 1 else main(*sys.argv[1:3])
