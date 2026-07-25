# FigureForge Skill 1.1.0 Portable Certification Evidence

This directory is the sanitized, repository-tracked evidence bundle for the
local FigureForge Skill 1.1.0 certification. It preserves machine-readable
summaries, immutable source bindings, environment facts, exact commands,
artifact identities, package identities, and checksums without retaining raw
agent transcripts, prompts, user data, rendered images, private corpus files,
credentials, or temporary installed trees.

## Immutable source boundary

The real live gates ran from a clean worktree at commit
`2f92d6370563a12862c111d61f3831c83da8b025`, whose complete Git tree is
`b17435309d9d8e4a967d8211e5b7c4e35e323389`. The tested Skill subtree and
live/plotting harness blobs are recorded in
[source-binding.tsv](source-binding.tsv), together with SHA-256 identities.

The live gates did **not** run on the later evidence-document commits.
`2983880a8d8f19cd53d73f4a64236e75c9b247c0` added the certification prose and
tests; `f475a308709269f35a7253f8ce930f7ba7e49f10` corrected an evidence root.
Those commits changed documentation and documentation tests only. The tested
Skill subtree, live harness, plotting harness, verifier, and package builder
remain byte-identical to the clean tested source binding.

## Files

- [environment.tsv](environment.tsv) records observable runtime and OS facts.
- [commands.tsv](commands.tsv) records exact commands, evidence time windows,
  source binding, worktree state, and result.
- [deterministic-verification.log](deterministic-verification.log) is a
  sanitized terminal-result log for the deterministic verifier runs.
- [live-trigger-summary.csv](live-trigger-summary.csv) and
  [live-trigger.log](live-trigger.log) preserve the trigger result and
  sanitized terminal output.
- [live-plotting-summary.csv](live-plotting-summary.csv) and
  [live-plotting.log](live-plotting.log) preserve the executable plotting and
  independent-rerender result.
- [artifact-identities.tsv](artifact-identities.tsv) records the nonempty
  delivered and independently rerendered artifacts by size, type, and SHA-256
  without committing the generated binaries or user input.
- [package-identities.tsv](package-identities.tsv) records the canonical
  release-manifest identity and the run-specific compressed archive identities.
- [SHA256SUMS](SHA256SUMS) authenticates every other file in this bundle.

## Package identity and gzip nondeterminism

All three recorded verifier runs produced the same 156-row release manifest:

`12752a5688f4939a6d5deb72a60cbc2587077d6ad0672d9ea8218d021ecf0398`

That manifest is the canonical portable package identity because it fixes every
member path, byte count, and member SHA-256. The three `.tar.gz` files have
different SHA-256 values even though their manifests are identical. The
packaging pipeline does not promise a reproducible gzip/tar byte stream:
container metadata and gzip headers can vary by run. Therefore each compressed
archive hash is recorded as run-specific evidence and is not substituted for
the stable manifest identity.

## Time and model observability

Times in [commands.tsv](commands.tsv) are exact filesystem evidence times from
the retained artifacts. For verifier runs, the start column is the release
manifest creation time and the end column is the last verifier-root event; it
is not misrepresented as a process start timestamp. Trigger and plotting
windows use package-log creation and summary completion times.

The live commands did not pass `--model`, so the configured default model was
used. Codex CLI 0.145.0 did not expose the resolved model name in the retained
JSONL `thread.started` event. The evidence records that limit explicitly rather
than guessing a model name.

## Privacy boundary

Raw JSONL transcripts and final replies remain outside Git because they can
contain prompts, local paths, and agent working context. The private 165-case
corpus, third-party source assets, reproductions, logs, rendered outputs, and
credentials are also excluded. This bundle contains only sanitized aggregate
results and cryptographic identities needed to audit the certification.
