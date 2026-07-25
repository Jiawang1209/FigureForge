# FigureForge Skill v1.0.1 External-Use Hardening Design

Date: 2026-07-25

## Status

Approved design. This specification hardens the accepted FigureForge Skill
v1.0.0 release for real external installation, discovery, triggering,
evaluation, and upgrade. It does not authorize or include an MCP Server.

## Goal

Ship FigureForge Skill v1.0.1 as a standalone Codex Skill that:

- installs from a release archive into a standard Codex Skill search root;
- is discoverable through explicit `$figureforge` use and implicit
  natural-language triggering;
- resolves Rscript consistently on supported macOS and Linux systems;
- includes three authentic, redistributable public-data cases in addition to
  the existing synthetic demonstration gallery;
- is measured against bilingual selection, mapping, rendering, and safe
  rejection evaluations; and
- has a reproducible manifest, archive checksum, upgrade test, release
  verifier, and bilingual release evidence.

The private 165-case corpus remains outside the public package. The existing
12 synthetic public cases remain demonstrations and stress-test anchors; they
are not reclassified as authentic scientific examples.

## Chosen Approach

Use incremental standalone-Skill hardening.

Keep the source authority at `skills/figureforge/`, preserve the current
public R libraries and CLIs, and add only the missing installation, runtime,
evaluation, authentic-data, and release boundaries. Do not convert the project
to a plugin in v1.0.1. Plugin packaging may be evaluated later if FigureForge
needs bundled MCP or app capabilities.

This approach preserves v1.0.0 compatibility while fixing a concrete
distribution defect: the current archive retains repository-relative
`skills/figureforge/...` paths, so extracting it directly under
`.agents/skills/` does not create the required
`.agents/skills/figureforge/SKILL.md` layout.

## Supported Platforms

The v1.0.1 support contract covers:

- macOS with Homebrew or another discoverable R installation; and
- Linux with `Rscript` available through configuration or `PATH`.

Windows is not a v1.0.1 acceptance platform. The runtime resolver must avoid
unnecessary Unix-specific assumptions so Windows support can be added later,
but no Windows compatibility claim is made in this release.

## Repository and Distribution Boundaries

The source tree remains:

```text
skills/figureforge/
├── SKILL.md
├── VERSION
├── agents/
├── cases/_template/
├── lib/
├── public-cases/
├── references/
├── schemas/
└── scripts/
```

The installed archive root becomes:

```text
figureforge/
├── SKILL.md
├── VERSION
├── agents/
├── cases/_template/
├── examples/public-demo/
├── lib/
├── public-cases/
├── references/
├── schemas/
└── scripts/
```

The archive is designed to be extracted directly beneath either:

```text
<repository>/.agents/skills/
```

or:

```text
$HOME/.agents/skills/
```

The release manifest records both `source_path` and `package_path`. Package
paths must be unique, relative, normalized, and rooted at `figureforge/`.
Checksums and byte sizes describe the exact source bytes copied into the
archive.

Top-level repository README, README.zh, CHANGELOG, and LICENSE files remain
release evidence but are not installed inside the Skill unless an equivalent
Skill-local file is required at runtime. The public demo must be packaged
under `figureforge/examples/public-demo/` with all inputs required to execute
it. Generated demo renders and logs remain excluded.

The package must continue to exclude:

- the private `skills/figureforge/cases/` corpus except `_template`;
- private indexes, audits, source attachments, and reproduction files;
- third-party images and rights-uncertain material;
- generated renders, logs, caches, and temporary workspaces;
- tests and development-only fixtures; and
- MCP Server code or dependencies.

## Install and Discovery Contract

Add an install-smoke test that:

1. builds the v1.0.1 archive;
2. extracts it under an empty temporary `.agents/skills/` root;
3. proves `figureforge/SKILL.md` and `figureforge/agents/openai.yaml` occupy
   the expected installed paths;
4. runs the official Skill validator against the installed folder;
5. runs doctor, public search, and the packaged demo from the installed copy;
6. confirms all generated output is outside the installed Skill; and
7. invokes the current Codex CLI in an isolated temporary repository to test
   explicit and implicit Skill discovery.

The explicit live probe must mention `$figureforge`. The implicit probe must
use a natural research-visualization request without the Skill name. Both
probes must use bounded prompts, machine-readable output where supported, and
must not depend on the private corpus.

Deterministic repository tests validate installed structure and commands.
Live Codex probes are release acceptance evidence and are reported separately
so model behavior is not mistaken for a deterministic unit test.

## Rscript Resolution Contract

