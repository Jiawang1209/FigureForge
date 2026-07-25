# World Bank Population Time Series

## Chart Type

multi-country longitudinal line chart

## Chart Type Chinese

多国家纵向人口折线图

## Aliases

population trend, country time series, World Bank population, 人口趋势, 国家时序

## Best For

Comparing published population estimates across countries and years.

## Best For Chinese

比较不同国家和年份的已发布人口估计。

## Data Provenance

The fixed 120-row snapshot uses World Bank indicator `SP.POP.TOTL` for Brazil,
China, India, South Africa, and the United States from 2000 through 2023.
`source.yml` records the exact API query, CC BY 4.0 terms, attribution, hashes,
and normalization. Values are descriptive published estimates.

## Data Schema

- identifier: `country_code`, ISO3 code
- group: `country`, non-empty country name
- time: `year`, integer from 2000 through 2023
- estimate: `population`, finite positive count

## Visual Encoding

Horizontal position encodes year, vertical position encodes population, and
color identifies country.

## ggplot Components

- `geom_line()`
- `geom_point()`
- continuous population labels

## Required R Packages

- ggplot2

## Adaptation Notes

Preserve indicator definition, country identity, year, attribution, and any
upstream revisions. Use a different scale or facets when ranges obscure small
countries.

## Common Pitfalls

- Published values may be estimates and may be revised.
- A shared linear scale visually compresses smaller populations.
- Country comparisons do not explain demographic causes.
