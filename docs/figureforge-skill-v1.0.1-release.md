# FigureForge Skill 1.0.1 Release Evidence

Date: 2026-07-25

Branch: `codex/figureforge-skill-mvp`

Version: `1.0.1`

Release policy: local commit and local artifacts only; no push, tag, PR, or
MCP implementation.

## Outcome

FigureForge Skill 1.0.1 is an install-shaped, independently usable R/ggplot2
Skill. It installs beneath `.agents/skills/figureforge`, runs without the
private corpus or a source-tree fallback, and keeps every adaptation and
generated output outside the installed Skill.

Release inventory: 15 public cases, 3 authentic open-data cases, 12 synthetic demonstration cases, 24 stress fixtures, and 30 deterministic bilingual forward evaluations.

MCP is planned and unimplemented. This release contains no MCP endpoint,
server, transport, or client configuration.

## Authentic Open-Data Cases

All three cases declare `synthetic_test_fixture: false`,
`scientific_claims: descriptive_only`, `distribution_status: public_ready`,
and `Status: verified`. Human review covered data, visual fidelity,
reproducibility, export, and limits.

| Case | Publisher and attribution | License | Upstream SHA-256 | Normalized SHA-256 | Human QA |
| --- | --- | --- | --- | --- | --- |
| `authentic-palmer-penguins-scatter` | Allison Horst and palmerpenguins contributors; data collected by Dr. Kristen Gorman and Palmer Station LTER | CC0-1.0 | `f204db2c753b0937caac3cb35258562c14f073e4bbc76be24b4c51ce22767a93` | `86071627c1cbbd8492763e3a8eb8efc0961f6bfea689dc21f8946e56d401e78e` | verified; 333 complete rows and independent PDF/PNG inspection |
| `authentic-usgs-earthquakes-bubble` | U.S. Geological Survey Earthquake Hazards Program | public domain | `39d0e2be2a0c36784fd7ff8b9335e43fa7583b65dbb3db79ddda65423c55148d` | `74f833c5a61a9d4d784fc9dfc80d061e4b1ba2523087e0302ad7f785f1c63f5e` | verified; 133 fixed-query rows and independent PDF/PNG inspection |
| `authentic-world-bank-population-timeseries` | World Bank, Population total `SP.POP.TOTL`, API snapshot retrieved 2026-07-25 | CC-BY-4.0 | `0c516b92077b8cb39972a34a3be14230a84adcbed3db921023b9182e9068e9d0` | `ad9749b12908ac679a9fce4e1ba91e72fdeb260a1a14de958e289488a088427a` | verified; 120 country-year rows and independent PDF/PNG inspection |

The remaining 12 public cases are synthetic demonstration cases. Their
metadata keeps QA at `review_required`, declares no scientific claim, and
exists to demonstrate schema mapping, rendering, and safety behavior.

## Evaluation Evidence

The deterministic catalog contains 15 English and 15 Chinese rows:

| Gate | Result | Required threshold |
| --- | ---: | ---: |
| Total deterministic rows | 30/30 passed | all hard gates |
| Top-1 selection | 100% | at least 80% |
| Top-3 selection | 100% | 100% |
| Valid mapping | 100% | 100% |
| Independent render | 100% | 100% |
| Exact safe rejection | 100% | 100% |
| Explicit live trigger | 1/1 | 100% |
| Implicit live trigger | 10/10 | at least 90% |

The six exact rejection categories are `missing_required_role`,
`incompatible_type`, `incompatible_cardinality`, `protected_output`,
`private_asset`, and `unsafe_transformation`. Raw live transcripts remain in
the ignored local directory
`/tmp/figureforge-v101.PkhJDS/live-evals/` and are not packaged or committed.
An earlier qualification run passed 9/10 implicit probes; the final complete
release gate passed all 10/10.

## Runtime, Installation, and Upgrade

Rscript resolution is:

1. explicit `--rscript`;
2. `FIGUREFORGE_RSCRIPT`;
3. `/usr/local/bin/Rscript` as a compatibility path; and
4. `Rscript` on `PATH`.

The installation archive is rooted at `figureforge/`:

```bash
mkdir -p .agents/skills
tar -xzf /tmp/figureforge-skill-1.0.1.tar.gz -C .agents/skills
test -s .agents/skills/figureforge/SKILL.md
```

The v1.0.0-to-v1.0.1 test exports commit `fe00d2a`, records the hashes of an
external time-series adaptation, verifies a sibling v1.0.1 stage, moves the
exact installed target to a target-specific backup, atomically renames the
stage, and removes only that exact backup after success. It proves:

