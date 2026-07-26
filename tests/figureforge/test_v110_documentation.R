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

sha256_file <- function(path) {
  output <- system2(
    "shasum",
    c("-a", "256", shQuote(path)),
    stdout = TRUE,
    stderr = TRUE
  )
  stopifnot(is.null(attr(output, "status")))
  hash <- sub("[[:space:]].*$", "", output[[1L]])
  stopifnot(grepl("^[0-9a-f]{64}$", hash))
  hash
}

english <- read_document("README.md")
chinese <- read_document("README.zh.md")
changelog <- read_document("CHANGELOG.md")
status <- read_document("docs/figureforge-skill-mvp-status.md")
release <- read_document("docs/figureforge-skill-v1.1.0-release.md")
evidence_readme <- read_document(
  "docs/figureforge-skill-v1.1.0-evidence/README.md"
)
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

expected_readme_sections <- list(
  english = c(
    "## Install",
    "## Use",
    "## Default outputs",
    "## Iris PCA demo",
    "## Maintainer documentation",
    "## Scope",
    "## License"
  ),
  chinese = c(
    "## 安装",
    "## 使用",
    "## 默认输出",
    "## Iris PCA 演示",
    "## 维护者文档",
    "## 范围",
    "## 许可"
  )
)
extract_h2_sections <- function(document) {
  lines <- strsplit(document, "\n", fixed = TRUE)[[1L]]
  lines[grepl("^## [^#]", lines)]
}
assert_readme_sections <- function(document, expected, label) {
  actual <- extract_h2_sections(document)
  if (!identical(actual, expected)) {
    stop(
      paste0(
        label,
        " README H2 sections differ.\nExpected:\n",
        paste(expected, collapse = "\n"),
        "\nActual:\n",
        paste(actual, collapse = "\n")
      ),
      call. = FALSE
    )
  }
}
assert_readme_sections(
  english,
  expected_readme_sections$english,
  "English"
)
assert_readme_sections(
  chinese,
  expected_readme_sections$chinese,
  "Chinese"
)

old_maintainer_walkthrough_headings <- c(
  "## Maintainer workflow",
  "### Historical v1.0.1 compatibility and release evidence",
  "### Install and discover",
  "### Runtime and public workflow",
  "### Verify, evaluate, and upgrade",
  "### Case-system rationale",
  "### Maintained case workflow",
  "## 维护者工作流",
  "### v1.0.1 历史兼容与发布证据",
  "### 安装与发现",
  "### R 运行时与公开工作流",
  "### 验证、评测与升级",
  "### 案例系统原理",
  "### 维护中的案例工作流"
)
for (heading in old_maintainer_walkthrough_headings) {
  stopifnot(!grepl(heading, english, fixed = TRUE))
  stopifnot(!grepl(heading, chinese, fixed = TRUE))
}

for (document in list(english, chinese)) {
  stopifnot(contains_all(
    document,
    c(
      "examples/iris-pca",
      "plot.R",
      "plot.png",
      "plot.pdf",
      "skills/figureforge/references/maintainer-workflow.md",
      "docs/figureforge-skill-v1.1.0-release.md",
      "docs/figureforge-skill-v1.1.0-evidence/README.md",
      "docs/figureforge-skill-mvp-status.md",
      "skills/figureforge/cases/",
      "LICENSE"
    )
  ))
}
evidence_root <- file.path(
  repo_root,
  "docs",
  "figureforge-skill-v1.1.0-evidence"
)
evidence_files <- c(
  "README.md",
  "environment.tsv",
  "source-binding.tsv",
  "commands.tsv",
  "deterministic-verification.log",
  "live-trigger.log",
  "live-plotting.log",
  "live-trigger-summary.csv",
  "live-plotting-summary.csv",
  "artifact-identities.tsv",
  "package-identities.tsv",
  "SHA256SUMS"
)
stopifnot(dir.exists(evidence_root))
stopifnot(all(file.exists(file.path(evidence_root, evidence_files))))

trigger_summary <- read.csv(
  file.path(evidence_root, "live-trigger-summary.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(identical(
  names(trigger_summary),
  c(
    "kind",
    "probe_id",
    "exit_status",
    "skill_loaded",
    "capability_selected",
    "artifact_contract",
    "passed"
  )
))
stopifnot(nrow(trigger_summary) == 11L)
stopifnot(sum(trigger_summary$kind == "explicit") == 1L)
stopifnot(sum(trigger_summary$kind == "implicit") == 10L)
stopifnot(all(trigger_summary$exit_status == 0L))
stopifnot(all(trigger_summary$skill_loaded == "true"))
stopifnot(all(trigger_summary$capability_selected == "true"))
stopifnot(all(trigger_summary$artifact_contract == "true"))
stopifnot(all(trigger_summary$passed == "true"))

