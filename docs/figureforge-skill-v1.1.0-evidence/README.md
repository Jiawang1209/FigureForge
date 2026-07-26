# FigureForge Skill 1.1.0 Portable Certification Evidence

This is the sanitized, repository-tracked evidence bundle for the current
local FigureForge Skill 1.1.0 certification.

## Certified boundary

The machine-readable
[certification-identity.tsv](certification-identity.tsv) binds release `1.1.0`
to source commit `9888601f2119e03380855aaadd92b340f8a24964`, source tree
`dd6026c700b5d715d0a66b31db6531324793ec80`, the release-source digest, the
canonical package manifest, and SHA-256 identities for all three live gate
summaries. A later documentation-only commit may carry this bundle without
changing the certified source commit, provided the currentness checker confirms
that every release input and live summary remains identical.

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

`45e2bc2cf42249c037ccca63876fe30864684de1026768787cb03806dcea5b04`

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

The query SHA-256 values described by the release are linkable pseudonymous
identifiers, not encryption. Queries therefore remain abstract and must not
contain secrets or personal identifiers.
