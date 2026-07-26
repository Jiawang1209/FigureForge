#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_live_mode_eval_contract.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)

harness_path <- file.path(
  repo_root,
  "scripts",
  "run_figureforge_mode_evals.sh"
)
evaluator_path <- file.path(
  repo_root,
  "scripts",
  "lib",
  "live_mode_evaluation.R"
)
evaluator_cli_path <- file.path(
  repo_root,
  "scripts",
  "evaluate_figureforge_mode_probe.R"
)
verifier_path <- file.path(
  repo_root,
  "scripts",
  "verify_figureforge_v110.sh"
)

stopifnot(file.exists(harness_path))
stopifnot(file.exists(evaluator_path))
stopifnot(file.exists(evaluator_cli_path))

harness <- readLines(harness_path, warn = FALSE, encoding = "UTF-8")
verifier <- readLines(verifier_path, warn = FALSE, encoding = "UTF-8")
stopifnot(any(grepl("package_skill[.]R", harness)))
stopifnot(any(grepl("case_based", harness, fixed = TRUE)))
stopifnot(any(grepl("general_fallback", harness, fixed = TRUE)))
stopifnot(sum(grepl("--ephemeral", harness, fixed = TRUE)) >= 1L)
stopifnot(any(grepl("evaluate_figureforge_mode_probe[.]R", harness)))
stopifnot(any(grepl(
  "successful cat or sed commands",
  harness,
  fixed = TRUE
)))
stopifnot(any(grepl("trusted-install", harness, fixed = TRUE)))
stopifnot(any(grepl("--manifest", harness, fixed = TRUE)))
stopifnot(any(grepl("--trusted-cat", harness, fixed = TRUE)))
stopifnot(any(grepl("--trusted-sed", harness, fixed = TRUE)))
stopifnot(!any(grepl("Sys.which", harness, fixed = TRUE)))
stopifnot(any(grepl('"/bin", "/usr/bin"', harness, fixed = TRUE)))
stopifnot(any(grepl("chmod -R a-w", harness, fixed = TRUE)))
stopifnot(any(grepl("run_figureforge_mode_evals[.]sh", verifier)))

live_start <- which(verifier == 'if [ "$RUN_LIVE" = "1" ]; then')
live_end <- which(verifier == "else")
live_end <- live_end[live_end > live_start[[1L]]][[1L]]
live_block <- verifier[live_start[[1L]]:live_end]
stopifnot(any(grepl("run_figureforge_mode_evals[.]sh", live_block)))

source(evaluator_path)
trusted_reader_paths <- live_mode_fixed_reader_paths()
stopifnot(live_mode_trusted_reader_paths(trusted_reader_paths))
trusted_cat <- trusted_reader_paths[["cat"]]
trusted_sed <- trusted_reader_paths[["sed"]]

startup_shadow_dir <- tempfile(
  "figureforge-path-shadow-",
  tmpdir = "/private/tmp"
)
dir.create(startup_shadow_dir)
startup_fake_cat <- file.path(startup_shadow_dir, "cat")
startup_fake_sed <- file.path(startup_shadow_dir, "sed")
writeLines("#!/bin/sh\nexit 0", startup_fake_cat)
writeLines("#!/bin/sh\nexit 0", startup_fake_sed)
Sys.chmod(c(startup_fake_cat, startup_fake_sed), mode = "0755")
original_path <- Sys.getenv("PATH")
Sys.setenv(PATH = paste(startup_shadow_dir, original_path, sep = ":"))
stopifnot(identical(
  normalizePath(Sys.which("cat"), mustWork = TRUE),
  normalizePath(startup_fake_cat, mustWork = TRUE)
))
stopifnot(identical(
  normalizePath(Sys.which("sed"), mustWork = TRUE),
  normalizePath(startup_fake_sed, mustWork = TRUE)
))
stopifnot(identical(
  live_mode_fixed_reader_paths(),
  trusted_reader_paths
))
stopifnot(!live_mode_trusted_reader_paths(c(
  cat = normalizePath(startup_fake_cat, mustWork = TRUE),
  sed = trusted_sed
)))
Sys.setenv(PATH = original_path)