- the installed `VERSION` is `1.0.1`;
- no v1.0.0-only package file remains;
- the external `input.csv` and `mapping.md` hashes are unchanged; and
- doctor, search, adaptation validation, and independent rendering still pass.

## Release Verification Commands

```bash
Rscript skills/figureforge/scripts/package_skill.R \
  --archive /tmp/figureforge-skill-1.0.1.tar.gz \
  --manifest /tmp/figureforge-skill-1.0.1-manifest.csv

Rscript skills/figureforge/scripts/verify_release.R \
  --archive /tmp/figureforge-skill-1.0.1.tar.gz \
  --manifest /tmp/figureforge-skill-1.0.1-manifest.csv \
  --extract-dir /tmp/figureforge-skill-1.0.1-verified

Rscript skills/figureforge/scripts/evaluate_skill.R \
  --catalog skills/figureforge/references/trigger-evals-v1.csv \
  --output-dir /tmp/figureforge-forward-evals \
  --report /tmp/figureforge-forward-evals.csv \
  --rscript "${FIGUREFORGE_RSCRIPT:-Rscript}"

bash scripts/run_figureforge_live_evals.sh \
  --output-dir outputs/figureforge-v101/live-evals/manual
```

The archive verifier requires the adjacent `.sha256` sidecar and rejects
missing, extra, duplicate, absolute, parent-traversal, symlink/non-regular,
empty, byte-mismatched, or checksum-mismatched members.

## Approved-Design Traceability

| Design area | Evidence |
| --- | --- |
| Install-shaped package | `test_install_smoke.R`; archive members start at `figureforge/` |
| Location-independent installed runtime | installed doctor, search, demo, and validation tests |
| Portable Rscript resolution | `test_runtime_resolution.R` covers CLI, environment, compatibility path, PATH, old R, and missing R |
| Authentic public data | three `source.yml` contracts, fixed hashes, distribution validation, manual QA |
| Synthetic stress behavior | 24/24 stress fixtures pass across the 12 synthetic families |
| Forward behavior | 30/30 deterministic bilingual evaluations pass |
| Trigger behavior | explicit 1/1 and implicit 10/10 final live probes pass |
| Archive integrity | sidecar plus structural, byte, and per-member SHA-256 verification |
| Upgrade | `test_upgrade_compatibility.R` preserves external adaptation state and removes stale files |
| Private boundary | tracked/package scans contain no private case, source figure, reproduction, output, log, render, or raw transcript |
| MCP boundary | planned and unimplemented; no MCP runtime is included |

## Local Commit Chain

- `d2fc5f0` — v1.0.1 hardening design
- `79c3c00` — v1.0.1 implementation plan
- `e6212b9` — install-shaped Skill package
- `ba5681a` — portable Rscript resolution
- `e58e3f8` — authentic public provenance contract
- `89ead27` — three authentic public visualization cases
- `2eaee2b` — deterministic bilingual forward evaluations
- `4aebf0d` — Skill triggering and live probe harness
- `db7c9b7` — release archive verification
- `da019c4` — v1.0.0 upgrade compatibility
- release certification — the commit containing this document, reported in
  the final handoff because a commit cannot contain its own hash

No commit was pushed.

## Private Corpus Boundary

The local corpus remains 165 private case directories: 152 completed, 13 with
validated blockers, and 0 pending. Those cases, third-party source images,
reproductions, generated indexes, audit reports, renders, logs, and live
transcripts are excluded from both Git and the release package. Only the
public `_template` is distributable from `skills/figureforge/cases/`.

## Final Artifact Location

The final live-enabled verifier completed with:

```text
Verification artifacts: /tmp/figureforge-v101.PkhJDS
FigureForge Skill v1.0.1 acceptance: PASS
```

Concrete release artifacts:

- archive:
  `/tmp/figureforge-v101.PkhJDS/figureforge-skill-1.0.1.tar.gz`;
- manifest:
  `/tmp/figureforge-v101.PkhJDS/figureforge-skill-1.0.1-manifest.csv`;
- checksum:
  `/tmp/figureforge-v101.PkhJDS/figureforge-skill-1.0.1.tar.gz.sha256`;
- archive SHA-256:
  `eaac441c1681a9ee84215eb6226e0f75fa85bc9981bc520b900b39ae34353d25`;
- installed Skill:
  `/tmp/figureforge-v101.PkhJDS/installed-project/.agents/skills/figureforge`;
- deterministic reports and renders:
  `/tmp/figureforge-v101.PkhJDS/`; and
- live summaries and raw transcripts:
  `/tmp/figureforge-v101.PkhJDS/live-evals/`.

The preceding deterministic-only acceptance also passed and remains at
`/tmp/figureforge-v101.eCxNfE`.
