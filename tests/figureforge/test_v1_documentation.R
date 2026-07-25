#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_v1_documentation.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)

read_repo_document <- function(path) {
  paste(
    readLines(file.path(repo_root, path), warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
}

english <- read_repo_document("README.md")
chinese <- read_repo_document("README.zh.md")
status <- read_repo_document("docs/figureforge-skill-mvp-status.md")
release_path <- file.path(
  repo_root,
  "docs",
  "figureforge-skill-v1-release.md"
)
stopifnot(file.exists(release_path))
release <- read_repo_document("docs/figureforge-skill-v1-release.md")

fixed_position <- function(text, needle) {
  position <- regexpr(needle, text, fixed = TRUE)[[1L]]
  stopifnot(position > 0L)
  as.integer(position)
}

english_terms <- c(
  "1.1.0",
  "plotting capability enhancer",
  "real data",
  "primary case",
  "secondary cases",
  "plot.R",
  "plot.png",
  "plot.pdf",
  "Rscript plot.R <input-file> <output-directory>",
  "Maintainer workflow",
  "current implementation and release candidate",
  "live-model and release certification remain pending",
  "FigureForge Skill 1.0.1 remains the latest locally certified release",
  "15 public cases",
  "24 synthetic stress fixtures",
  "doctor.R",
  "create_adaptation.R",
  "match_schema.R",
  "visual_qa.R",
  "package_skill.R",
  "review_required",
  "private corpus",
  "MCP is planned and unimplemented"
)
stopifnot(all(vapply(
  english_terms,
  grepl,
  logical(1),
  x = english,
  fixed = TRUE
)))

chinese_terms <- c(
  "1.1.0",
  "绘图能力增强器",
  "真实数据",
  "主案例",
  "辅助案例",
  "plot.R",
  "plot.png",
  "plot.pdf",
  "Rscript plot.R <input-file> <output-directory>",
  "维护者工作流",
  "当前实现与发布候选版本",
  "真实模型与发布认证仍待完成",
  "FigureForge Skill 1.0.1 仍是最新完成本地认证的发布版本",
  "15 个公开案例",
  "24 个合成压力测试夹具",
  "doctor.R",
  "create_adaptation.R",
  "match_schema.R",
  "visual_qa.R",
  "package_skill.R",
  "review_required",
  "私有案例库",
  "MCP 状态为 planned 且尚未实现"
)
stopifnot(all(vapply(
  chinese_terms,
  grepl,
  logical(1),
  x = chinese,
  fixed = TRUE
)))

english_positions <- vapply(
  c(
    "**A case-enhanced R scientific plotting capability for AI agents.**",
    "## FigureForge Skill 1.1.0",
    "current implementation and release candidate",
    "Use `xxx.csv` with FigureForge to draw a scatter plot and give me the R script.",
    "## Maintainer workflow"
  ),
  fixed_position,
  integer(1),
  text = english
)
stopifnot(all(diff(english_positions) > 0L))

chinese_positions <- vapply(
  c(
    "**面向 AI 智能体、由案例增强的 R 科研绘图能力。**",
    "## FigureForge Skill 1.1.0",
    "当前实现与发布候选版本",
    "使用 `xxx.csv` 数据，基于 FigureForge 帮我绘制一个散点图，并给我一份 R 脚本。",
    "## 维护者工作流"
  ),
  fixed_position,
  integer(1),
  text = chinese
)
stopifnot(all(diff(chinese_positions) > 0L))

stopifnot(!grepl(
  "Open the case's `case.md`, `data.csv`, `plot.R`, and `qa.md`",
  english,
  fixed = TRUE
))
stopifnot(!grepl(
  "打开案例的 `case.md`、`data.csv`、`plot.R` 和",
  chinese,
  fixed = TRUE
))

status_terms <- c(
  "FigureForge Skill 1.1.0",
  "case-enhanced R plotting capability",
  "real data",
  "natural request",
  "plot.R",
  "plot.png",
  "plot.pdf",
  "User plotting behavior",
  "Maintainer and release reliability",
  "MCP is planned and unimplemented"
)
stopifnot(all(vapply(
  status_terms,
  grepl,
  logical(1),
  x = status,
  fixed = TRUE
)))

combined <- paste(english, chinese, status, release, sep = "\n")
stopifnot(grepl("public-bar-grouped", release, fixed = TRUE))
stopifnot(grepl("public-multipanel", release, fixed = TRUE))
stopifnot(grepl("1.0.0", release, fixed = TRUE))
stopifnot(grepl("12", release, fixed = TRUE))
stopifnot(grepl("24", release, fixed = TRUE))
stopifnot(grepl("165", release, fixed = TRUE))
stopifnot(grepl("MCP", release, fixed = TRUE))

command_paths <- unique(regmatches(
  combined,
  gregexpr(
    "(skills/figureforge/scripts/[a-z0-9_-]+\\.R|examples/public-demo/run_demo\\.sh)",
    combined,
    perl = TRUE
  )
)[[1L]])
stopifnot(length(command_paths) >= 8L)
stopifnot(all(file.exists(file.path(repo_root, command_paths))))

message("v1 documentation tests: PASS")
