# Keep regular-season field goals and identify clutch attempts.

library(tidyverse)

target_season <- 2026L
raw_dir <- file.path("data", "raw")
pbp_path <- file.path(raw_dir, "nba_pbp_2026.rds")
schedule_path <- file.path(raw_dir, "nba_schedule_2026.rds")

if (!all(file.exists(c(pbp_path, schedule_path)))) {
  stop("Run R/acquire_data.R first.", call. = FALSE)
}

clock_to_seconds <- function(x) {
  parts <- stringr::str_split_fixed(x, ":", 2)
  as.numeric(parts[, 1]) * 60 + as.numeric(parts[, 2])
}

regular_games <- readRDS(schedule_path) |>
  filter(
    season == target_season,
    season_type == 2,
    type_abbreviation == "STD",
    status_type_completed %in% TRUE
  ) |>
  transmute(game_id = as.numeric(game_id)) |>
  distinct()

shots <- readRDS(pbp_path) |>
  semi_join(regular_games, by = "game_id") |>
  filter(
    season == target_season,
    season_type == 2,
    shooting_play %in% TRUE,
    points_attempted %in% c(2, 3)
  ) |>
  arrange(game_id, game_play_number) |>
  mutate(
    made = scoring_play %in% TRUE,
    clock_seconds = clock_to_seconds(clock_display_value),
    pre_home_score = home_score - if_else(
      made & team_id == home_team_id, score_value, 0
    ),
    pre_away_score = away_score - if_else(
      made & team_id == away_team_id, score_value, 0
    ),
    pre_shot_margin = abs(pre_home_score - pre_away_score),
    clutch = period_number >= 4 &
      clock_seconds <= 300 &
      pre_shot_margin <= 5
  )

output <- file.path("data", "processed", "nba_shots_2026_classified.rds")
dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
saveRDS(shots, output, compress = "xz")
message("Saved ", nrow(shots), " field-goal attempts to ", output, ".")
