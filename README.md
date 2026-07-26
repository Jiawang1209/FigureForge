# FigureForge

**A case-enhanced R scientific plotting capability for AI agents.**

FigureForge is a plotting capability enhancer: give an AI agent real data and
a plotting request, and get reusable R code plus publication-ready figures.

English · [简体中文](README.zh.md)

## Install

From the project where you want to use FigureForge, run this upgrade-safe
POSIX shell block:

```sh
# figureforge-install:start
(
set -eu

FIGUREFORGE_REPO_URL=${FIGUREFORGE_REPO_URL:-https://github.com/Jiawang1209/FigureForge.git}
figureforge_target=.agents/skills/figureforge
figureforge_clone=$(mktemp -d "${TMPDIR:-/tmp}/figureforge-clone.XXXXXX")
figureforge_stage_root=
figureforge_backup_root=
figureforge_published=0

figureforge_cleanup() {
  figureforge_status=$?
  trap - 0 HUP INT TERM
  if [ "$figureforge_published" -eq 0 ] &&
     [ -n "$figureforge_backup_root" ] &&
     [ -e "$figureforge_backup_root/figureforge" ]; then
    if [ ! -e "$figureforge_target" ] && [ ! -L "$figureforge_target" ]; then
      mv "$figureforge_backup_root/figureforge" "$figureforge_target" ||
        figureforge_status=1
    else
      printf '%s\n' "Previous install preserved at $figureforge_backup_root/figureforge" >&2
      figureforge_backup_root=
    fi
  fi
  for figureforge_dir in \
    "$figureforge_stage_root" "$figureforge_backup_root" "$figureforge_clone"
  do
    if [ -n "$figureforge_dir" ] && [ -d "$figureforge_dir" ]; then
      rm -rf "$figureforge_dir" || figureforge_status=1
    fi
  done
  exit "$figureforge_status"
}
trap figureforge_cleanup 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

git clone --quiet "$FIGUREFORGE_REPO_URL" "$figureforge_clone/repo"
test -s "$figureforge_clone/repo/skills/figureforge/SKILL.md"
mkdir -p .agents/skills
figureforge_stage_root=$(mktemp -d ".agents/skills/.figureforge-stage.XXXXXX")
cp -R "$figureforge_clone/repo/skills/figureforge" \
  "$figureforge_stage_root/figureforge"
test -s "$figureforge_stage_root/figureforge/SKILL.md"

figureforge_backup_root=$(mktemp -d ".agents/skills/.figureforge-backup.XXXXXX")
if [ -e "$figureforge_target" ] || [ -L "$figureforge_target" ]; then
  mv "$figureforge_target" "$figureforge_backup_root/figureforge"
fi
mv "$figureforge_stage_root/figureforge" "$figureforge_target"
figureforge_published=1
rm -rf "$figureforge_backup_root" "$figureforge_stage_root" "$figureforge_clone"
figureforge_backup_root=
figureforge_stage_root=
figureforge_clone=
trap - 0 HUP INT TERM
)
# figureforge-install:end
```

Other Skill-compatible agents can use the same `skills/figureforge` directory:
copy it into a Skill root supported by that agent.

## Use

Ask your AI agent:

> Use data.csv with the FigureForge Skill to draw a scatter plot and give me the R script.

The Skill inspects the real data, adapts a proven plotting approach, renders
the result, and returns a standalone script with its figures.

Case-based generation may claim FigureForge case knowledge only when it uses actual case evidence and passes strict trace validation.
General fallback can still complete the plot with `claim: general_method`, but it is not case-grounded.
The Skill handles case search, evidence reading, and hidden trace creation and validation in the background; users do not need to operate the case library.
Every mode records only a search-query SHA-256, a controlled abstract intent, and a hashed CSV search receipt before the mode decision; raw queries are not persisted.
The default visible outputs remain `plot.R`, `plot.png`, and `plot.pdf`; the hidden case trace and search receipt are audit state.

## Iris PCA demo

Try a complete public example with this prompt:

> Use examples/iris-pca/iris.csv with the FigureForge Skill to create a PCA biplot, render it, and give me the R script.

Run the checked-in demo directly:

```bash
Rscript examples/iris-pca/plot.R examples/iris-pca/iris.csv examples/iris-pca
```

GitHub's [HTML link](examples/iris-pca/index.html) shows the report source.
After cloning the repository, open `examples/iris-pca/index.html` locally
(`open examples/iris-pca/index.html` on macOS, or use your browser's Open File
command). See the [source directory and README](examples/iris-pca/README.md).

## Default output

FigureForge's default user deliverables are exactly:

- `plot.R`
- `plot.png`
- `plot.pdf`

Re-run a delivered script with the stable contract:

```bash
Rscript plot.R <input-file> <output-directory>
```

## Documentation

- [Skill entry](skills/figureforge/SKILL.md)
- [Plotting workflow](skills/figureforge/references/plotting-workflow.md)
- [Maintainer workflow](skills/figureforge/references/maintainer-workflow.md)
- [Historical FigureForge Skill 1.1.0 certification snapshot](docs/figureforge-skill-v1.1.0-release.md)
- [Portable evidence for that historical snapshot](docs/figureforge-skill-v1.1.0-evidence/README.md)
- [Current-source recertification procedure](docs/figureforge-skill-v1.1.0-recertification.md)
- [Current status](docs/figureforge-skill-mvp-status.md)
- [Historical v1.0.1 release evidence](docs/figureforge-skill-v1.0.1-release.md)

## Scope

FigureForge defaults to R and ggplot2, adding specialist R packages when a
scientific chart needs them.

FigureForge Skill 1.1.0 is the current implemented version. Its linked
certification evidence binds an earlier v1.1.0 source and package identity, so
the changed current source is pending recertification.
FigureForge Skill 1.0.1 is the prior certified historical release. The shipped
package contains 15 public cases.

The local `skills/figureforge/cases/` private corpus and restricted source
material are not distributed; see the linked release evidence and current
status for the concise release boundary. Python plotting and MCP are outside
the shipped current scope. **MCP is planned and unimplemented.**

## License

FigureForge is released under the [MIT License](LICENSE).