Add one shared runtime resolver used by all public CLIs and release scripts.
Resolution priority is:

1. an explicit CLI `--rscript <path>`;
2. the `FIGUREFORGE_RSCRIPT` environment variable;
3. `/usr/local/bin/Rscript` when it exists, preserving current macOS
   compatibility;
4. `Rscript` resolved from `PATH`; and
5. a clear failure naming all attempted resolution methods.

Every resolved candidate must:

- expand to an existing regular executable file;
- resolve to a normalized absolute path;
- execute `--version` successfully; and
- report a supported R version of at least 4.1.

An explicit invalid CLI path must fail rather than silently fall back. An
invalid `FIGUREFORGE_RSCRIPT` value must also fail with configuration-specific
remediation. Automatic fallbacks apply only when higher-priority configuration
is absent.

Doctor must report:

- the resolved absolute Rscript path;
- the resolution source: `cli`, `environment`, `homebrew_compat`, or `path`;
- the detected R version;
- pass or error status; and
- a copyable remediation command or configuration example.

All CLI entry points that launch another R process accept `--rscript`.
Scripts already running inside R may use the current runtime for in-process
work, but they must pass the resolved runtime to subprocesses rather than
reintroduce fixed paths.

Tests simulate macOS Homebrew, Linux `PATH`, CLI override, environment
override, missing runtime, non-executable candidate, and unsupported version
without modifying the host installation.

## Authentic Public Case Contract

Add exactly three v1.0.1 authentic public cases:

1. `authentic-palmer-penguins-scatter`
   - data: Palmer Penguins;
   - visualization: bill length versus bill depth by species with a
     descriptive fit;
   - distribution basis: CC0 dataset release;
   - scientific claims: descriptive only.
2. `authentic-usgs-earthquakes-bubble`
   - data: a fixed USGS FDSN earthquake query snapshot;
   - visualization: time or depth against magnitude with bubble encoding;
   - distribution basis: United States public-domain government data;
   - scientific claims: descriptive only.
3. `authentic-world-bank-population-timeseries`
   - data: a fixed World Bank API snapshot for a declared set of countries
     and years;
   - visualization: population time series;
   - distribution basis: World Bank open-data terms, CC BY 4.0 with required
     attribution and additional terms;
   - scientific claims: descriptive only.

SSA Baby Names is not included because its current download endpoint returned
HTTP 403 during automated source feasibility checks on 2026-07-25. A release
case may not rely on an inaccessible endpoint or undocumented scraping
workaround.

### Source feasibility evidence

The approved source candidates were checked before implementation:

| Case | Upstream data or query | Rights evidence | 2026-07-25 feasibility snapshot |
| --- | --- | --- | --- |
| Palmer Penguins | `https://raw.githubusercontent.com/allisonhorst/palmerpenguins/main/inst/extdata/penguins.csv` | `https://github.com/allisonhorst/palmerpenguins` documents the data under CC0 and supplies the original dataset citation | 15,241 bytes; SHA-256 `f204db2c753b0937caac3cb35258562c14f073e4bbc76be24b4c51ce22767a93` |
| USGS Earthquakes | `https://earthquake.usgs.gov/fdsnws/event/1/query.csv?starttime=2024-01-01&endtime=2024-02-01&minmagnitude=5&orderby=time-asc` | `https://www.usgs.gov/data-management/data-licensing` and the ANSS data policy document the applicable public-domain basis | 25,178 bytes; SHA-256 `39d0e2be2a0c36784fd7ff8b9335e43fa7583b65dbb3db79ddda65423c55148d` |
| World Bank Population | `https://api.worldbank.org/v2/country/CHN;USA;IND;BRA;ZAF/indicator/SP.POP.TOTL?date=2000:2023&format=json&per_page=500` | `https://datacatalog.worldbank.org/public-licenses` documents CC BY 4.0 as the default for World Bank-produced open data, subject to the listed additional terms | 23,901 bytes; upstream `lastupdated` was `2026-07-13`; SHA-256 `0c516b92077b8cb39972a34a3be14230a84adcbed3db921023b9182e9068e9d0` |

These hashes establish source feasibility only. Implementation must retrieve
or copy the reviewed upstream bytes, normalize them deterministically, record
both upstream and normalized hashes in `source.yml`, and recheck the
case-specific license metadata before making a distribution decision. The
USGS and World Bank endpoints can revise historical records; a later hash
change is not silently accepted.

Each authentic case contains the existing six case assets plus a tracked
`source.yml`:

