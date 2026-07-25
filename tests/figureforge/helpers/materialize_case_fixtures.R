materialize_case_fixtures <- function(repo_root) {
  source_root <- file.path(
    repo_root,
    "tests",
    "fixtures",
    "figureforge",
    "cases"
  )
  target_root <- tempfile("figureforge-case-fixtures-")
  dir.create(target_root, recursive = TRUE)
  relative_files <- list.files(
    source_root,
    recursive = TRUE,
    all.files = TRUE,
    no.. = TRUE,
    include.dirs = FALSE
  )
  for (relative_path in relative_files) {
    target_path <- file.path(target_root, relative_path)
    dir.create(dirname(target_path), recursive = TRUE, showWarnings = FALSE)
    if (!file.copy(
      file.path(source_root, relative_path),
      target_path,
      overwrite = TRUE
    )) {
      stop("Unable to materialize case fixture: ", relative_path)
    }
  }
  writeLines(
    "synthetic runtime reproduction evidence",
    file.path(target_root, "authentic-public", "reproduction.pdf"),
    useBytes = TRUE
  )
  target_root
}
