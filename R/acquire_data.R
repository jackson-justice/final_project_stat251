# Download and cache the 2025-26 NBA data used by the project.

if (!requireNamespace("hoopR", quietly = TRUE)) {
  stop("Install hoopR before running this script.", call. = FALSE)
}

season <- 2026L
raw_dir <- file.path("data", "raw")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

load_cached <- function(filename, download) {
  path <- file.path(raw_dir, filename)

  if (file.exists(path)) {
    message("Using cached file: ", path)
    return(readRDS(path))
  }

  data <- download()
  saveRDS(data, path, compress = "xz")
  message("Saved: ", path)
  data
}

nba_pbp <- load_cached(
  "nba_pbp_2026.rds",
  function() hoopR::load_nba_pbp(seasons = season)
)

nba_schedule <- load_cached(
  "nba_schedule_2026.rds",
  function() hoopR::load_nba_schedule(seasons = season)
)

message("Raw data are ready in ", raw_dir, ".")
