# FigureForge Visual QA Report Schema v1

The visual QA assistant emits JSON with `schema_version: 1`. Its top-level
`status` is restricted to `review_required`, `tool_check_failed`, or
`not_applicable`.

The `render` object records path, format, bytes, width, height, and page count.
The `checks` array records a stable check ID, `pass`, `warning`, `error`, or
`not_applicable`, plus a short detail. `reference_comparison` records whether
dimensions match when both files expose dimensions.

`manual_review_prompts` lists visual and scientific decisions that still need a
human reviewer. The report is evidence for review; it is never an approval
record and never modifies a case or adaptation `qa.md`.
