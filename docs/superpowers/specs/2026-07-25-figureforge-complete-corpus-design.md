# FigureForge Complete Corpus Design

Date: 2026-07-25

## Goal

Turn the existing 165-case private FigureForge corpus into a completely
processed evidence base for one independently usable FigureForge Skill.
Preserve the 15 verified cases, develop every remaining case that can be
completed authentically, and record machine-readable blocker evidence for
cases that cannot be completed safely.

The MCP server remains out of scope.

## Approved Baseline

- Public code worktree:
  `/Users/liuyue/Desktop/Github_repos/FigureForge/.worktrees/figureforge-skill-mvp`
- Public branch: `codex/figureforge-skill-mvp`
- Skill MVP baseline commit: `2b685b6`
- Private corpus:
  `/Users/liuyue/Desktop/Github_repos/FigureForge/skills/figureforge/cases`
- Real case directories: 165
- Completed `runnable + reproduced + qa_verified` cases: 15
- Remaining cases: 150
- Scaffold markers present: 147
- Reproduction artifacts present: 107
- Distribution state: 165 `private_only`, 0 `public_ready`

The private corpus remains gitignored. Public tooling, fixtures, tests, schema
references, and documentation live in the public worktree.

## Approaches Considered

### One long sequential pass

Process directory names in lexical order. This is easy to track but spends
early effort on cases with missing assets while source-rich cases remain
unfinished. It also produces uneven chart-family coverage.

### Automation-first standardization

Generate normalized data, metadata, plots, and QA from filenames and broad
chart families. This is fast but repeats the existing failure mode: runnable
scaffolds are mistaken for authentic case development. This approach is
rejected.

### Evidence-first waves

Rank cases by reproduction evidence, authentic source data, original plotting
code, dependency availability, and missing chart-family coverage. Process
15–25 cases per wave, validate each case independently, refresh the 165-case
audit after every wave, and leave explicit blocker records only after recovery
attempts are exhausted.

This is the selected approach because it maximizes verified progress while
preserving the completed-case contract.

## Architecture

### Public control plane

Tracked FigureForge scripts provide:

- read-only corpus audit;
- completed-case validation and rendering;
- blocker-record parsing and validation;
- deterministic batch candidate ranking;
- local index generation and search;
- dependency checks;
- fixture-based regression tests.

Public tooling must never embed private case names, data, images, or absolute
private paths in tracked outputs.

### Private evidence plane

Each private case ends in exactly one terminal processing outcome:

1. **Completed:** authentic metadata, normalized data, standard-argument
   plotting code, reproduction evidence, fresh render, and verified visual QA.
2. **Blocked:** a `blocker.md` record names one approved blocker category,
   evidence inspected, commands run, recovery attempts, why inference would be
   unsafe, and the exact requirement for unblocking.

A case may remain `private_only` in either outcome. Distribution is independent
of completion.

### Ignored operational outputs

`outputs/figureforge-audit/` stores:

- `case-readiness.csv`;
- `summary.md`;
- per-case render logs and external renders;
- batch manifests and progress reports;
- visual-review previews;
- blocker summaries.

Generated paths and case metadata remain ignored.

## Evidence Model

Existing independent evidence fields remain:

- `raw`
- `scaffolded`
- `runnable`
- `reproduced`
- `qa_verified`
- `public_ready`
- `private_only`

The audit adds:

- `blocked`: a structurally valid blocker record exists;
- `blocked_status`: one approved blocker category;
- `blocked_summary`: concise reason;
- `processed`: either completed or validly blocked;
- `terminal_outcome`: `completed`, `blocked`, or `pending`.

Approved blocker categories:

- `blocked_source_missing`
- `blocked_dependency`
- `blocked_visual_reference`
- `blocked_corrupt_asset`
- `blocked_ambiguous_mapping`
- `blocked_rights`

`processed` is true only when:

```text
(runnable AND reproduced AND qa_verified AND NOT scaffolded)
OR valid blocker.md
```