plotting_summary <- read.csv(
  file.path(evidence_root, "live-plotting-summary.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(nrow(plotting_summary) == 1L)
stopifnot(identical(
  names(plotting_summary),
  c(
    "exit_status",
    "skill_loaded",
    "script_exists",
    "png_exists",
    "pdf_exists",
    "rerender_png",
    "rerender_pdf",
    "passed"
  )
))
stopifnot(plotting_summary$exit_status[[1L]] == 0L)
stopifnot(all(
  unlist(plotting_summary[1L, -1L], use.names = FALSE) == "true"
))

environment <- read.delim(
  file.path(evidence_root, "environment.tsv"),
  sep = "\t",
  quote = "",
  comment.char = "",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(identical(
  names(environment),
  c("key", "value", "observability", "source")
))
stopifnot(all(c(
  "timezone",
  "codex_path",
  "codex_version",
  "codex_model",
  "rscript_path",
  "r_version",
  "os_version",
  "kernel",
  "architecture"
) %in% environment$key))
stopifnot(identical(
  environment$value[environment$key == "codex_path"],
  "/Users/liuyue/.local/bin/codex"
))
stopifnot(identical(
  environment$value[environment$key == "codex_version"],
  "codex-cli 0.145.0"
))
stopifnot(identical(
  environment$observability[environment$key == "codex_model"],
  "not_exposed"
))
stopifnot(!any(grepl(
  "(api[_-]?key|token|secret|password)",
  paste(environment$key, environment$value),
  ignore.case = TRUE,
  perl = TRUE
)))

source_binding <- read.delim(
  file.path(evidence_root, "source-binding.tsv"),
  sep = "\t",
  quote = "",
  comment.char = "",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(identical(
  names(source_binding),
  c(
    "record_type",
    "name",
    "commit",
    "git_object",
    "sha256",
    "worktree_state",
    "notes"
  )
))
tested_commit <- "2f92d6370563a12862c111d61f3831c83da8b025"
tested_tree <- "b17435309d9d8e4a967d8211e5b7c4e35e323389"
repo_binding <- source_binding[
  source_binding$record_type == "repository",
  ,
  drop = FALSE
]
stopifnot(nrow(repo_binding) == 1L)
stopifnot(identical(repo_binding$commit, tested_commit))
stopifnot(identical(repo_binding$git_object, tested_tree))
stopifnot(identical(repo_binding$worktree_state, "clean"))
resolved_tree <- system2(
  "git",
  c("-C", shQuote(repo_root), "rev-parse", paste0(tested_commit, "^{tree}")),
  stdout = TRUE
)
stopifnot(is.null(attr(resolved_tree, "status")))
stopifnot(identical(resolved_tree[[1L]], tested_tree))

component_bindings <- source_binding[
  source_binding$record_type == "component",
  ,
  drop = FALSE
]
required_components <- c(
  "skills/figureforge",
  "scripts/run_figureforge_live_evals.sh",
  "scripts/run_figureforge_plotting_eval.sh",
  "scripts/verify_figureforge_v110.sh",
  "skills/figureforge/scripts/package_skill.R"
)
stopifnot(setequal(component_bindings$name, required_components))
stopifnot(all(vapply(
  seq_len(nrow(component_bindings)),
  function(index) {
    component_name <- component_bindings$name[[index]]
    expected_object <- component_bindings$git_object[[index]]
    tested_object <- system2(
      "git",
      c(
        "-C",
        shQuote(repo_root),
        "rev-parse",
        paste0(tested_commit, ":", component_name)
      ),
      stdout = TRUE
    )
    current_object <- system2(
      "git",
      c(
        "-C",
        shQuote(repo_root),
        "rev-parse",
        paste0("HEAD:", component_name)
      ),
      stdout = TRUE
    )
    is.null(attr(tested_object, "status")) &&
      is.null(attr(current_object, "status")) &&
      identical(tested_object[[1L]], expected_object) &&
      identical(current_object[[1L]], expected_object)
  },
  logical(1)
)))
file_components <- component_bindings[
  file.info(file.path(repo_root, component_bindings$name))$isdir %in% FALSE,
  ,
  drop = FALSE
]
stopifnot(all(vapply(
  seq_len(nrow(file_components)),
  function(index) {
    identical(
      sha256_file(file.path(repo_root, file_components$name[[index]])),
      file_components$sha256[[index]]
    )
  },
  logical(1)
)))
skill_object <- system2(
  "git",
  c("-C", shQuote(repo_root), "rev-parse", "HEAD:skills/figureforge"),
  stdout = TRUE
)
stopifnot(is.null(attr(skill_object, "status")))
stopifnot(identical(
  skill_object[[1L]],
  component_bindings$git_object[
    component_bindings$name == "skills/figureforge"
  ]
))
documentation_bindings <- source_binding[
  source_binding$record_type == "documentation_only",
  ,
  drop = FALSE
]
stopifnot(all(c(
  "2983880a8d8f19cd53d73f4a64236e75c9b247c0",
  "f475a308709269f35a7253f8ce930f7ba7e49f10"
) %in% documentation_bindings$commit))

commands <- read.delim(
  file.path(evidence_root, "commands.tsv"),
  sep = "\t",
  quote = "",
  comment.char = "",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(identical(
  names(commands),
  c(
    "gate",
    "command",
    "evidence_time_start",
    "evidence_time_end",
    "time_basis",
    "source_commit",
    "worktree_state",
    "result"
  )
))
stopifnot(all(c(
  "deterministic_baseline",
  "live_triggers",
  "live_plotting",
  "deterministic_pre_certification",
  "independent_spec_review"
) %in% commands$gate))
stopifnot(all(commands$source_commit == tested_commit))
stopifnot(all(commands$worktree_state %in% c(
  "clean",
  "documentation_only_dirty"
)))
stopifnot(all(grepl(
  "^2026-07-26T[0-9]{2}:[0-9]{2}:[0-9]{2}\\+0800$",
  commands$evidence_time_end
)))
stopifnot(all(commands$result == "PASS"))
expected_command_times <- c(
  deterministic_baseline = "2026-07-26T00:58:51+0800|2026-07-26T00:59:21+0800",
  live_triggers = "2026-07-26T00:59:33+0800|2026-07-26T01:01:59+0800",
  live_plotting = "2026-07-26T01:02:04+0800|2026-07-26T01:05:56+0800",
  deterministic_pre_certification = "2026-07-26T01:18:13+0800|2026-07-26T01:18:43+0800",
  independent_spec_review = "2026-07-26T01:23:41+0800|2026-07-26T01:24:11+0800"
)
actual_command_times <- paste(
  commands$evidence_time_start,
  commands$evidence_time_end,
  sep = "|"
)
names(actual_command_times) <- commands$gate
stopifnot(identical(
  actual_command_times[names(expected_command_times)],
  expected_command_times
))

artifact_identities <- read.delim(
  file.path(evidence_root, "artifact-identities.tsv"),
  sep = "\t",
  quote = "",
  comment.char = "",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(nrow(artifact_identities) == 5L)
stopifnot(all(artifact_identities$bytes > 0L))
stopifnot(all(grepl(
  "^[0-9a-f]{64}$",
  artifact_identities$sha256
)))
stopifnot(setequal(
  artifact_identities$artifact,
  c(
    "delivered_plot.R",
    "delivered_plot.png",
    "delivered_plot.pdf",
    "independent_rerender_plot.png",
    "independent_rerender_plot.pdf"
  )
))
expected_artifact_hashes <- c(
  delivered_plot.R = "9462e1de9e6815043e4f057fcfea6bfc643b51b64438b711fc83b84de3b549e2",
  delivered_plot.png = "dedd99342143c323a0b72023649538a427101e3fff4d28870d784bc74bca9c24",
  delivered_plot.pdf = "65a3fae8e7851b5f7477a868bdc8e7d81bad4527d2b828a3fcea7657fed00fbc",
  independent_rerender_plot.png = "dedd99342143c323a0b72023649538a427101e3fff4d28870d784bc74bca9c24",
  independent_rerender_plot.pdf = "a45bbb6da086694141192c0fa9b283f294e8cb4f8d9df50d61e13105f93751ac"
)
actual_artifact_hashes <- artifact_identities$sha256
names(actual_artifact_hashes) <- artifact_identities$artifact
stopifnot(identical(
  actual_artifact_hashes[names(expected_artifact_hashes)],
  expected_artifact_hashes
))
expected_artifact_bytes <- c(
  delivered_plot.R = 5861L,
  delivered_plot.png = 194565L,
  delivered_plot.pdf = 424126L,
  independent_rerender_plot.png = 194565L,
  independent_rerender_plot.pdf = 424126L
)
actual_artifact_bytes <- as.integer(artifact_identities$bytes)
names(actual_artifact_bytes) <- artifact_identities$artifact
stopifnot(identical(
  actual_artifact_bytes[names(expected_artifact_bytes)],
  expected_artifact_bytes
))

package_identities <- read.delim(
  file.path(evidence_root, "package-identities.tsv"),
  sep = "\t",
  quote = "",
  comment.char = "",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(nrow(package_identities) == 3L)
stopifnot(length(unique(package_identities$manifest_sha256)) == 1L)
stopifnot(identical(
  unique(package_identities$manifest_sha256),
  "12752a5688f4939a6d5deb72a60cbc2587077d6ad0672d9ea8218d021ecf0398"
))
stopifnot(all(package_identities$manifest_rows == 156L))
stopifnot(length(unique(package_identities$archive_sha256)) == 3L)
stopifnot(all(package_identities$archive_bytes > 0L))
expected_archive_hashes <- c(
  deterministic_baseline = "cfe744653676ce11659b8251daf0c2fd21f33d0a92adfb803902c5b5a214f335",
  deterministic_pre_certification = "9a603bacde147df9526b861b94f92031be838cf4b5e5432b644fbce77079bacb",
  independent_spec_review = "906326178cbc99b20dd22d78a32cc4cc3a77913f158b11de6e9c37efc3450460"
)
actual_archive_hashes <- package_identities$archive_sha256
names(actual_archive_hashes) <- package_identities$run
stopifnot(identical(
  actual_archive_hashes[names(expected_archive_hashes)],
  expected_archive_hashes
))

checksum_lines <- readLines(
  file.path(evidence_root, "SHA256SUMS"),
  warn = FALSE,
  encoding = "UTF-8"
)
checksum_match <- regexec(
  "^([0-9a-f]{64})  ([A-Za-z0-9._-]+)$",
  checksum_lines
)
checksum_parts <- regmatches(checksum_lines, checksum_match)
stopifnot(all(lengths(checksum_parts) == 3L))
checksum_hashes <- vapply(checksum_parts, `[[`, character(1), 2L)
checksum_files <- vapply(checksum_parts, `[[`, character(1), 3L)
checksummed_files <- setdiff(evidence_files, "SHA256SUMS")
stopifnot(setequal(checksum_files, checksummed_files))
stopifnot(all(vapply(
  seq_along(checksum_files),
  function(index) {
    identical(
      sha256_file(file.path(evidence_root, checksum_files[[index]])),
      checksum_hashes[[index]]
    )
  },
  logical(1)
)))
stopifnot(!any(grepl(
  "\\.(jsonl|png|pdf|rds|rdata)$",
  evidence_files,
  ignore.case = TRUE
)))
evidence_text <- paste(vapply(
  setdiff(evidence_files, "SHA256SUMS"),
  function(filename) {
    paste(
      readLines(
        file.path(evidence_root, filename),
        warn = FALSE,
        encoding = "UTF-8"
      ),
      collapse = "\n"
    )
  },
  character(1)
), collapse = "\n")
for (sensitive_pattern in c(
  "OPENAI_API_KEY",
  "DEEPSEEK_API_KEY",
  "ANTHROPIC_API_KEY",
  "BEGIN PRIVATE KEY",
  "BEGIN OPENSSH PRIVATE KEY",
  "sk-[A-Za-z0-9]{20,}"
)) {
  stopifnot(!grepl(
    sensitive_pattern,
    evidence_text,
    perl = TRUE
  ))
}
stopifnot(contains_all(
  release,
  c(
    "[portable certification evidence](figureforge-skill-v1.1.0-evidence/README.md)",
    "12752a5688f4939a6d5deb72a60cbc2587077d6ad0672d9ea8218d021ecf0398"
  )
))
stopifnot(contains_all(
  release,
  c(
    "raw or unsanitized evaluation logs",
    "tracked sanitized certification logs"
  )
))
stopifnot(contains_all(
  evidence_readme,
  c(
    "Raw or unsanitized logs",
    "Tracked sanitized certification logs"
  )
))
stopifnot(grepl(
  "[portable certification evidence](figureforge-skill-v1.1.0-evidence/README.md)",
  status,
  fixed = TRUE
))

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