fixture_root <- tempfile("figureforge-live-mode-eval-")
workspace <- file.path(fixture_root, "workspace")
skill_root <- file.path(
  fixture_root,
  "trusted-install",
  "figureforge"
)
output_dir <- file.path(workspace, "figureforge-output")
trace_dir <- file.path(output_dir, ".figureforge")
case_dir <- file.path(
  skill_root,
  "public-cases",
  "public-scatter-fit"
)
dir.create(trace_dir, recursive = TRUE)
dir.create(case_dir, recursive = TRUE)
writeLines("case evidence", file.path(case_dir, "case.md"))
writeLines("plot <- ggplot2::ggplot()", file.path(case_dir, "plot.R"))
writeLines("Status: review_required", file.path(case_dir, "qa.md"))
writeLines("script", file.path(output_dir, "plot.R"))
writeBin(as.raw(c(137, 80, 78, 71, 1)), file.path(output_dir, "plot.png"))
writeBin(charToRaw("%PDF-1.4\n"), file.path(output_dir, "plot.pdf"))

manifest_path <- file.path(fixture_root, "release-manifest.csv")
write_fixture_manifest <- function() {
  installed_files <- list.files(
    skill_root,
    recursive = TRUE,
    all.files = TRUE,
    no.. = TRUE,
    include.dirs = FALSE,
    full.names = TRUE
  )
  relative_files <- substring(
    installed_files,
    nchar(skill_root) + 2L
  )
  write.csv(
    data.frame(
      source_path = paste0("fixture/", relative_files),
      package_path = paste0("figureforge/", relative_files),
      sha256 = vapply(
        installed_files,
        live_mode_sha256,
        character(1L)
      ),
      bytes = as.numeric(file.info(installed_files)$size),
      stringsAsFactors = FALSE
    ),
    manifest_path,
    row.names = FALSE
  )
}
write_fixture_manifest()

receipt <- data.frame(
  receipt_schema_version = "2",
  receipt_generator = "figureforge-search_cases",
  search_query_sha256 = paste(rep("a", 64L), collapse = ""),
  search_intent = "relationship",
  search_scope = "public",
  schema_sha256 = paste(rep("a", 64L), collapse = ""),
  search_limit = "5",
  completed_only = "FALSE",
  explain_scores = "TRUE",
  result_rank = "1",
  case_id_sha256 = paste(rep("b", 64L), collapse = ""),
  score = "20",
  stringsAsFactors = FALSE
)
write.csv(
  receipt,
  file.path(trace_dir, "case-search.csv"),
  row.names = FALSE
)
writeLines(
  c(
    "schema_version: 1",
    "generation_mode: case_based",
    "figureforge_version: 1.1.0",
    paste0("generated_script_sha256: ", paste(rep("c", 64L), collapse = "")),
    "claim: case_grounded",
    paste0("search_query_sha256: ", paste(rep("a", 64L), collapse = "")),
    "search_intent: relationship",
    "search_receipt_file: case-search.csv",
    paste0("search_receipt_sha256: ", paste(rep("d", 64L), collapse = "")),
    "primary_case_id: public-scatter-fit"
  ),
  file.path(trace_dir, "case-trace.yml")
)
validation_log <- file.path(fixture_root, "validation.log")
writeLines(
  c(
    "Verification level: strict",
    "Case trace validation OK: case-trace.yml"
  ),
  validation_log
)

json_command <- function(command, exit_code = 0L) {
  jsonlite::toJSON(
    list(
      type = "item.completed",
      item = list(
        type = "command_execution",
        command = command,
        exit_code = exit_code
      )
    ),
    auto_unbox = TRUE
  )
}
transcript <- file.path(fixture_root, "transcript.jsonl")
writeLines(
  c(
    json_command(sprintf(
      "/bin/zsh -lc %s",
      shQuote(paste(
        trusted_sed,
        "-n '1,240p'",
        shQuote(file.path(case_dir, "case.md"))
      ))
    )),
    json_command(paste(
      trusted_sed,
      "-n '1,240p'",
      shQuote(file.path(case_dir, "plot.R"))
    )),
    json_command(paste(
      trusted_cat,
      shQuote(file.path(case_dir, "qa.md"))
    ))
  ),
  transcript
)