```text
public-cases/<case-id>/
├── case.md
├── case.yml
├── data.csv
├── distribution.yml
├── plot.R
├── qa.md
└── source.yml
```

`source.yml` records:

- `source_type: authentic_open_data`;
- source publisher and dataset title;
- canonical dataset or API URL;
- exact query URL or upstream file URL;
- retrieval date;
- upstream version, last-updated value, or query interval when available;
- SHA-256 of the retrieved upstream snapshot;
- SHA-256 of the normalized `data.csv`;
- license identifier, license URL, attribution text, and additional terms;
- selected rows and fields;
- ordered normalization operations;
- missing-value treatment;
- `synthetic_test_fixture: false`; and
- `scientific_claims: descriptive_only`.

The packaged case uses a normalized fixed snapshot so installation and
rendering never require network access. Remote retrieval is provenance, not a
runtime dependency. A source update intentionally changes the recorded
upstream hash and requires a new review.

Authentic cases must pass the existing case, metadata, distribution, render,
and export checks. Distribution validation must distinguish authentic open
data from synthetic fixtures and fail closed when source metadata,
attribution, license, hashes, or normalization evidence is missing.

No third-party reference image is packaged. Trusted visual basis consists of:

- authoritative source field documentation;
- the declared chart encoding and transformation specification;
- a successful independent rerender; and
- recorded human inspection of labels, scales, legends, values, clipping,
  and export.

Authentic cases may use `Status: verified` only after that human review is
recorded in `qa.md`. Existing synthetic cases remain `Status:
review_required`; automated visual QA must never promote either case type.

## Trigger and Forward-Evaluation Contract

Create a versioned bilingual evaluation set of approximately 30 prompts with
paired Chinese and English coverage where meaningful. Every row records:

- stable evaluation ID and language;
- prompt text or prompt template;
- supplied data fixture;
- expected outcome: `select`, `map_render`, or `reject`;
- acceptable Top-1 and Top-3 case IDs;
- expected field-role mapping;
- expected render status or rejection category; and
- whether the row is deterministic or requires a live Codex run.

Coverage includes:

- exact and ambiguous chart names;
- scientific intent without a chart name;
- data-only requests;
- Chinese and English aliases;
- renamed columns;
- misleading or wrong column names;
- missing required fields;
- incompatible types;
- incompatible cardinality;
- impossible or unsafe transformations;
- requests attempting to use private or non-distributable assets; and
- requests attempting to write inside the installed Skill.

The evaluator separates four layers:

1. deterministic search and Top-1/Top-3 ranking;
2. deterministic schema mapping or safe rejection;
3. deterministic render and validation;
4. live Codex explicit or implicit Skill triggering.

Release thresholds are:

- deterministic Top-1 accuracy at least 80%;
- deterministic Top-3 accuracy 100%;
- valid mapping and render success 100%;
- invalid, protected, and incompatible input rejection 100%;
- explicit `$figureforge` live trigger success 100%; and
- implicit natural-language live trigger success at least 90%.

Every failure produces a row-level report. Aggregate percentages without
individual evidence are insufficient. Live-evaluation results are generated
release evidence and are not committed unless they are a deliberately
redacted, stable documentation summary.

Skill-trigger tests begin with a baseline evaluation of v1.0.0 metadata and
instructions. Any failed or ambiguous cases become the RED evidence for the
smallest necessary `SKILL.md` or `agents/openai.yaml` change. Skill wording is
not edited before this baseline is recorded.

## Version, Upgrade, and Compatibility Contract

Set `skills/figureforge/VERSION` to `1.0.1` only after the new release
contracts pass their focused tests.

The upgrade test must:

1. install a built v1.0.0 archive into a temporary Skill root;
2. preserve a representative v1.0.0 external adaptation workspace;
3. install v1.0.1 over the installed Skill using a safe replacement strategy;
4. prove no stale v1.0.0 package files remain;
5. rerun doctor, search, demo, and adaptation validation;
6. independently rerender the preserved adaptation; and
7. prove source user data and external workspace files were not modified by
   installation.

The existing public CLI arguments, case identifiers, adaptation metadata
version, and 12 synthetic cases remain compatible. New optional `--rscript`
arguments must not change existing default behavior on the current macOS
environment.

Upgrade code must never delete a broad user directory. Tests operate only in
new temporary roots and compare pre/post file inventories and hashes.

## Release Artifacts and Verification

The release builder emits, outside the repository:

- `figureforge-skill-1.0.1.tar.gz`;
- `figureforge-skill-1.0.1-manifest.csv`;
- `figureforge-skill-1.0.1.tar.gz.sha256`; and
- verifier logs and evaluation reports.

