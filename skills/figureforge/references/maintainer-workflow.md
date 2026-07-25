# Maintainer Workflow

This document is for FigureForge maintainers. These corpus, evidence, and
release procedures are not requirements for an ordinary user plotting task.

## Case Lifecycle

Use the lifecycle tools at their tracked paths:

- `scripts/validate_case.R` checks private case structure, completion, and
  rendering evidence.
- `scripts/validate_public_case.R` checks the public case contract.
- `scripts/validate_distribution.R` checks redistribution declarations and
  asset boundaries.
- `scripts/index_cases.R` rebuilds a deterministic case catalog.
- `scripts/audit_cases.R` audits corpus readiness and fresh rendering.

Follow [Gallery Index](gallery-index.md), [QA Checklist](qa-checklist.md), and
[Adaptation Contract](adaptation-contract.md) for detailed evidence contracts.

## Terminal Outcomes

Use `scripts/validate_blocker.R` to validate a supported blocker and
`scripts/plan_case_batches.R` to plan deterministic evidence-first work. Corpus
processing reports `terminal_outcome` as completed, blocked, or pending.
`blocked_source_missing` is reserved for missing authentic source material, not
time or workload. A verified QA and a valid blocker cannot coexist.

Follow the [Blocker Contract](blocker-contract.md) for required statuses,
evidence, contradiction checks, and batch-planning details.

## Evaluation

Use `scripts/run_stress_tests.R` and `scripts/evaluate_skill.R` to evaluate
behavior. Stress suites may use synthetic fixtures, but those fixtures make no
scientific or provenance claims. `review_required` remains the safe status
until authorized visual review. Automated checks never promote
`review_required` to `verified`.

## Release

Build distributable archives with `scripts/package_skill.R` and certify them
with `scripts/verify_release.R`. Verify archive members, sidecar files, member
sizes, and hashes against the manifest. Private and generated content must
remain excluded from the package.

Use the repository release documentation and
[Theme and Export](theme-and-export.md) for the detailed packaging, artifact,
and rendering contracts.
