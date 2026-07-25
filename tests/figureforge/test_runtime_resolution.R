#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_runtime_resolution.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "runtime_resolution.R"
))

versions <- c(
  "/cli/Rscript" = "R scripting front-end version 4.5.0",
  "/env/Rscript" = "R scripting front-end version 4.4.2",
  "/usr/local/bin/Rscript" = "R scripting front-end version 4.3.3",
  "/path/Rscript" = "R scripting front-end version 4.2.1",
  "/old/Rscript" = "R scripting front-end version 3.6.3"
)
fake_probe <- function(path) {
  found <- path %in% names(versions)
  list(
    path = path,
    exists = found,
    executable = found,
    version_output = if (found) unname(versions[[path]]) else "",
    status = if (found) 0L else 1L
  )
}
fake_path <- function(name) {
  stopifnot(identical(name, "Rscript"))
  "/path/Rscript"
}

cli <- resolve_rscript(
  cli_path = "/cli/Rscript",
  env = "/env/Rscript",
  homebrew_path = "/usr/local/bin/Rscript",
  path_lookup = fake_path,
  probe = fake_probe,
  normalize = identity
)
stopifnot(identical(cli$path, "/cli/Rscript"))
stopifnot(identical(cli$source, "cli"))
stopifnot(identical(cli$version, "4.5.0"))

environment <- resolve_rscript(
  env = "/env/Rscript",
  homebrew_path = "/usr/local/bin/Rscript",
  path_lookup = fake_path,
  probe = fake_probe,
  normalize = identity
)
stopifnot(identical(environment$path, "/env/Rscript"))
stopifnot(identical(environment$source, "environment"))

homebrew <- resolve_rscript(
  env = "",
  homebrew_path = "/usr/local/bin/Rscript",
  path_lookup = fake_path,
  probe = fake_probe,
  normalize = identity
)
stopifnot(identical(homebrew$path, "/usr/local/bin/Rscript"))
stopifnot(identical(homebrew$source, "homebrew_compat"))

path_runtime <- resolve_rscript(
  env = "",
  homebrew_path = "/missing/Rscript",
  path_lookup = fake_path,
  probe = fake_probe,
  normalize = identity
)
stopifnot(identical(path_runtime$path, "/path/Rscript"))
stopifnot(identical(path_runtime$source, "path"))

invalid_cli <- tryCatch(
  {
    resolve_rscript(
      cli_path = "/missing/Rscript",
      env = "/env/Rscript",
      homebrew_path = "/usr/local/bin/Rscript",
      path_lookup = fake_path,
      probe = fake_probe,
      normalize = identity
    )
    ""
  },
  error = conditionMessage
)
stopifnot(grepl("CLI", invalid_cli, ignore.case = TRUE))
stopifnot(grepl("/missing/Rscript", invalid_cli, fixed = TRUE))

invalid_environment <- tryCatch(
  {
    resolve_rscript(
      env = "/missing/Rscript",
      homebrew_path = "/usr/local/bin/Rscript",
      path_lookup = fake_path,
      probe = fake_probe,
      normalize = identity
    )
    ""
  },
  error = conditionMessage
)
stopifnot(grepl("FIGUREFORGE_RSCRIPT", invalid_environment, fixed = TRUE))

unsupported <- tryCatch(
  {
    resolve_rscript(
      cli_path = "/old/Rscript",
      env = "",
      homebrew_path = "/missing/Rscript",
      path_lookup = fake_path,
      probe = fake_probe,
      normalize = identity
    )
    ""
  },
  error = conditionMessage
)
stopifnot(grepl("4.1", unsupported, fixed = TRUE))

missing <- tryCatch(
  {
    resolve_rscript(
      env = "",
      homebrew_path = "/missing/Rscript",
      path_lookup = function(name) "",
      probe = fake_probe,
      normalize = identity
    )
    ""
  },
  error = conditionMessage
)
stopifnot(grepl("homebrew_compat", missing, fixed = TRUE))
stopifnot(grepl("path", missing, fixed = TRUE))

host <- resolve_rscript(cli_path = "/usr/local/bin/Rscript")
stopifnot(identical(
  host$path,
  normalizePath("/usr/local/bin/Rscript", mustWork = TRUE)
))
stopifnot(identical(host$source, "cli"))
stopifnot(utils::compareVersion(host$version, "4.1.0") >= 0L)

entrypoints <- c(
  list.files(
    file.path(repo_root, "skills", "figureforge", "scripts"),
    pattern = "\\.R$",
    full.names = TRUE
  ),
  file.path(repo_root, "examples", "public-demo", "run_demo.sh"),
  file.path(repo_root, "scripts", "verify_figureforge_v1.sh")
)
fixed_runtime <- vapply(entrypoints, function(path) {
  any(grepl(
    "/usr/local/bin/Rscript",
    readLines(path, warn = FALSE, encoding = "UTF-8"),
    fixed = TRUE
  ))
}, logical(1))
stopifnot(!any(fixed_runtime))

message("runtime resolution tests: PASS")
