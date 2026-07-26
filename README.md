# FigureForge

**A case-enhanced R scientific plotting capability for AI agents.**

FigureForge is a plotting capability enhancer: give an AI agent real data and
a plotting request, and get reusable R code plus publication-ready figures.

English · [简体中文](README.zh.md)

## Install

Install the shipped Skill in a project's `.agents/skills` directory:

```bash
git clone https://github.com/Jiawang1209/FigureForge.git
mkdir -p .agents/skills
cp -R FigureForge/skills/figureforge .agents/skills/figureforge
test -s .agents/skills/figureforge/SKILL.md
```

Other Skill-compatible agents can use the same `skills/figureforge` directory:
copy it into a Skill root supported by that agent.

## Use

Ask your AI agent:

> Use data.csv with the FigureForge Skill to draw a scatter plot and give me the R script.

The Skill inspects the real data, adapts a proven plotting approach, renders
the result, and returns a standalone script with its figures.

## Iris PCA demo

Try a complete public example with this prompt:

> Use examples/iris-pca/iris.csv with the FigureForge Skill to create a PCA biplot, render it, and give me the R script.

Run the checked-in demo directly:

```bash
Rscript examples/iris-pca/plot.R examples/iris-pca/iris.csv examples/iris-pca
```

Open the [offline report](examples/iris-pca/index.html), or inspect the
[source directory and README](examples/iris-pca/README.md).

## Default outputs

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
- [FigureForge Skill 1.1.0 release evidence](docs/figureforge-skill-v1.1.0-release.md)
- [Portable v1.1.0 certification evidence](docs/figureforge-skill-v1.1.0-evidence/README.md)
- [Current status](docs/figureforge-skill-mvp-status.md)
- [Historical v1.0.1 release evidence](docs/figureforge-skill-v1.0.1-release.md)

## Scope

FigureForge defaults to R and ggplot2, adding specialist R packages when a
scientific chart needs them.

FigureForge Skill 1.1.0 is the current locally certified release.
FigureForge Skill 1.0.1 is the prior certified historical release. The shipped
package contains 15 public cases.

The local `skills/figureforge/cases/` private corpus and restricted source
material are not distributed; see the linked release evidence and current
status for the concise release boundary. Python plotting and MCP are outside
the shipped current scope. **MCP is planned and unimplemented.**

## License

FigureForge is released under the [MIT License](LICENSE).