result <- evaluate_live_mode_probe(
  expected_mode = "case_based",
  workspace_root = workspace,
  installed_skill_root = skill_root,
  manifest_path = manifest_path,
  trusted_reader_paths = trusted_reader_paths,
  transcript_path = transcript,
  validator_log = validation_log,
  validator_status = 0L
)
stopifnot(identical(result$generation_mode[[1L]], "case_based"))
stopifnot(identical(result$claim[[1L]], "case_grounded"))
stopifnot(isTRUE(result$schema_bound_receipt[[1L]]))
stopifnot(isTRUE(result$strict_validation[[1L]]))
stopifnot(isTRUE(result$installed_skill_integrity[[1L]]))
stopifnot(isTRUE(result$trusted_readers[[1L]]))
stopifnot(isTRUE(result$trusted_case_evidence[[1L]]))
stopifnot(isTRUE(result$case_md_read[[1L]]))
stopifnot(isTRUE(result$plot_r_read[[1L]]))
stopifnot(isTRUE(result$qa_md_read[[1L]]))
stopifnot(isTRUE(result$artifacts_present[[1L]]))
stopifnot(isTRUE(result$passed[[1L]]))

batched_transcript <- file.path(
  fixture_root,
  "batched-trusted-read-transcript.jsonl"
)
writeLines(
  json_command(sprintf(
    "/bin/zsh -lc %s",
    shQuote(paste(
      paste(
        trusted_cat,
        shQuote(file.path(case_dir, "case.md"))
      ),
      paste(
        trusted_cat,
        shQuote(file.path(case_dir, "plot.R"))
      ),
      paste(
        trusted_cat,
        shQuote(file.path(case_dir, "qa.md"))
      ),
      sep = " && "
    ))
  )),
  batched_transcript
)
for (evidence_name in c("case.md", "plot.R", "qa.md")) {
  stopifnot(live_mode_transcript_reads(
    batched_transcript,
    workspace,
    file.path(case_dir, evidence_name),
    trusted_reader_paths = trusted_reader_paths
  ))
}

failed_transcript <- file.path(fixture_root, "failed-transcript.jsonl")
writeLines(
  c(
    json_command(paste(
      trusted_cat,
      shQuote(file.path(case_dir, "case.md"))
    ), 1L),
    json_command("echo case.md plot.R qa.md")
  ),
  failed_transcript
)
failed_result <- evaluate_live_mode_probe(
  expected_mode = "case_based",
  workspace_root = workspace,
  installed_skill_root = skill_root,
  manifest_path = manifest_path,
  trusted_reader_paths = trusted_reader_paths,
  transcript_path = failed_transcript,
  validator_log = validation_log,
  validator_status = 0L
)
stopifnot(!isTRUE(failed_result$case_md_read[[1L]]))
stopifnot(!isTRUE(failed_result$plot_r_read[[1L]]))
stopifnot(!isTRUE(failed_result$qa_md_read[[1L]]))
stopifnot(!isTRUE(failed_result$passed[[1L]]))

original_plot_r <- readLines(
  file.path(case_dir, "plot.R"),
  warn = FALSE
)
writeLines("mutated by agent", file.path(case_dir, "plot.R"))
mutated_install <- evaluate_live_mode_probe(
  expected_mode = "case_based",
  workspace_root = workspace,
  installed_skill_root = skill_root,
  manifest_path = manifest_path,
  trusted_reader_paths = trusted_reader_paths,
  transcript_path = transcript,
  validator_log = validation_log,
  validator_status = 0L
)
stopifnot(!isTRUE(mutated_install$installed_skill_integrity[[1L]]))
stopifnot(!isTRUE(mutated_install$passed[[1L]]))
writeLines(original_plot_r, file.path(case_dir, "plot.R"))

