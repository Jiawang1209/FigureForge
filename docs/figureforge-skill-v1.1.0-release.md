# FigureForge Skill 1.1.0 Release Evidence

Date: 2026-07-26

Branch: `codex/figureforge-v110`

Version: `1.1.0`

Release policy: local commit and local artifacts only. This certification does
not push a branch, create or push a tag, open a PR, or publish a remote release.

## Product Definition and Artifact Contract

FigureForge Skill 1.1.0 is the current locally certified release of the
case-enhanced R scientific plotting capability. It accepts a natural-language
plotting request plus real data, uses one primary public case and optional
secondary cases as experience, and delivers exactly the reusable artifact
contract:

- `plot.R`;
- `plot.png`; and
- `plot.pdf`.

The delivered script must read the real input and rerun outside the installed
Skill as:

```bash
Rscript plot.R <input-file> <output-directory>
```

The real plotting gate also requires an independent rerender into a fresh
directory and validates both the resulting PNG and PDF.

## Deterministic Verification

All 28 `tests/figureforge/*.R` scripts other than the recursive
`test_v1_acceptance.R` passed in a fresh baseline run. The full deterministic
v1.1.0 verifier was then run with live evaluations disabled:

```bash
FIGUREFORGE_RUN_LIVE_EVALS=0 /bin/sh scripts/verify_figureforge_v110.sh
```

That verifier passed the R test suite, 15 public cases with fresh external
renders, 24 synthetic stress fixtures, 30 deterministic bilingual forward
evaluations, doctor output, strict package verification, installed-package
validation, the public demo, delivered-script validation and rerender, upgrade
compatibility, tracked-R parsing, and the private/generated boundary.

The first complete deterministic verifier retained its artifacts at:

```text
Verification artifacts: /tmp/figureforge-v110.4Ywsys
FigureForge Skill v1.1.0 acceptance: PASS
```

After the release evidence and status documentation were added, the complete
no-live verifier was run again and retained the post-documentation artifacts
at `/tmp/figureforge-v110.lRin35`; it ended with the same exact acceptance
line.

## Real Live Trigger Evidence

The live trigger gate used the current `codex` executable and its default
configured model. No fake Codex executable or parser fixture was used. It ran
in a new empty temporary root:

```bash
bash scripts/run_figureforge_live_evals.sh \
  --output-dir /tmp/figureforge-v110-live.740e78/triggers
```

The summary contains exactly 11 rows: one explicit probe and ten implicit
probes. Every passing row has exit status zero, a real installed
`.agents/skills/figureforge/SKILL.md` read event, FigureForge capability
selection, and all three artifact names: `plot.R`, `plot.png`, and `plot.pdf`.

| Gate | Actual result | Required threshold |
| --- | ---: | ---: |
| Explicit live trigger | 1/1 | 1/1 |
| Implicit live trigger | 10/10 | at least 9/10 |

The summary, eleven JSONL transcripts, eleven final replies, installed package,
manifest, archive, checksum sidecar, prompts, and stderr logs are retained at
`/tmp/figureforge-v110-live.740e78/triggers`.

## Real Live Plotting and Rerender Evidence

The plotting gate used the same real Codex installation and a separately
installed FigureForge package:

```bash
bash scripts/run_figureforge_plotting_eval.sh \
  --output-dir /tmp/figureforge-v110-live.740e78/plotting
```

Its summary contains exactly one row with `passed=true`. The transcript records
a real installed Skill read event. The agent inspected the supplied real CSV,
wrote and ran a nonempty 5,861-byte `plot.R`, and delivered a valid 4320 by 3120
PNG plus a valid one-page PDF. The delivered `plot.R` reruns successfully.

The harness independently reran the delivered script into
`/tmp/figureforge-v110-live.740e78/plotting/independent-rerender`. Both
independent `plot.png` and `plot.pdf` are nonempty and valid, and
`independent-rerender-status.txt` records exit status `0`.

Evidence locations:

- live root: `/tmp/figureforge-v110-live.740e78`;
- plotting transcript and summary:
  `/tmp/figureforge-v110-live.740e78/plotting`;
- retained audit workspace: `/tmp/figureforge-plotting-eval.Tt6tlo`;
- delivered artifacts:
  `/tmp/figureforge-plotting-eval.Tt6tlo/figureforge-output`; and
- independent rerender:
  `/tmp/figureforge-v110-live.740e78/plotting/independent-rerender`.

## Platform Counts and Release Package

The accepted v1.1.0 platform retains the established public evaluation counts:

- 15 public cases: 3 authentic open-data cases and 12 synthetic demonstration
  cases;
- 24 synthetic stress fixtures across the 12 synthetic public families; and
- 30 deterministic bilingual forward evaluations with all hard gates passed.

The deterministic verifier produced an install-shaped `figureforge/` archive
with 156 nonempty public files, a 156-row manifest, and an adjacent SHA-256
sidecar:

- archive:
  `/tmp/figureforge-v110.4Ywsys/figureforge-skill-1.1.0.tar.gz`;
- manifest:
  `/tmp/figureforge-v110.4Ywsys/figureforge-skill-1.1.0-manifest.csv`;
- sidecar:
  `/tmp/figureforge-v110.4Ywsys/figureforge-skill-1.1.0.tar.gz.sha256`;
- archive SHA-256:
  `cfe744653676ce11659b8251daf0c2fd21f33d0a92adfb803902c5b5a214f335`;
- verified installed Skill:
  `/tmp/figureforge-v110.4Ywsys/installed-project/.agents/skills/figureforge`.

The strict verifier rejects missing, extra, duplicate, empty, absolute,
parent-traversal, symlink, byte-mismatched, and checksum-mismatched members.
The installed package passed official validation, doctor, search, demo,
adaptation validation, and rerender checks without a source-tree fallback.

## Private and MCP Boundaries

The 165-case private corpus, third-party source figures, reproductions,
generated outputs, logs, and raw live transcripts remain outside Git and the
release archive. The preserved private-corpus status is 152 completed cases,
13 evidence-backed blockers, and 0 pending cases. Only reviewed public assets
are packaged.

MCP is planned and unimplemented. FigureForge Skill 1.1.0 contains no MCP
server, endpoint, transport, or client configuration.

FigureForge Skill 1.0.1 remains the prior certified historical release. No
push, tag, or PR was performed for this local v1.1.0 certification.

## Certification

The deterministic verifier and both real bounded live gates passed without
lowering any trigger, artifact, archive, rerender, or private-boundary
requirement.

FigureForge Skill v1.1.0 acceptance: PASS