Workload, elapsed time, or a difficult dependency is not blocker evidence.

## Blocker Record Contract

Private blocked cases use `blocker.md`:

```markdown
# FigureForge Case Blocker

Status: blocked_source_missing

## Files Inspected

## Commands Run

## Recovery Attempts

## Why Unsafe To Infer

## Unblock Requirement
```

Every section must contain concrete case-specific evidence. Template text,
empty sections, or unsupported categories fail validation. A case with
`Status: verified` in `qa.md` cannot simultaneously be terminally blocked.

## Batch Selection

Candidate ranking is deterministic and favors:

1. reproduction evidence;
2. authentic source scripts such as `R.R` or `source-script.R`;
3. non-canonical source data;
4. installed declared dependencies;
5. missing chart-family coverage;
6. lower recovery complexity.

Wave order:

- **Wave 1:** 15–25 source-rich reproduced cases that broaden common chart
  families.
- **Waves 2–5:** remaining reproduced cases, grouped by related plotting
  ecosystem and dependency stack.
- **Later waves:** cases without reproduction evidence and historical or
  difficult dependencies.
- **Final wave:** unresolved source, corruption, ambiguity, reference, rights,
  or dependency cases receive completed recovery attempts and blocker records.

Previously verified cases are excluded unless a regression is found.

## Per-Case Development Protocol

For each selected case:

1. Inventory raw files and preserve file hashes or mtimes before work.
2. Read all relevant source plotting code and authentic input data.
3. Open the authentic reference or reproduction and identify visible grammar.
4. Replace scaffold metadata with case-specific bilingual discovery metadata.
5. Normalize authentic inputs to `data.csv`, documenting every transform.
6. Refactor authentic plotting logic into standard `input_path` and
   `output_path` arguments.
7. Declare and check R package dependencies.
8. Render externally with `/usr/local/bin/Rscript`.
9. Compare the fresh render against authentic visual evidence.
10. Write `qa.md` only after visual review.
11. Run complete validation with an output outside the case.
12. Confirm original source assets remain present and unmodified.

No generated generic dataset or generic chart-family script may satisfy this
protocol.

## Error Handling

- Missing or malformed blocker records remain `pending`.
- A failed render records the exact status and log without aborting the corpus
  audit.
- Missing packages trigger recovery investigation before blocker
  classification.
- Unreadable source files retain their original bytes and receive external
  diagnostics.
- Ambiguous data joins or field mappings stop case development rather than
  permitting inferred values.
- Distribution remains `private_only` unless independently approved.

## Testing

Public changes follow RED–GREEN–REFACTOR:

1. add fixtures for valid, malformed, contradictory, and unsupported blocker
   records;
2. verify tests fail because blocker support is absent;
3. implement parsing, validation, report fields, and batch ranking;
4. run focused tests, then all FigureForge tests;
5. parse all public R files;
6. run official Skill validation;
7. verify public behavior from a clean local clone.

Private cases use render and visual evidence rather than public fixtures.

## Documentation

README files and Skill status documentation report:

- completed, blocked, and pending counts;
- chart-family coverage;
- exact public commands;
- conservative private/public boundaries;
- MCP as planned and unimplemented.

Public documentation reports aggregate counts and public dataset proofs. It
does not publish private source data or restricted case images.

## Completion Criteria

The complete-corpus goal finishes only when:

- all 165 real case directories have `terminal_outcome` equal to `completed`
  or `blocked`;
- every completed case is non-scaffolded, runnable, reproduced, and
  QA-verified;
- every blocked case has a valid, case-specific evidence record after
  reasonable recovery attempts;
- no case remains uninspected or pending;
- public tests, R parsing, Skill validation, and clean-clone verification pass;
- generated private reports and assets remain untracked;
- bilingual documentation matches the final audit;
- local public commits exist and nothing is pushed;
- no MCP implementation has been added.
