# FigureForge Skill 1.1.0 Status

Date: 2026-07-26
Status: currently certified locally

FigureForge Skill 1.1.0 is a case-enhanced R plotting capability and the
currently certified release. It preserves the standard visible artifact
contract (`plot.R`, `plot.png`, and `plot.pdf`) while selecting either
case-grounded generation or a general-method fallback.

The certified release-input commit is
`ab1213c36fbe1591b44581b78c7d182c35f79ffb`. Certification documentation may
land in a later documentation-only commit; the identity checker confirms that
the release inputs and all three live summaries still match the certified
identity.

## Gate status

| Area | Current result |
|---|---|
| Live triggers | Explicit 1/1; implicit 10/10 |
| Executable plotting | 1/1, including independent rerender |
| Generation modes | case-grounded 1/1; general-method fallback 1/1 |
| Evidence state | currently certified and identity-bound |
| MCP | planned and unimplemented |

See the [portable certification evidence](figureforge-skill-v1.1.0-evidence/README.md),
the [release evidence](figureforge-skill-v1.1.0-release.md), and the
[recertification procedure](figureforge-skill-v1.1.0-recertification.md).

The platform baseline remains 15 public cases, 24 synthetic stress fixtures,
30 deterministic bilingual forward evaluations, 152 completed private cases,
13 validated blockers, and 0 pending cases. The private corpus and generated
artifacts are not committed.

Search-query SHA-256 values are linkable pseudonymous identifiers rather than
encryption; queries must remain abstract and exclude secrets and personal
identifiers.

FigureForge Skill 1.0.1 is the prior certified historical release. No MCP server
is included in 1.1.0, and no push, tag, merge, PR, or publication is implied by
this local certification.
