# Case Use Contract

After inspecting the real data and searching the gallery, choose exactly one
generation mode: `case_based` or `general_fallback`. Keep the audit record at
`.figureforge/case-trace.yml` under the output directory. It is hidden workflow
state and is not a fourth user-visible deliverable.

## `case_based`

Use this mode only when one primary case is sufficiently relevant and readable.
Actually read its `case.md` and `plot.R`; also read `qa.md` when it exists.
Secondary cases may inform local patterns, but the trace and claim bind to the
primary case.

Before claiming case-grounded use:

1. Record a concrete `schema_mapping` from the user's columns or roles to the
   primary case roles.
2. Record each borrowed choice in `adopted_patterns` using
   `<case evidence>#source anchor => plot.R#generated executable anchor`.
   The source evidence must be `case.md`, `plot.R`, or an available `qa.md`;
   the generated anchor must name executable code in the delivered `plot.R`.
3. Record `departures`, including renamed roles, changed transformations,
   omitted layers, different packages, or other deliberate differences.
4. Hash the generated script and the case evidence files in the trace.
5. Validate with both the real case directory and generated script:

```bash
Rscript "$FIGUREFORGE_SKILL_ROOT/scripts/validate_case_trace.R" \
  <output-directory>/.figureforge/case-trace.yml \
  --case-dir "<primary-case-directory>" \
  --script "<output-directory>/plot.R"
```

Only exit status zero with `Verification level: strict` authorizes
`claim: case_grounded`. `structural` and `partial` checks are diagnostic only
and never authorize a case-grounded claim.

When `qa.md` exists, read it and hash it. Read the unique `Status:` marker; it
must be `verified` or `review_required`. Use `qa_status: verified` or
`qa_status: review_required` to record that status unchanged, together with
`qa_md_file: qa.md` and its SHA-256.
Strict validation fails when the declared status conflicts with `qa.md`.

Required trace fields:

```yaml
schema_version: 1
generation_mode: case_based
figureforge_version: <version>
generated_script_sha256: <sha256>
claim: case_grounded
primary_case_id: <case-id>
case_md_file: case.md
case_md_sha256: <sha256>
plot_r_file: plot.R
plot_r_sha256: <sha256>
schema_mapping: <source role mapping>
adopted_patterns: case.md#overall composition => plot.R#build_plot(
departures: <deliberate differences or none>
qa_md_file: qa.md
qa_md_sha256: <sha256>
qa_status: verified
```

If `qa.md` does not exist, omit its file and hash fields and set
`qa_status: missing`. Do not use `missing` when the file exists.

## `general_fallback`

Use this mode when search finds no sufficiently relevant primary case, or when
the required `case.md` or `plot.R` cannot actually be read. Proceed with sound
general R plotting methods; do not ask the user to operate the case library.

Record why fallback was necessary, use `claim: general_method`, and never
describe the result as case-grounded, case-enhanced by a matched example, or
based on FigureForge case knowledge.

```yaml
schema_version: 1
generation_mode: general_fallback
figureforge_version: <version>
generated_script_sha256: <sha256>
claim: general_method
fallback_reason: <no sufficient match or unreadable evidence>
```

Validate the generated script binding:

```bash
Rscript "$FIGUREFORGE_SKILL_ROOT/scripts/validate_case_trace.R" \
  <output-directory>/.figureforge/case-trace.yml \
  --script "<output-directory>/plot.R"
```

Do not add primary-case evidence, schema mapping, adopted patterns, or
departures to a fallback trace.