The archive checksum file contains the lowercase SHA-256 and archive basename.
The verifier independently recomputes the archive checksum, validates every
manifest row against extracted bytes, rejects undeclared archive members, and
proves every declared member exists.

Use a portable SHA-256 implementation strategy:

1. `sha256sum` when available;
2. `shasum -a 256` when available; or
3. a bundled standard-library fallback that produces identical lowercase
   hashes.

The final verifier runs:

- all FigureForge R tests;
- R parse checks for every public R file;
- official `quick_validate.py`;
- distribution validation and rendering for all 15 public cases;
- deterministic bilingual forward evaluations;
- package build, manifest, and checksum verification;
- clean archive extraction and install smoke;
- v1.0.0-to-v1.0.1 upgrade compatibility;
- packaged demo and independent rerender;
- bounded explicit and implicit Codex trigger probes;
- `git diff --check`; and
- repository boundary checks proving private and generated assets are absent.

The clean-install and upgrade tests must use the installed package rather than
source-tree fallbacks.

## Documentation Contract

Update and align:

- `README.md`;
- `README.zh.md`;
- `CHANGELOG.md`;
- the Skill status and v1.0.1 release evidence document;
- installation, archive extraction, discovery, doctor, search, demo,
  adaptation, evaluation, and verification commands;
- authentic versus synthetic public-case semantics;
- platform and runtime resolution rules;
- private/public distribution boundaries; and
- the stable future MCP input contract.

Documentation must state that MCP is planned and unimplemented. It must not
advertise a server command, endpoint, or capability as available.

## Delivery Slices

### Slice 1: Installation-shaped packaging

Add source-to-package path mapping, package the public demo, verify manifest
bytes, and prove direct extraction under `.agents/skills/`.

### Slice 2: Cross-platform Rscript resolution

Add the shared resolver, CLI and environment configuration, doctor reporting,
and macOS/Linux simulations.

### Slice 3: Authentic public cases

Extend the fail-closed case and distribution contracts, add the three fixed
open-data snapshots, render them, and record human QA.

### Slice 4: Bilingual trigger and forward evaluation

Add the versioned prompt set, deterministic evaluator, baseline Skill
triggering evidence, minimal Skill metadata changes, and bounded live probes.

### Slice 5: Release and upgrade certification

Add archive checksum verification, v1.0.0 upgrade compatibility, clean-install
acceptance, bilingual documentation, and the final v1.0.1 verifier.

Every behavioral slice follows red-green-refactor and ends with focused tests,
the full FigureForge suite, parse checks, official Skill validation,
`git diff --check`, and a clear local commit. No slice is pushed.

## Acceptance Gates

FigureForge Skill v1.0.1 is complete only when current evidence proves:

- the archive extracts directly to a discoverable
  `.agents/skills/figureforge/` installation;
- the installed copy validates and runs without source-tree fallbacks;
- the packaged demo is present and renders outside the installed Skill;
- Rscript resolution obeys the declared priority and passes macOS/Linux
  simulations;
- doctor reports the actual runtime path, source, version, and remediation;
- all three authentic cases have verifiable source, license, attribution,
  hashes, normalization, render, and human-QA evidence;
- all 12 synthetic cases remain correctly disclosed and review-required;
- all 15 public cases render and validate independently;
- bilingual evaluation thresholds are met with row-level evidence;
- invalid mappings, incompatible data, private assets, and protected output
  paths are rejected safely;
- explicit and implicit Codex discovery meet their release thresholds;
- manifest contents and extracted archive bytes match exactly;
- the archive SHA-256 verifies independently;
- v1.0.0 upgrades without breaking the preserved adaptation contract;
- full tests, parse checks, official validation, and clean-install verifier
  pass;
- README, README.zh, CHANGELOG, VERSION, and release evidence agree;
- no private case, restricted image, generated report, log, or render is
  tracked or packaged;
- MCP remains planned and absent;
- all commits are local, the final worktree is clean, and nothing is pushed.

## Git and Evidence Policy

Commit only public code, tests, fixtures with compatible redistribution terms,
schemas, templates, and documentation. Before every commit, inspect staged
paths and staged diffs. Store archives, extracted installs, live-evaluation
transcripts, renders, logs, and full manifests under ignored output or
temporary paths.

The final report lists requirement-by-requirement evidence, all local commits,
the three authentic case IDs and licenses, evaluation results, platform
coverage, verification commands, release artifact paths and hashes, and the
unchanged future MCP boundary. It does not claim that MCP exists.
