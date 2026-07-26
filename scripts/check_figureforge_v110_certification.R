#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "scripts/check_figureforge_v110_certification.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

for (library_path in c(
  "skills/figureforge/lib/distribution_validation.R",
  "skills/figureforge/lib/checksums.R",
  "skills/figureforge/lib/release_packaging.R",
  "scripts/lib/release_certification.R"
)) {
  source(file.path(repo_root, library_path))
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0L) {
  identity_path <- file.path(
    repo_root,
    "docs",
    "figureforge-skill-v1.1.0-evidence",
    "certification-identity.tsv"
  )
} else if (length(args) == 2L && identical(args[[1L]], "--identity")) {
  identity_path <- args[[2L]]
} else {
  message(
    "Usage: check_figureforge_v110_certification.R ",
    "[--identity PATH]"
  )
  quit(status = 2L)
}

result <- tryCatch(
  check_figureforge_current_certification(repo_root, identity_path),
  error = function(error) {
    message("Certification identity check failed: ", conditionMessage(error))
    quit(status = 1L)
  }
)
if (!isTRUE(result$ok)) {
  message(
    "FigureForge Skill 1.1.0 is not currently certified: ",
    paste(result$failures, collapse = ", ")
  )
  quit(status = 1L)
}
message(
  "FigureForge Skill 1.1.0 certification identity: CURRENT; source=",
  result$certified$certified_source_commit,
  "; manifest=",
  result$certified$manifest_sha256
)
