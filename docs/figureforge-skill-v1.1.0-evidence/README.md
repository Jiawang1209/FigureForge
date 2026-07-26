# FigureForge Skill 1.1.0 Portable Certification Evidence

This is the sanitized, repository-tracked evidence bundle for the current
local FigureForge Skill 1.1.0 certification.

## Certified boundary

The machine-readable
[certification-identity.tsv](certification-identity.tsv) binds release `1.1.0`
to source commit `32eb3a7e3fa1a6aaef19d462b3893e9e396b3282`, source tree
`403bd3c9de57345480244d7a57174522afc062f1`, the release-source digest, and the
canonical package manifest. A later documentation-only commit may carry this
bundle without changing the certified source commit, provided the currentness
checker confirms that every release input remains identical.

## Files

- `certification-identity.tsv`: authoritative source/package identity.
- `source-binding.tsv`: Git objects and SHA-256 values for the Skill and all
  certification machinery.
- `environment.tsv` and `commands.tsv`: observable environment and sanitized
  gate commands.
- `live-trigger-summary.csv`, `live-plotting-summary.csv`, and
  `live-mode-summary.csv`: machine-readable gate outcomes.
- `live-trigger.log`, `live-plotting.log`, `live-mode.log`, and
  `deterministic-verification.log`: tracked sanitized certification logs.
- `artifact-identities.tsv` and `package-identities.tsv`: generated artifact
  and package identities without the generated binaries.
- `SHA256SUMS`: checksums for every other file in this directory.

## Package identity

All three live gates produced the same 159-row manifest:

`a6dbd539aba44cf566cf974c6b7eaa277b3d8d5717c1ebe88d2399e783c5e6bf`

This manifest is the portable package identity because it binds each member
path, size, and SHA-256. The three compressed archives differ only at the
container-byte level; gzip/tar byte reproducibility is not part of the contract,
so each run-specific archive hash is retained separately.

## Privacy boundary

Raw or unsanitized logs, JSONL transcripts, final replies, prompts, local
temporary paths, user data, private corpus content, rendered images, package
archives, credentials, and installed trees are excluded.

Tracked sanitized certification logs contain aggregate outcomes and
cryptographic identities only. The configured Codex model name was not exposed
by the retained events and is recorded as `not_exposed`, not guessed.