original_case_md <- readLines(
  file.path(case_dir, "case.md"),
  warn = FALSE
)
escaped_case_md <- file.path(fixture_root, "escaped-case.md")
writeLines(original_case_md, escaped_case_md)
unlink(file.path(case_dir, "case.md"))
stopifnot(file.symlink(escaped_case_md, file.path(case_dir, "case.md")))
symlink_escape <- evaluate_live_mode_probe(
  expected_mode = "case_based",
  workspace_root = workspace,
  installed_skill_root = skill_root,
  manifest_path = manifest_path,
  trusted_reader_paths = trusted_reader_paths,
  transcript_path = transcript,
  validator_log = validation_log,
  validator_status = 0L
)
stopifnot(!isTRUE(symlink_escape$installed_skill_integrity[[1L]]))
stopifnot(!isTRUE(symlink_escape$trusted_case_evidence[[1L]]))
stopifnot(!isTRUE(symlink_escape$passed[[1L]]))
unlink(file.path(case_dir, "case.md"))
writeLines(original_case_md, file.path(case_dir, "case.md"))

fake_bin <- file.path(workspace, "fake-bin")
dir.create(fake_bin, recursive = TRUE)
fake_cat <- file.path(fake_bin, "cat")
fake_sed <- file.path(fake_bin, "sed")
writeLines("#!/bin/sh\nexit 0", fake_cat)
writeLines("#!/bin/sh\nexit 0", fake_sed)
Sys.chmod(c(fake_cat, fake_sed), mode = "0755")
linked_cat <- file.path(fake_bin, "linked-cat")
stopifnot(file.symlink(trusted_cat, linked_cat))
stopifnot(!live_mode_trusted_reader_paths(c(
  cat = fake_cat,
  sed = trusted_sed
)))
stopifnot(!live_mode_trusted_reader_paths(c(
  cat = linked_cat,
  sed = trusted_sed
)))

adversarial_commands <- c(
  paste("cat", shQuote(file.path(case_dir, "case.md"))),
  paste("sed -n '1,240p'", shQuote(file.path(case_dir, "case.md"))),
  paste(fake_cat, shQuote(file.path(case_dir, "case.md"))),
  paste(
    fake_sed,
    "-n '1,240p'",
    shQuote(file.path(case_dir, "case.md"))
  ),
  paste(linked_cat, shQuote(file.path(case_dir, "case.md"))),
  paste(
    "env",
    paste0("PATH=", shQuote(fake_bin)),
    "cat",
    shQuote(file.path(case_dir, "case.md"))
  ),
  paste(
    "true || cat",
    shQuote(file.path(case_dir, "case.md")),
    "> marker"
  ),
  paste(
    "false && cat",
    shQuote(file.path(case_dir, "case.md")),
    "|| true"
  ),
  paste(
    "cat",
    shQuote(file.path(case_dir, "case.md")),
    "> marker"
  ),
  paste(
    "cat <",
    shQuote(file.path(case_dir, "case.md"))
  ),
  paste0(
    "(cat ",
    shQuote(file.path(case_dir, "case.md")),
    ")"
  ),
  paste0(
    "sh -c ",
    shQuote(paste("cat", shQuote(file.path(case_dir, "case.md"))))
  ),
  sprintf(
    "/bin/zsh -lc %s",
    shQuote(paste(
      "true || cat",
      shQuote(file.path(case_dir, "case.md")),
      "> marker"
    ))
  ),
  sprintf(
    "/tmp/fake/zsh -lc %s",
    shQuote(paste(
      "cat",
      shQuote(file.path(case_dir, "case.md"))
    ))
  )
)
for (adversarial_command in adversarial_commands) {
  adversarial_transcript <- tempfile(
    "figureforge-adversarial-transcript-",
    fileext = ".jsonl"
  )
  writeLines(json_command(adversarial_command), adversarial_transcript)
  stopifnot(!live_mode_transcript_reads(
    adversarial_transcript,
    workspace,
    file.path(case_dir, "case.md"),
    trusted_reader_paths = trusted_reader_paths
  ))
}

