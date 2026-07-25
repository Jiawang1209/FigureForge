args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) stop("Expected input_path and output_path")
input_path <- args[[1L]]
output_path <- args[[2L]]
data <- read.csv(input_path, check.names = FALSE)
if (!all(c("x", "y") %in% names(data))) stop("Missing x or y")
grDevices::pdf(output_path)
graphics::plot(data$x, data$y)
grDevices::dev.off()
