# FigureForge Public Case Metadata Schema v1

`case.yml` is the machine-readable authority for a public case. It uses one
UTF-8 `key: value` pair per line. Duplicate keys, unknown schema versions, and
missing required keys fail validation.

## Required keys

| Key | Contract |
| --- | --- |
| `schema_version` | Exact value `1` |
| `case_id` | Lowercase `public-` identifier |
| `title_en`, `title_zh` | Non-empty bilingual titles |
| `chart_family`, `chart_subfamily` | Exact taxonomy pair |
| `aliases_en`, `aliases_zh` | Pipe-separated bilingual search aliases |
| `scientific_intents` | Pipe-separated intended comparisons |
| `required_roles` | Pipe-separated `role:type:cardinality` entries |
| `optional_roles` | Same syntax; the value may be empty |
| `annotations`, `layouts` | Pipe-separated supported features |
| `required_packages` | Pipe-separated packages needed for rendering |
| `optional_packages` | Pipe-separated enhancements; may be empty |
| `qa_status` | Exact value `review_required` in the public release |
| `distribution_status` | Exact value `public_ready` |
| `synthetic_test_fixture` | Exact value `true` |

Supported role types are `character`, `numeric`, `integer`, `logical`, `date`,
and `datetime`. Supported cardinalities are `continuous`, `categorical`,
`identifier`, and `temporal`.

## Forward compatibility

A consumer must reject an unknown `schema_version`. A future schema version
must use a new validator and migration path instead of silently interpreting
new fields under the v1 contract.
