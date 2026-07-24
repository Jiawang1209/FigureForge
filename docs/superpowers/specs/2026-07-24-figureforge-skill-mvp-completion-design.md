# FigureForge Skill MVP Completion Design

Date: 2026-07-24

## Goal

Complete FigureForge as a verifiable, independently usable Skill MVP before
implementing any MCP server.

The work has three sequential stages:

1. Audit all private local cases with explicit evidence and select the MVP set.
2. Develop 12–20 authentic cases to the completed-case contract.
3. Prove the Skill workflow with three adaptations to previously unseen data.

The MCP package remains out of scope until all Skill acceptance criteria pass.

## Current Reality

The local case corpus contains 165 real case directories. Every directory now
contains `case.md`, `data.csv`, and `plot.R`, but most of those files were
created by `standardize_remaining_cases.R`. That script infers a broad chart
family from the directory name and creates synthetic data, a generic plotting
script, and scaffold metadata. Those files are useful inventory scaffolds, not
evidence that the original figure was reproduced.

The existing validator proves only that required files and Markdown headings
exist. It does not prove that:

- metadata describes the original case accurately;
- `data.csv` came from authentic source data;
- `plot.R` implements the original visual structure;
- rendering succeeds in the current environment;
- a reproduction output exists and was visually reviewed;
- redistribution is allowed.

The full corpus and generated indexes are gitignored. A fresh checkout also
lacks the case template, which means the current public Skill cannot be
validated independently.

## Scope Decomposition

### Stage A: Completion Contract And Read-Only Audit

Create a tracked audit tool and fixture-based tests. Run the tool against the
private corpus without modifying case directories. Save local reports under
`outputs/figureforge-audit/`, which must remain untracked.

Stage A produces the evidence used to choose the MVP. It does not claim any
case is visually verified.

### Stage B: Authentic MVP Case Development

Select 12–20 representative cases only after Stage A. For each selected case,
preserve raw files and replace generated scaffolds with authentic normalized
inputs, case-specific scripts, dependency declarations, rendered
reproductions, and QA records.

Stage B will receive its own implementation plan because exact files,
dependencies, and verification commands depend on Stage A evidence.

### Stage C: Skill Workflow And Adaptation Proof

Complete the Skill instructions and helper tooling, then adapt at least three
different completed cases to new datasets. Save mappings, commands, rendered
outputs, and QA evidence.

Stage C will receive its own implementation plan after the MVP set is stable.

## Case Evidence Model

The audit classifications are independent booleans rather than one mutually
exclusive status. A case may be both `raw` and `scaffolded`, or both `runnable`
and `private_only`.

| Field | Evidence required |
| --- | --- |
| `raw` | One or more source assets beyond canonical `case.md`, `data.csv`, and `plot.R` |
| `scaffolded` | Known generated text or script markers from `standardize_remaining_cases.R` |
| `runnable` | A fresh audit render exits successfully and creates a non-empty output outside the case directory |
| `reproduced` | A non-empty `reproduction.png`, `reproduction.pdf`, or `reproduction.svg` exists |
| `qa_verified` | A `qa.md` record contains `Status: verified` and all required QA sections |
| `public_ready` | A `distribution.yml` record explicitly says `redistribution: allowed` and names the reviewed assets |
| `private_only` | Public readiness is absent or denied; this is the safe default |

The report also records structural checks, detected source assets, render exit
status, missing evidence, and a conservative recommended next action.

## Completed Case Contract

A completed FigureForge case must:

1. Retain the original raw source files without destructive rewriting.
2. Use accurate, case-specific metadata with no scaffold markers.
3. Provide normalized `data.csv` derived from or documented against authentic
   source data.
4. Provide a case-specific `plot.R` that accepts input and output paths.
5. Declare required R packages in `case.md`.
6. Render successfully through the FigureForge render wrapper.
7. Produce a non-empty reproduction artifact.
8. Record QA evidence in `qa.md`.
9. Record distribution review in `distribution.yml`; absence means
   `private_only`.

Structural validation, successful execution, and visual QA remain separate
claims. A successful render alone does not prove visual fidelity.

## Audit Interface

The tracked command will be:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/audit_cases.R \
  --cases-dir /absolute/path/to/private/cases \
  --output-dir /absolute/path/to/outputs/figureforge-audit \
  --rscript /usr/local/bin/Rscript \
  --render
```

Outputs:

- `case-readiness.csv`: one evidence row per real case;
- `summary.md`: counts, caveats, and recommended next actions;
- `render-logs/`: per-case stdout, stderr, and render status;
- `rendered/`: temporary audit renders, never written into source cases.

The tool must skip `_template`, use deterministic ordering, quote paths safely,
and continue after individual case failures.

## Public Checkout Contract

The public repository will gain:

- a tracked `_template` case that is explicitly not a curated case;
- tracked sanitized test fixtures outside the private corpus;
- a deterministic audit test runner using base R;
- an ignored `outputs/` directory.

No private case, raw dataset, source image, generated private index, or local
audit report will be committed.

## Testing

Stage A tests use temporary copies of small synthetic fixtures and prove:

- `_template` is excluded;
- scaffold markers are detected;
- source assets set `raw`;
- missing distribution review defaults to `private_only`;
- explicit allowed distribution sets `public_ready`;
- reproduction and QA evidence are distinguished;
- render success requires both exit status zero and a non-empty output;
- a failed case does not abort the full audit;
- CSV and Markdown reports are deterministic.

Tests must observe RED before implementation and pass with
`/usr/local/bin/Rscript`.

## Error Handling

- A missing cases directory is a command error with a non-zero exit.
- An empty corpus produces valid empty reports plus a warning.
- A malformed metadata record is reported per case and defaults conservatively.
- A render failure is recorded, not promoted to a process-wide failure.
- The audit never edits, deletes, or creates files under a case directory.

## Acceptance Criteria

Stage A is complete only when:

- tests pass from a fresh worktree;
- the tracked template renders successfully;
- the audit reports exactly 165 private real cases;
- every case has values for all seven evidence classifications;
- audit outputs stay untracked;
- no private case content enters the Git diff;
- the report explicitly distinguishes scaffold, execution, reproduction,
  visual QA, and distribution evidence.

The full Skill MVP goal remains active after Stage A.
