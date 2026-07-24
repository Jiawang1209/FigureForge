# Blocker Contract

A private case may be marked blocked only after authentic completion remains
unsafe despite concrete recovery attempts. Workload, elapsed time, or slow
dependency installation are not blockers.

## Supported Statuses

- `blocked_source_missing`: required authentic data or source code is absent.
- `blocked_dependency`: a required historical dependency cannot be recovered.
- `blocked_visual_reference`: no trusted reference exists for visual QA.
- `blocked_corrupt_asset`: required source material is unreadable or damaged.
- `blocked_ambiguous_mapping`: source fields cannot be mapped without guessing.
- `blocked_rights`: rights restrictions prohibit the required processing.

## Required blocker.md Structure

```markdown
# FigureForge Case Blocker

Status: blocked_source_missing

## Files Inspected

## Commands Run

## Recovery Attempts

## Why Unsafe To Infer

## Unblock Requirement
```

Every section must contain case-specific evidence. Empty sections, template
language, and unsupported statuses fail validation. A verified QA and a valid blocker cannot coexist.

## Validation

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/validate_blocker.R \
  "<case_dir>"
```

The validator checks the file, status, headings, evidence, and contradiction
with `qa.md`.

## Audit Outcome

The corpus audit reports:

- `blocked`: the blocker contract passes;
- `blocked_status`: one supported status;
- `blocked_summary`: the first concrete unsafe-inference statement;
- `processed`: the case is completed or validly blocked;
- `terminal_outcome`: `completed`, `blocked`, or `pending`.

A malformed blocker remains `pending`; its mere presence proves nothing.

## Deterministic Waves

After a full rendered audit, create an ignored batch manifest:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/plan_case_batches.R \
  --readiness outputs/figureforge-audit/case-readiness.csv \
  --output outputs/figureforge-audit/batch-manifest.csv \
  --batch-size 20
```

The planner excludes `processed` cases and prioritizes reproduction evidence,
authentic source scripts, source data, and current runnability.
