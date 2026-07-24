# Data Mapping

Data mapping translates a user's actual dataset into the semantic roles used
by a selected FigureForge case. Preserve the user's original file and column
names; create explicit aliases only inside the adaptation workspace.

## Inspect Before Mapping

Record:

- file format, delimiter, encoding, row count, and column names;
- numeric ranges, units, missing values, and non-finite values;
- unique group and facet levels in intended order;
- duplicate keys and whether observations are paired or repeated;
- statistical meaning of summaries, intervals, p-values, and thresholds.

Never infer a unit, pairing key, or statistical denominator from a column name
alone.

## Mapping Table

Write this in `mapping.md` before changing `plot.R`:

| Case role | Input column | Required | Type or unit | Transformation |
| --- | --- | --- | --- | --- |
| x |  | yes |  |  |
| y |  | yes |  |  |
| group |  | no | categorical | factor order |
| facet |  | no | categorical |  |
| label |  | no | text |  |
| value |  | no | numeric |  |

Add or remove roles to match the selected case exactly. For a heatmap these
may be `row`, `column`, and `value`; for a tree they may include `tip`,
`feature_start`, `feature_end`, and `feature_type`.

## Chinese Field Names

Keep original Chinese names in the mapping record:

| Case role | Input column | Required | Type or unit | Transformation |
| --- | --- | --- | --- | --- |
| x | 处理组 | yes | ordered category | map internally to `group` |
| y | 平均值 | yes | mg/L | map internally to `value` |
| color | 土层 | no | category | preserve observed order |

Use `check.names = FALSE` when reading CSV if R would otherwise alter names.

## Derived Fields

For each derived field, record:

1. output field name;
2. source columns;
3. exact formula or recoding table;
4. missing-value behavior;
5. units after transformation;
6. reason the derivation is scientifically valid.

Examples include `-log10(p)`, confidence intervals, signed correlation classes,
long-format pivots, category labels, and tree-relative coordinates.

## Rejection Conditions

Stop and resolve the mapping when:

- a required role has no source or justified derivation;
- units are incompatible;
- category or sample identifiers are ambiguous;
- a join changes row coverage unexpectedly;
- a statistical layer requires replication that the data lacks;
- values fall outside the case's scale assumptions;
- an annotation would imply evidence not present in the input.

## Post-Render Checks

Compare the normalized input with plotted marks. Confirm row coverage, factor
order, scale limits, missing-value handling, labels, derived summaries, and all
statistics before marking QA verified.
