# FigureForge Public Demo

Run the complete public workflow into a new directory outside the repository:

```bash
sh examples/public-demo/run_demo.sh /tmp/figureforge-public-demo
```

The demo deterministically generates Chinese-column time-series data, records
an explicit role mapping, creates a protected adaptation from
`public-timeseries-band`, canonicalizes only the copied input, renders two
independent PDFs, and writes a non-authoritative `visual-qa.json`.

The source public case is never modified. `qa.md` remains
`Status: review_required`; a human must review the scientific mapping and
render before recording any verified status.
