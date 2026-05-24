# Data Mapping

Data mapping translates a user's dataset into the schema expected by a FigureForge case. Source data may use English or Chinese column names, and users should not need to rename columns before the mapping step.

## Mapping Table

Before editing a plotting script, write a mapping table:

| Case role | User column | Required | Transformation |
| --- | --- | --- | --- |
| x |  | yes |  |
| y |  | yes |  |
| group |  | no |  |
| facet |  | no |  |
| label |  | no |  |
| value |  | no |  |

## Chinese Field Names

When users provide Chinese data columns, preserve the original column names in the mapping table and create explicit script aliases only when needed by R code.

Example:

| Case role | User column | Required | Transformation |
| --- | --- | --- | --- |
| x | 处理组 | yes | map to `x` inside plotting script |
| y | 平均值 | yes | map to `y` inside plotting script |
| group | 土层 | no | preserve order as factor levels |

## Rules

- Required case roles must map to existing user columns or explicit derived columns.
- Derived columns must be created before plotting and described in the report.
- Aesthetic mappings such as color, shape, size, and alpha should preserve the case's visual intent.
- Factor order should be set deliberately when order affects interpretation.
- Missing values should be handled before rendering, not hidden silently by geoms.
- Chinese labels, legends, and annotations should remain in Chinese when that matches the user's target output.
