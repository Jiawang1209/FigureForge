figureforge_sha256 <- function(path) {
  path <- normalizePath(path, mustWork = TRUE)
  tools <- c("sha256sum", "shasum")
  available <- unname(Sys.which(tools))

  output <- if (nzchar(available[[1L]])) {
    system2(available[[1L]], shQuote(path), stdout = TRUE, stderr = TRUE)
  } else if (nzchar(available[[2L]])) {
    system2(
      available[[2L]],
      c("-a", "256", shQuote(path)),
      stdout = TRUE,
      stderr = TRUE
    )
  } else if (file.exists("/usr/bin/python3")) {
    code <- paste(
      "import hashlib, pathlib, sys;",
      "print(hashlib.sha256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest())"
    )
    system2(
      "/usr/bin/python3",
      c("-c", shQuote(code), shQuote(path)),
      stdout = TRUE,
      stderr = TRUE
    )
  } else {
    stop("No SHA-256 implementation is available")
  }

  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop("Unable to calculate SHA-256 for: ", path)
  }
  hash <- strsplit(output[[1L]], "\\s+", perl = TRUE)[[1L]][[1L]]
  hash <- tolower(hash)
  if (!grepl("^[0-9a-f]{64}$", hash, perl = TRUE)) {
    stop("Invalid SHA-256 output for: ", path)
  }
  hash
}
