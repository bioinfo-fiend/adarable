#!/usr/bin/env python3
"""Spike-in A-to-I truth set for the test reads (docs/phases/05-editing-detection.md).

  spike_edits.py make BASELINE.tsv BAM FASTQ OUTDIR   edit FASTQ, write OUTDIR/<FASTQ name> + spikes.tsv
  spike_edits.py check spikes.tsv REDITOOLS.tsv[.gz]  exit 1 unless every spike is called within 0.10

Single-end only: BAM is the unedited rnavar_se dedup BAM, FASTQ its reads (rnavar_run1_R1). The paired
sample is no use here: its noisy R2 sits at STAR's mismatch limit, so edited pairs drop out or realign.
BASELINE is `reditools analyze -s 1 -C -me 0` on BAM, so sites and strands are in RNA orientation.
`make` picks 20 A sites with coverage >= 20 and no G yet, at least MIN_GAP apart, and turns a set fraction
of the non-duplicate reads covering each into G (A->G on the genome for '+' sites, T->C for '-').
Duplicates are left alone: markdup picks the kept read by base quality, which the edits don't change.
A read gets spikes only while NM + spikes < MAX_NM: these reads already carry ~5 mismatches, and STAR
drops a read at 10. Levels alternate low/high so neighbouring sites don't load the same reads.
Sites with >= 5 fixed differences (>= 90% of reads disagree with the reference) within 75 bp are skipped:
those reads match a near-copy elsewhere in the slice, and an extra G tips them into multimapping.
Needs pysam (the reditools3 container has it).
"""
import csv
import gzip
import random
import sys
from pathlib import Path

COMP = str.maketrans("ACGTN", "TGCAN")
N_SITES, MIN_COV, MIN_GAP, MAX_NM = 20, 20, 10, 8
LEVELS = [0.1, 0.6, 0.2, 0.7, 0.3, 0.8, 0.4, 0.9, 0.5]


def rows(path):
    with (gzip.open if str(path).endswith(".gz") else open)(path, "rt") as f:
        yield from csv.DictReader(f, delimiter="\t")


def counts(r):
    return [int(x) for x in r["BaseCount[A,C,G,T]"].strip("[]").split(",")]


def pick_sites(baseline):
    base = list(rows(baseline))   # position-sorted
    fixed = [(r["Region"], int(r["Position"])) for r in base if int(r["Coverage"]) >= 10 and float(r["Frequency"]) >= 0.9]
    sites, last = [], None
    for r in base:
        if r["Reference"] != "A" or r["Strand"] not in "+-" or int(r["Coverage"]) < MIN_COV or counts(r)[2]:
            continue
        if sum(c == r["Region"] and abs(p - int(r["Position"])) <= 75 for c, p in fixed) >= 5:
            continue
        if last and r["Region"] == last[0] and int(r["Position"]) - last[1] < MIN_GAP:
            continue
        sites.append((r["Region"], int(r["Position"]), r["Strand"]))
        last = (r["Region"], int(r["Position"]))
    return sorted(random.Random(5).sample(sites, min(N_SITES, len(sites))))


def make(baseline, bam_path, fastq, outdir):
    import pysam
    bam = pysam.AlignmentFile(bam_path)
    edits = {}   # read name -> [(trimmed seq in FASTQ orientation, offset in it, new base)]
    spikes = lambda r: r.get_tag("NM") + len(edits.get(r.query_name, []))
    truth = []
    for i, (chrom, pos, strand) in enumerate(pick_sites(baseline)):
        ref, alt = ("A", "G") if strand == "+" else ("T", "C")
        hits = []
        for col in bam.pileup(chrom, pos - 1, pos, truncate=True, stepper="nofilter",
                              min_base_quality=0, max_depth=100000):
            for p in col.pileups:
                r = p.alignment
                # flags REDItools keeps for single-end reads; -C keeps only reads on the site's strand
                if (r.flag in (0, 16) and not p.is_del and not p.is_refskip
                        and r.query_sequence[p.query_position] == ref and r.is_reverse == (strand == "-")):
                    hits.append((r, p.query_position))
        hits.sort(key=lambda h: h[0].query_name)
        free = [h for h in hits if spikes(h[0]) < MAX_NM]
        chosen = random.Random(pos).sample(free, min(len(free), round(LEVELS[i % len(LEVELS)] * len(hits))))
        for r, q in chosen:
            seq, base = r.query_sequence, alt
            if r.is_reverse:
                seq, q, base = seq.translate(COMP)[::-1], len(seq) - 1 - q, alt.translate(COMP)
            edits.setdefault(r.query_name, []).append((seq, q, base))
        truth.append((chrom, pos, strand, f"{len(chosen) / len(hits):.3f}", len(hits)))

    out = Path(outdir)
    out.mkdir(parents=True, exist_ok=True)
    done = 0
    with gzip.open(fastq, "rt") as f, gzip.open(out / Path(fastq).name, "wt", compresslevel=9) as w:
        for head, seq, plus, qual in zip(*[f] * 4):
            raw, new = seq, list(seq)
            for trimmed, off, base in edits.get(head[1:].split()[0].removesuffix("/1"), []):
                start = raw.find(trimmed)   # fastp trimmed the read; place it back in the raw one
                if start < 0:
                    sys.exit(f"{head.strip()}: aligned sequence not in the FASTQ read")
                new[start + off] = base
                done += 1
            w.write(head + "".join(new) + plus + qual)
    want = sum(len(v) for v in edits.values())
    if done != want:
        sys.exit(f"edited {done} of {want} bases: some BAM reads are not in {fastq}")
    with open(out / "spikes.tsv", "w") as w:
        w.write("chrom\tpos\tstrand\tlevel\treads\n")
        w.writelines("\t".join(map(str, t)) + "\n" for t in truth)
    print(f"{len(truth)} sites, {want} bases edited -> {out}")


def check(spikes, calls, tol=0.10):
    called = {(r["Region"], int(r["Position"])): r for r in rows(calls)}
    spiked = list(rows(spikes))
    bad = 0
    for s in spiked:
        c = called.get((s["chrom"], int(s["pos"])))
        level = counts(c)[2] / int(c["Coverage"]) if c and c["Reference"] == "A" else 0.0
        ok = abs(level - float(s["level"])) <= tol
        bad += not ok
        print(f"{s['chrom']}:{s['pos']}{s['strand']}  spiked {float(s['level']):.2f}  called {level:.2f}  {'ok' if ok else 'MISS'}")
    keys = {(s["chrom"], int(s["pos"])) for s in spiked}
    other = [k for k, r in called.items() if k not in keys and r["Reference"] == "A" and counts(r)[2] >= 3]
    print(f"{len(spiked) - bad}/{len(spiked)} spikes within {tol}; {len(other)} other A>G sites with >= 3 G reads")
    return bad == 0


if __name__ == "__main__":
    cmd, *a = sys.argv[1:] or ["-h"]
    if cmd == "make" and len(a) == 4:
        make(*a)
    elif cmd == "check" and len(a) == 2:
        sys.exit(0 if check(*a) else 1)
    else:
        sys.exit(__doc__)
