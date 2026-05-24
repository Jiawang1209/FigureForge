# FigureForge Project Handoff

## Project Name

FigureForge

## Recommended GitHub Description

An AI-ready, reproducible case-based skillbase for publication-ready scientific visualization in R and Python, built from real figure reproductions and reusable plotting workflows.

## One-Sentence Positioning

FigureForge turns real publication figure reproductions into AI-ready visualization workflows for AI4S and scientific discovery.

## Core Idea

FigureForge is planned as a case-based scientific visualization skillbase. The first version will focus on R and ggplot2, based on 100+ real figure reproduction cases from the user's "improving data visualization through imitation" article series.

Each case is expected to include:

- Original/example image
- Reproduced image
- Plotting data
- R/ggplot2 plotting script
- Case notes describing visual structure, data mapping, and adaptation rules

The long-term vision is to support both R and Python ecosystems and become a reusable AI-ready resource for scientific visualization, potentially publishable as a research article, database paper, data descriptor, or software/resource paper.

## Why This Is Worth Building

The project has a stronger foundation than a normal prompt-only skill because it is built from real reproducible cases. The key asset is not only the instruction file, but the accumulated gallery of examples, data, and scripts.

Compared with generic "Nature-style figure" prompts, FigureForge can offer:

- Case-based figure selection
- Real code adaptation
- Data-schema mapping
- Reproducible plotting workflows
- Visual QA against reference reproductions
- A learning pathway from imitation to migration

The strongest differentiator is the phrase:

From reproduction to adaptation.

## Relationship To Skills

The final product can still be a skill, but it should be understood as a case-based skill or skillbase rather than a simple prompt skill.

Minimum form:

```text
SKILL.md
references/
cases/
scripts/
```

More complete form:

```text
FigureForge
= AI skill
+ 100+ figure cases
+ data
+ R scripts
+ reference images
+ case metadata
+ QA rules
+ export workflows
+ future Python support
```

Recommended external wording:

- AI-ready scientific visualization skillbase
- Case-based publication figure toolkit
- Reproducible scientific visualization atlas
- R and Python figure workflow skillbase

## Suggested Repository Structure

```text
FigureForge/
├── README.md
├── PROJECT_HANDOFF.md
├── skills/
│   └── figureforge/
│       ├── SKILL.md
│       ├── references/
│       │   ├── gallery-index.md
│       │   ├── data-mapping.md
│       │   ├── ggplot-patterns.md
│       │   ├── theme-and-export.md
│       │   └── qa-checklist.md
│       ├── cases/
│       │   ├── 001-case-name/
│       │   │   ├── original.png
│       │   │   ├── reproduction.png
│       │   │   ├── data.csv
│       │   │   ├── plot.R
│       │   │   └── case.md
│       │   └── ...
│       └── scripts/
│           ├── index_cases.R
│           ├── render_case.R
│           └── validate_case.R
└── docs/
    └── paper-notes/
```

## Suggested Case Metadata Template

```markdown
# Case 001: Case Title

## Chart Type

scatter / heatmap / bar / violin / boxplot / map / network / timeline / multi-panel

## Best For

Describe the scientific data scenario this case is best suited for.

## Data Schema

- x:
- y:
- group:
- facet:
- label:
- value:

## Visual Encoding

- color:
- size:
- shape:
- line:
- annotation:

## ggplot Components

- geom_*:
- scale_*:
- theme_*:
- annotation_*:
- layout/composition:

## Adaptation Notes

Explain how a user's data should be mapped into this case.

## Common Pitfalls

List details that are easy to break during adaptation.
```

## Recommended MVP

Start with 12-20 representative R/ggplot2 cases instead of trying to clean all 100+ cases at once.

The first case set should cover:

- Bar or column charts
- Boxplots and violin plots
- Scatter plots with labels
- Line or trend plots
- Heatmaps
- Faceted plots
- Multi-panel composition
- Complex annotations
- A visually distinctive figure from the user's series

The MVP should prove that an AI agent can:

1. Inspect a user's plotting goal or data structure.
2. Select a similar FigureForge case.
3. Open the case metadata and R script.
4. Map the user's data to the case schema.
5. Modify the R/ggplot2 code.
6. Render a new figure.
7. Export publication-ready files.
8. Run a basic QA checklist.

## Possible Publication Framing

Potential paper or database title:

FigureForge Atlas: A Reproducible Case-Based Skillbase for Scientific Data Visualization

Possible contribution claims:

- A curated atlas of reproducible scientific visualization cases.
- A case-based workflow for adapting publication figures to new datasets.
- An AI-ready resource that connects visual examples, plotting code, data schemas, and adaptation rules.
- A bridge between scientific visualization education, reproducible research, and AI4S workflows.

Possible publication types:

- Software/resource paper
- Database article
- Data descriptor
- Education or methods article
- AI4S workflow paper

## Important Product Direction

Do not over-abstract the plotting code too early. The current redundancy in the R scripts may be useful because each case is independently understandable and reproducible.

Prioritize:

- Reproducibility
- Case clarity
- Visual fidelity
- Adaptability
- Good metadata

Avoid:

- Turning all cases into one complicated plotting framework too early
- Hiding important figure-specific details behind generic functions
- Marketing the project only as "Nature style"
- Binding the whole project permanently to R only

## Next Practical Steps

1. Add a README with the project description and roadmap.
2. Choose 12-20 representative R/ggplot2 cases for the MVP.
3. Create the first `skills/figureforge/SKILL.md`.
4. Create `references/gallery-index.md` with a small hand-curated index.
5. Convert 3-5 cases into the proposed case folder format.
6. Test whether Codex can adapt one case to a new dataset.
7. Expand the case library after the workflow proves useful.

## Suggested New-Conversation Startup Prompt

```text
Please read /Users/liuyue/Desktop/Github_repos/FigureForge/PROJECT_HANDOFF.md first.
This is the project handoff for FigureForge. Continue from this context and help me design or implement the next step.
```
