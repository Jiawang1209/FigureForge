# FigureForge Skill 1.1.0 Release Evidence

> Historical certification snapshot: this document and its portable evidence
> bind the source and package identities recorded below. The current
> FigureForge source has since changed and is pending recertification. Follow
> the [current-source recertification procedure](figureforge-skill-v1.1.0-recertification.md)
> and require the identity checker to report `CURRENT` before presenting this
> evidence as certification of the current source.

Date: 2026-07-26

Branch: `codex/figureforge-v110`

Version: `1.1.0`

Release policy: local commit and local artifacts only. This certification does
not push a branch, create or push a tag, open a PR, or publish a remote release.

The durable [portable certification evidence](figureforge-skill-v1.1.0-evidence/README.md)
contains machine-readable summaries, exact commands and evidence timestamps,
the observed environment, immutable source bindings, artifact/package
identities, sanitized logs, and SHA-256 checks. Temporary directories below are
retained only as local provenance; they are not the sole release evidence.

## Immutable Tested Source

The real live gates ran from a clean worktree at commit
`2f92d6370563a12862c111d61f3831c83da8b025`, complete tree
`b17435309d9d8e4a967d8211e5b7c4e35e323389`. The exact Skill subtree and
harness blob identities are recorded in
[`source-binding.tsv`](figureforge-skill-v1.1.0-evidence/source-binding.tsv).

The live gates predate the certification-document commits. They are not claimed
to have run on the later documentation HEAD. Commits `2983880` and `f475a30`
changed README, evidence documentation, and documentation tests only; the
tested Skill, both live harnesses, verifier, and package builder stayed
byte-identical to the bound clean source. Runtime and model observability are
recorded in
[`environment.tsv`](figureforge-skill-v1.1.0-evidence/environment.tsv):
`/Users/liuyue/.local/bin/codex`, Codex CLI 0.145.0,
`/usr/local/bin/Rscript`, R 4.6.1, and macOS 26.3.1 on arm64. The live command
used the configured default model without `--model`; the resolved model name
was not exposed by the retained CLI JSONL, so no model name is guessed.

## Product Definition and Artifact Contract

This historically certified FigureForge Skill 1.1.0 source snapshot is a
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

The final post-documentation certification verifier observed before the
certification evidence commit retained its artifacts at
`/tmp/figureforge-v110.RMisRW` and ended with the exact line:

```text
FigureForge Skill v1.1.0 acceptance: PASS
```

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
The repository-tracked
[`live-trigger-summary.csv`](figureforge-skill-v1.1.0-evidence/live-trigger-summary.csv)
is the portable copy validated by the documentation test.

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
The repository-tracked
[`live-plotting-summary.csv`](figureforge-skill-v1.1.0-evidence/live-plotting-summary.csv)
and
[`artifact-identities.tsv`](figureforge-skill-v1.1.0-evidence/artifact-identities.tsv)
preserve the portable result and artifact identities without committing input
data or generated binaries.

The harness independently reran the delivered script into
`/tmp/figureforge-v110-live.740e78/plotting/independent-rerender`. Both
independent `plot.png` and `plot.pdf` are nonempty and valid, and
`independent-rerender-status.txt` records exit status `0`.

Evidence locations:

- portable evidence:
  [`docs/figureforge-skill-v1.1.0-evidence/`](figureforge-skill-v1.1.0-evidence/README.md);
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

The canonical release identity is the manifest SHA-256:
`12752a5688f4939a6d5deb72a60cbc2587077d6ad0672d9ea8218d021ecf0398`.
The baseline, pre-certification, and independent-review manifests are
byte-identical. Their compressed archive hashes differ because this packaging
pipeline does not promise deterministic gzip/tar metadata. The stable manifest
fixes every member path, byte count, and member SHA-256; the three run-specific
archive hashes and the nondeterminism explanation are recorded in
[`package-identities.tsv`](figureforge-skill-v1.1.0-evidence/package-identities.tsv).

The strict verifier rejects missing, extra, duplicate, empty, absolute,
parent-traversal, symlink, byte-mismatched, and checksum-mismatched members.
The installed package passed official validation, doctor, search, demo,
adaptation validation, and rerender checks without a source-tree fallback.

## Private and MCP Boundaries

The 165-case private corpus, third-party source figures, reproductions,
generated outputs, raw or unsanitized evaluation logs, and raw live transcripts
remain outside Git and the release archive. The portable evidence bundle
contains tracked sanitized certification logs with only aggregate gate results
and source/artifact identities; they contain no raw prompt, transcript, user
data, or private-corpus content. The preserved private-corpus status is 152
completed cases, 13 evidence-backed blockers, and 0 pending cases. Only
reviewed public assets are packaged.

MCP is planned and unimplemented. FigureForge Skill 1.1.0 contains no MCP
server, endpoint, transport, or client configuration.

FigureForge Skill 1.0.1 remains the prior certified historical release. No
push, tag, or PR was performed for this local v1.1.0 certification.

## Certification

The deterministic verifier and both real bounded live gates passed without
lowering any trigger, artifact, archive, rerender, or private-boundary
requirement.

FigureForge Skill v1.1.0 acceptance: PASS
