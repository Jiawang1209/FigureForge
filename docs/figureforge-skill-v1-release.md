# FigureForge Skill 1.0.0 Release

Date: 2026-07-25

## Release Boundary

FigureForge Skill 1.0.0 is a public R-first Skill that runs without the local
private corpus. The public framework uses the repository MIT license. Every
public case is separately allowlisted by `distribution.yml`, uses generated
data marked `synthetic_test_fixture: true`, and remains
`Status: review_required`.

The 165-case private corpus is an optional local extension and is not packaged.
The release also excludes third-party source figures, original or reproduction
images, private indexes, audit reports, logs, and renders. Automated visual QA
never grants verified status. MCP is planned and unimplemented.

## Public Cases

The 12 public case IDs are:

1. `public-bar-grouped`
2. `public-correlation-heatmap`
3. `public-distribution-raincloud`
4. `public-enrichment-bubble`
5. `public-gene-structure`
6. `public-multipanel`
7. `public-network`
8. `public-phylogeny-annotation`
9. `public-scatter-fit`
10. `public-survival`
11. `public-timeseries-band`
12. `public-volcano`

Together they cover grouped/stacked bars, distribution and raincloud
comparisons, fitted scatter, uncertainty-band time series, correlation
heatmaps, enrichment bubbles, volcano plots, networks, survival, annotated
phylogeny, gene feature tracks, and multi-panel composition.

## Synthetic Stress Fixtures

The 24 fixture IDs are:

- `bar-chinese-columns`
- `bar-renamed-en`
- `distribution-missing-values`
- `distribution-outliers`
- `enrichment-sparse-groups`
- `enrichment-zero-p`
- `gene-negative-coordinate`
- `gene-overlapping-features`
- `heatmap-invalid-correlation`
- `heatmap-reordered-factors`
- `multipanel-many-facets`
- `multipanel-missing-optional`
- `network-chinese-labels`
- `network-unknown-node`
- `phylogeny-missing-parent`
- `phylogeny-reordered-nodes`
- `scatter-long-labels`
- `scatter-missing-required`
- `survival-imbalanced-groups`
- `survival-invalid-probability`
- `timeseries-duplicate-key`
- `timeseries-irregular-dates`
- `volcano-large-input`
- `volcano-negative-p`

They include 15 successful adaptations and 9 expected failures covering
missing roles, duplicate keys, invalid values, and referential integrity.

## Public Workflow

The stable command boundary is:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/doctor.R
/usr/local/bin/Rscript skills/figureforge/scripts/search_cases.R \
  --public --query "<English or Chinese terms>"
/usr/local/bin/Rscript skills/figureforge/scripts/match_schema.R \
  --case "<public-case-id>" --input "<input.csv>" --output "<match.csv>"
/usr/local/bin/Rscript skills/figureforge/scripts/create_adaptation.R \
  --case "<public-case-id>" --input "<input.csv>" \
  --workspace "<external_adaptation>"
/usr/local/bin/Rscript skills/figureforge/scripts/visual_qa.R \
  --render "<external_adaptation>/output.pdf" \
  --report "<external_report>/visual-qa.json"
/usr/local/bin/Rscript skills/figureforge/scripts/validate_adaptation.R \
  "<external_adaptation>" --render --output "<independent_output>"
```

The public demo is:

```bash
sh examples/public-demo/run_demo.sh /tmp/figureforge-public-demo
```

## Package and Upgrade

Build the allowlisted package outside the repository:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/package_skill.R \
  --archive /tmp/figureforge-skill-1.0.0.tar.gz \
  --manifest /tmp/figureforge-skill-1.0.0-manifest.csv
```

Install by copying `skills/figureforge/` into a Codex Skills directory or by
extracting the archive. Keep user adaptations outside the installed Skill.
Upgrade by replacing the whole installed version so old and new library files
cannot mix.

## Validation

Acceptance was executed on 2026-07-25 with:

```bash
sh scripts/verify_figureforge_v1.sh
/usr/local/bin/Rscript tests/figureforge/test_v1_acceptance.R
```

The verifier ran 18 non-recursive FigureForge R test files, validated and
externally rendered all 12 public cases, executed all 24 stress scenarios,
parsed every public R file, ran the official `quick_validate.py`, compared the
128-file release manifest with the archive, and checked `git diff --check`.
The acceptance wrapper then repeated the verifier from a local clean clone
without the private corpus.

The final verifier line was:

```text
FigureForge Skill v1.0 acceptance: PASS
```

No archive, render, private case, private index, or audit output is committed.

## Acceptance Matrix

| Requirement | Direct evidence |
| --- | --- |
| Public-only redistribution | `validate_distribution.R`, `distribution.yml`, and `test_distribution_validation.R` |
| 12 public cases | `public-cases/`, `public-case-index.csv`, and 12 external renders in the verifier |
| 24 deterministic stress fixtures | `tests/fixtures/figureforge/stress/manifest.csv` and `run_stress_tests.R` |
| Safe external workspace | `create_adaptation.R` plus protected-root and non-empty-target negative tests |
| Layered dependency diagnosis | `doctor.R` text/JSON checks and strict case diagnostics |
| Bilingual schema-aware discovery | paired English/Chinese search and `match_schema.R` acceptance checks |
| Non-authoritative visual QA | `visual_qa.R`, JSON schema, blank/nonblank fixtures, and forbidden-source-path test |
| Human QA boundary | generated `qa.md` remains `review_required`; automation cannot write verified status |
| Public demo | Chinese-column deterministic input, explicit mapping, two independent PDF renders |
| Version and packaging | `VERSION` 1.0.0, changelog, MIT license, 128-file manifest/archive identity |
| Private/public separation | no private case, reproduction/original asset, private index, output, or log is tracked or packaged |
| Clean-clone operation | `test_v1_acceptance.R` clones the current branch and reruns the verifier without the private corpus |
| Documentation parity | `test_v1_documentation.R` checks both READMEs and every documented public command |
| MCP deferral | docs state planned and unimplemented; the v1 release contains no MCP Server |

## Future MCP Boundary

A future local-first MCP may wrap the stable public inputs:

- explicit public or authorized local case root;
- English or Chinese query plus optional input schema;
- public case ID and explicit role mapping;
- external input, workspace, render, report, and validation paths;
- structured dependency, match, render, and QA-check results;
- independent readiness and distribution states.

The MCP must default to public assets, fail closed on distribution, never
return private data or third-party images, and never treat automated checks as
human verification. No MCP Server is implemented in 1.0.0.
