# January 2024 Magnitude 5+ Earthquakes

## Chart Type

time-depth bubble plot

## Chart Type Chinese

时间—深度地震气泡图

## Aliases

earthquake bubble, magnitude depth, seismic events, 地震气泡图, 震级深度

## Best For

Reviewing the timing, depth, and magnitude of events from a fixed catalog
query.

## Best For Chinese

查看固定目录查询中地震事件的时间、深度和震级。

## Data Provenance

The fixed 133-row snapshot comes from a declared USGS FDSN Event Web Service
query for magnitude 5+ events during January 2024. See `source.yml` for the
query, public-domain basis, hashes, and normalization. Catalog records may be
revised upstream; this packaged snapshot is descriptive.

## Data Schema

- time: ISO 8601 UTC event time
- depth: finite non-negative kilometres
- magnitude: finite event magnitude
- label: non-empty place description

## Visual Encoding

Horizontal position encodes UTC time, vertical position encodes depth with
deeper events lower on the plot, and point size and color encode magnitude.

## ggplot Components

- `geom_point()`
- continuous size and color scales
- reversed depth axis

## Required R Packages

- ggplot2

## Adaptation Notes

Use a declared catalog query and preserve time zone, depth units, and magnitude
semantics. A changed upstream response requires a new snapshot hash and review.

## Common Pitfalls

- Catalog events and parameters can be revised after the event.
- Bubble area is a visual encoding, not released energy.
- This view does not represent detection completeness.
