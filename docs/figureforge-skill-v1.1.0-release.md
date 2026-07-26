# FigureForge Skill 1.1.0 Release Evidence

Status: currently certified locally
Version: `1.1.0`
Certified source commit: `9888601f2119e03380855aaadd92b340f8a24964`
Certified source tree: `dd6026c700b5d715d0a66b31db6531324793ec80`

FigureForge Skill 1.1.0 is the current locally certified release. The
certification is bound by
[`certification-identity.tsv`](figureforge-skill-v1.1.0-evidence/certification-identity.tsv)
to the committed release inputs, not merely to a documentation commit. A later
documentation-only commit may therefore contain this evidence while the
certified source commit remains the release-input commit above.

The durable [portable certification evidence](figureforge-skill-v1.1.0-evidence/README.md)
contains sanitized summaries, source and package bindings, artifact identities,
environment facts, commands, and checksums.

## Acceptance

FigureForge Skill v1.1.0 acceptance: PASS

| Gate | Result |
|---|---:|
| Explicit live trigger | 1/1 |
| Implicit live trigger | 10/10 |
| Executable plotting and independent rerender | 1/1 |
| Case-grounded mode | 1/1 |
| General-method fallback | 1/1 |

The plotting gate produced nonempty `plot.R`, `plot.png`, and `plot.pdf`; an
independent rerender reproduced the PNG byte-for-byte and produced a valid PDF.
The mode gate proved both branches: case-grounded generation used trusted case
evidence and read the selected case, plotting, and QA files; general fallback
used `claim: general_method` without reading case evidence.

The accepted platform baseline remains 15 public cases, 24 synthetic stress fixtures,
and 30 deterministic bilingual forward evaluations.

MCP is planned and unimplemented.

## Package identity

The canonical 159-row release manifest SHA-256 is:

`45e2bc2cf42249c037ccca63876fe30864684de1026768787cb03806dcea5b04`

All three live gates produced this same manifest. Schema v2 additionally binds
the exact trigger, plotting, and mode summary SHA-256 values. Their compressed
archive hashes differ because the packaging contract does not promise
deterministic gzip/tar container bytes. The archive used for the certification identity is
recorded separately in the identity and
[`package-identities.tsv`](figureforge-skill-v1.1.0-evidence/package-identities.tsv).

## Privacy and release boundary

The raw or unsanitized evaluation logs are not committed. The bundle contains
tracked sanitized certification logs with aggregate results and cryptographic identities;
they exclude prompts, transcripts, credentials, private corpus content, user
data, and generated binaries.

Search-query SHA-256 values are linkable pseudonymous identifiers, not
encryption. Search queries must remain abstract and exclude secrets and personal
identifiers.

FigureForge Skill 1.0.1 is the prior certified historical release. This is a
local certification only: no push, tag, merge, PR, or publication is implied.
