#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_v110_documentation.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)

read_document <- function(relative_path) {
  path <- file.path(repo_root, relative_path)
  stopifnot(file.exists(path))
  paste(
    readLines(path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
}

contains_all <- function(document, terms) {
  all(vapply(terms, grepl, logical(1), x = document, fixed = TRUE))
}

english <- read_document("README.md")
chinese <- read_document("README.zh.md")
changelog <- read_document("CHANGELOG.md")
status <- read_document("docs/figureforge-skill-mvp-status.md")
release <- read_document("docs/figureforge-skill-v1.1.0-release.md")
skill <- read_document("skills/figureforge/SKILL.md")
plotting <- read_document(
  "skills/figureforge/references/plotting-workflow.md"
)
maintainer <- read_document(
  "skills/figureforge/references/maintainer-workflow.md"
)
live_harness <- read_document("scripts/run_figureforge_live_evals.sh")
plotting_harness <- read_document(
  "scripts/run_figureforge_plotting_eval.sh"
)

stopifnot(contains_all(
  english,
  c(
    "FigureForge Skill 1.1.0",
    "plotting capability enhancer",
    "plot.R",
    "plot.png",
    "plot.pdf",
    "MCP is planned and unimplemented"
  )
))
stopifnot(contains_all(
  chinese,
  c(
    "FigureForge Skill 1.1.0",
    "绘图能力增强器",
    "plot.R",
    "plot.png",
    "plot.pdf",
    "MCP 状态为 planned 且尚未实现"
  )
))
stopifnot(grepl(
  "MCP is planned and unimplemented",
  skill,
  fixed = TRUE
))
for (document in list(skill, plotting)) {
  stopifnot(contains_all(
    document,
    c("plot.R", "plot.png", "plot.pdf")
  ))
}
stopifnot(contains_all(
  maintainer,
  c(
    "scripts/validate_blocker.R",
    "scripts/audit_cases.R",
    "scripts/package_skill.R",
    "scripts/verify_release.R"
  )
))
stopifnot(contains_all(
  changelog,
  c(
    "## 1.1.0 - 2026-07-25",
    "plot.R",
    "plot.png",
    "plot.pdf",
    "primary",
    "secondary",
    "maintainer",
    "v1.0.1",
    "MCP"
  )
))
stopifnot(grepl(
  "FigureForge Skill 1.1.0",
  status,
  fixed = TRUE
))
stopifnot(contains_all(
  release,
  c(
    "FigureForge Skill 1.1.0",
    "plot.R",
    "plot.png",
    "plot.pdf",
    "independent rerender",
    "15 public cases",
    "24 synthetic stress fixtures",
    "30 deterministic bilingual forward evaluations",
    "MCP is planned and unimplemented",
    "FigureForge Skill v1.1.0 acceptance: PASS",
    "Explicit live trigger | 1/1",
    "Implicit live trigger | 10/10",
    "/tmp/figureforge-v110-live.740e78",
    "/tmp/figureforge-v110.4Ywsys",
    "/tmp/figureforge-v110.RMisRW"
  )
))
stopifnot(contains_all(
  english,
  c(
    "FigureForge Skill 1.1.0 is the current locally certified release",
    "FigureForge Skill 1.0.1 is the prior certified historical release"
  )
))
stopifnot(contains_all(
  chinese,
  c(
    "FigureForge Skill 1.1.0 是当前完成本地认证的发布版本",
    "FigureForge Skill 1.0.1 是此前已认证的历史发布版本"
  )
))
stopifnot(contains_all(
  status,
  c(
    "locally certified",
    "Explicit 1/1; implicit 10/10",
    "/tmp/figureforge-v110-live.740e78",
    "/tmp/figureforge-v110.RMisRW"
  )
))
for (document in list(release, status)) {
  stopifnot(!grepl(
    "/tmp/figureforge-v110.lRin35",
    document,
    fixed = TRUE
  ))
}
for (document in list(english, chinese, status)) {
  stopifnot(!grepl(
    "v1.1.0 live-model and release certification is pending",
    document,
    fixed = TRUE
  ))
  stopifnot(!grepl(
    "真实模型与发布认证仍待完成",
    document,
    fixed = TRUE
  ))
}

verifier_path <- file.path(
  repo_root,
  "scripts",
  "verify_figureforge_v110.sh"
)
stopifnot(file.exists(verifier_path))
stopifnot(identical(
  as.integer(system2("sh", c("-n", shQuote(verifier_path)))),
  0L
))
for (harness in c(
  "scripts/run_figureforge_live_evals.sh",
  "scripts/run_figureforge_plotting_eval.sh"
)) {
  stopifnot(identical(
    as.integer(system2(
      "bash",
      c("-n", shQuote(file.path(repo_root, harness)))
    )),
    0L
  ))
}

verifier <- read_document("scripts/verify_figureforge_v110.sh")
verifier_lines <- readLines(
  verifier_path,
  warn = FALSE,
  encoding = "UTF-8"
)
verifier_nonempty_lines <- verifier_lines[nzchar(trimws(verifier_lines))]
stopifnot(identical(
  tail(verifier_nonempty_lines, 1L),
  'echo "FigureForge Skill v1.1.0 acceptance: PASS"'
))
live_if <- which(
  verifier_lines == 'if [ "$RUN_LIVE" = "1" ]; then'
)
live_else <- which(verifier_lines == "else")
live_fi <- which(verifier_lines == "fi")
stopifnot(length(live_if) == 1L)
live_else <- live_else[live_else > live_if][[1L]]
live_fi <- live_fi[live_fi > live_else][[1L]]
live_harness_line <- grep(
  "scripts/run_figureforge_live_evals.sh",
  verifier_lines,
  fixed = TRUE
)
plotting_harness_line <- grep(
  "scripts/run_figureforge_plotting_eval.sh",
  verifier_lines,
  fixed = TRUE
)
stopifnot(length(live_harness_line) == 1L)
stopifnot(length(plotting_harness_line) == 1L)
stopifnot(live_if < live_harness_line)
stopifnot(live_harness_line < plotting_harness_line)
stopifnot(plotting_harness_line < live_else)
stopifnot(live_else < live_fi)
verifier_terms <- c(
  "FIGUREFORGE_RSCRIPT",
  "FIGUREFORGE_V110_OUTPUT_DIR",
  "/tmp/figureforge-v110.XXXXXX",
  "figureforge-skill-1.1.0.tar.gz",
  "figureforge-skill-1.1.0-manifest.csv",
  "test_v1_acceptance.R",
  "test_upgrade_compatibility.R",
  "validate_public_case.R",
  "run_stress_tests.R",
  "evaluate_skill.R",
  "doctor.R",
  "package_skill.R",
  ".sha256",
  "verify_release.R",
  "quick_validate.py",
  "validate_adaptation.R",
  "run_figureforge_live_evals.sh",
  "run_figureforge_plotting_eval.sh",
  "live-trigger-evals",
  "live-plotting-eval",
  "FIGUREFORGE_RUN_LIVE_EVALS",
  "git diff --check",
  "FigureForge Skill v1.1.0 acceptance: PASS"
)
stopifnot(contains_all(verifier, verifier_terms))
stopifnot(contains_all(
  verifier,
  c(
    'export FIGUREFORGE_PYTHON="$PYTHON"',
    'export FIGUREFORGE_SKILL_VALIDATOR="$SKILL_VALIDATOR"',
    "FIGUREFORGE_STRESS_REPORT",
    "FIGUREFORGE_FORWARD_REPORT",
    "FIGUREFORGE_DOCTOR_JSON",
    "FIGUREFORGE_SEARCH_REPORT",
    "FIGUREFORGE_R_FILE",
    "FIGUREFORGE_MANIFEST"
  )
))
for (unsafe_pattern in c(
  "read.csv('$VERIFY_ROOT",
  "open('$VERIFY_ROOT",
  "parse(file='$REPO_ROOT",
  "read.csv('$MANIFEST"
)) {
  stopifnot(!grepl(unsafe_pattern, verifier, fixed = TRUE))
}
stopifnot(!grepl(
  "FIGUREFORGE_V101_OUTPUT_DIR",
  verifier,
  fixed = TRUE
))
stopifnot(!grepl(
  "/tmp/figureforge-v101",
  verifier,
  fixed = TRUE
))
stopifnot(!grepl(
  "figureforge-skill-1.0.1",
  verifier,
  fixed = TRUE
))
stopifnot(!grepl(
  "FigureForge Skill v1.0.1 acceptance: PASS",
  verifier,
  fixed = TRUE
))

documents <- list(
  english,
  chinese,
  changelog,
  status,
  release,
  skill,
  plotting,
  maintainer,
  verifier,
  live_harness,
  plotting_harness
)
for (document in documents) {
  lower <- tolower(document)
  stopifnot(!grepl("mcp is implemented", lower, fixed = TRUE))
  stopifnot(!grepl("mcp server is implemented", lower, fixed = TRUE))
  stopifnot(!grepl(
    "(^|[^[:alpha:]])implemented mcp",
    lower,
    perl = TRUE
  ))
  stopifnot(!grepl("已实现 mcp", lower, fixed = TRUE))
  stopifnot(!grepl("mcp 服务已实现", lower, fixed = TRUE))
  stopifnot(!grepl("mcp 已实现", lower, fixed = TRUE))
}

upgrade_test <- read_document(
  "tests/figureforge/test_upgrade_compatibility.R"
)
stopifnot(contains_all(
  upgrade_test,
  c(
    "Sys.getenv(env_var",
    '"FIGUREFORGE_RSCRIPT"',
    '"FIGUREFORGE_PYTHON"',
    '"FIGUREFORGE_SKILL_VALIDATOR"',
    "rscript",
    "python",
    "skill_validator"
  )
))
for (hardcoded_execution in c(
  'system2("/usr/local/bin/Rscript"',
  'system2("/usr/bin/python3"'
)) {
  stopifnot(!grepl(
    hardcoded_execution,
    upgrade_test,
    fixed = TRUE
  ))
}

message("v1.1.0 documentation tests: PASS")