writeLines(
  c(
    "schema_version: 1",
    "generation_mode: general_fallback",
    "figureforge_version: 1.1.0",
    paste0("generated_script_sha256: ", paste(rep("c", 64L), collapse = "")),
    "claim: general_method",
    paste0("search_query_sha256: ", paste(rep("f", 64L), collapse = "")),
    "search_intent: ordination",
    "search_receipt_file: case-search.csv",
    paste0("search_receipt_sha256: ", paste(rep("d", 64L), collapse = "")),
    "fallback_reason: no sufficiently relevant public case"
  ),
  file.path(trace_dir, "case-trace.yml")
)
receipt$search_query_sha256 <- paste(rep("f", 64L), collapse = "")
receipt$search_intent <- "ordination"
write.csv(
  receipt,
  file.path(trace_dir, "case-search.csv"),
  row.names = FALSE
)
fallback_result <- evaluate_live_mode_probe(
  expected_mode = "general_fallback",
  workspace_root = workspace,
  installed_skill_root = skill_root,
  manifest_path = manifest_path,
  trusted_reader_paths = trusted_reader_paths,
  transcript_path = failed_transcript,
  validator_log = validation_log,
  validator_status = 0L
)
stopifnot(identical(fallback_result$claim[[1L]], "general_method"))
stopifnot(isTRUE(fallback_result$schema_bound_receipt[[1L]]))
stopifnot(isTRUE(fallback_result$strict_validation[[1L]]))
stopifnot(isTRUE(fallback_result$passed[[1L]]))

fallback_lines <- readLines(
  file.path(trace_dir, "case-trace.yml"),
  warn = FALSE
)
writeLines(
  sub(
    "claim: general_method",
    "claim: case_grounded",
    fallback_lines,
    fixed = TRUE
  ),
  file.path(trace_dir, "case-trace.yml")
)
wrong_claim <- evaluate_live_mode_probe(
  expected_mode = "general_fallback",
  workspace_root = workspace,
  installed_skill_root = skill_root,
  manifest_path = manifest_path,
  trusted_reader_paths = trusted_reader_paths,
  transcript_path = failed_transcript,
  validator_log = validation_log,
  validator_status = 0L
)
stopifnot(!isTRUE(wrong_claim$passed[[1L]]))
writeLines(fallback_lines, file.path(trace_dir, "case-trace.yml"))

receipt$schema_sha256 <- "none"
write.csv(
  receipt,
  file.path(trace_dir, "case-search.csv"),
  row.names = FALSE
)
unbound <- evaluate_live_mode_probe(
  expected_mode = "general_fallback",
  workspace_root = workspace,
  installed_skill_root = skill_root,
  manifest_path = manifest_path,
  trusted_reader_paths = trusted_reader_paths,
  transcript_path = failed_transcript,
  validator_log = validation_log,
  validator_status = 0L
)
stopifnot(!isTRUE(unbound$schema_bound_receipt[[1L]]))
stopifnot(!isTRUE(unbound$passed[[1L]]))

receipt$schema_sha256 <- paste(rep("a", 64L), collapse = "")
write.csv(
  receipt,
  file.path(trace_dir, "case-search.csv"),
  row.names = FALSE
)
cli_root <- file.path(fixture_root, "cli with spaces")
dir.create(file.path(cli_root, "lib"), recursive = TRUE)
stopifnot(file.copy(
  evaluator_cli_path,
  file.path(cli_root, "evaluate_figureforge_mode_probe.R")
))
stopifnot(file.copy(
  evaluator_path,
  file.path(cli_root, "lib", "live_mode_evaluation.R")
))
cli_output <- file.path(fixture_root, "cli-summary.csv")
cli_result <- system2(
  "/usr/local/bin/Rscript",
  c(
    shQuote(file.path(cli_root, "evaluate_figureforge_mode_probe.R")),
    "--expected-mode", "general_fallback",
    "--workspace", shQuote(workspace),
    "--installed-skill", shQuote(skill_root),
    "--manifest", shQuote(manifest_path),
    "--trusted-cat", shQuote(trusted_cat),
    "--trusted-sed", shQuote(trusted_sed),
    "--transcript", shQuote(failed_transcript),
    "--validator-log", shQuote(validation_log),
    "--validator-status", "0",
    "--output", shQuote(cli_output)
  ),
  stdout = TRUE,
  stderr = TRUE
)
if (!is.null(attr(cli_result, "status"))) {
  stop(
    "evaluator CLI failed from a path with spaces:\n",
    paste(cli_result, collapse = "\n"),
    call. = FALSE
  )
}
cli_summary <- read.csv(
  cli_output,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(isTRUE(cli_summary$passed[[1L]]))

message("live mode eval contract tests: PASS")
