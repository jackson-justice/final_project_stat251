# Create the player summary and two proposal figures.

library(tidyverse)

shots_path <- file.path("data", "processed", "nba_shots_2026_classified.rds")

if (!file.exists(shots_path)) {
  stop("Run R/acquire_data.R and R/clean_data.R first.", call. = FALSE)
}

player_summary <- readRDS(shots_path) |>
  mutate(
    player_name = coalesce(
      athlete_name_1,
      paste("Player", athlete_id_1)
    )
  ) |>
  group_by(athlete_id_1, player_name) |>
  summarize(
    clutch_games = n_distinct(game_id[clutch %in% TRUE]),
    clutch_fgm = sum(made & clutch, na.rm = TRUE),
    clutch_fga = sum(clutch, na.rm = TRUE),
    non_clutch_fgm = sum(made & !clutch, na.rm = TRUE),
    non_clutch_fga = sum(!clutch, na.rm = TRUE),
    .groups = "drop"
  ) |>
  filter(clutch_fga > 0, non_clutch_fga > 0) |>
  mutate(
    clutch_fg_pct = clutch_fgm / clutch_fga,
    non_clutch_fg_pct = non_clutch_fgm / non_clutch_fga,
    fg_pct_difference = clutch_fg_pct - non_clutch_fg_pct
  ) |>
  arrange(desc(clutch_fga))

processed_dir <- file.path("data", "processed")
figures_dir <- "figures"
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, showWarnings = FALSE)
write_csv(player_summary, file.path(processed_dir, "player_shooting_summary.csv"))

plot_theme <- theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title.position = "plot"
  )
percent_labels <- scales::label_percent(accuracy = 1)

comparison_plot <- player_summary |>
  slice_max(clutch_fga, n = 20, with_ties = FALSE) |>
  ggplot(aes(y = reorder(player_name, fg_pct_difference))) +
  geom_segment(
    aes(
      x = non_clutch_fg_pct,
      xend = clutch_fg_pct,
      yend = player_name
    ),
    color = "grey75",
    linewidth = 0.8
  ) +
  geom_point(aes(x = non_clutch_fg_pct, color = "Non-clutch"), size = 2.5) +
  geom_point(aes(x = clutch_fg_pct, color = "Clutch"), size = 2.5) +
  scale_color_manual(
    values = c("Clutch" = "#B22222", "Non-clutch" = "#315A7D"),
    name = NULL
  ) +
  scale_x_continuous(labels = percent_labels) +
  labs(
    title = "Clutch and non-clutch field-goal percentage",
    subtitle = "Twenty players with the most clutch field-goal attempts",
    x = "Field-goal percentage",
    y = NULL
  ) +
  plot_theme +
  theme(
    legend.position = "top",
    panel.grid.major.y = element_blank()
  )

attempt_plot <- ggplot(
  player_summary,
  aes(x = clutch_fga, y = fg_pct_difference)
) +
  geom_hline(yintercept = 0, color = "grey40", linewidth = 0.6) +
  geom_point(color = "#315A7D", alpha = 0.6, size = 1.8) +
  scale_y_continuous(labels = percent_labels) +
  labs(
    title = "Observed shooting difference and clutch attempts",
    subtitle = "All players with at least one clutch field-goal attempt",
    x = "Clutch field-goal attempts",
    y = "Clutch FG% minus non-clutch FG%"
  ) +
  plot_theme

ggsave(
  file.path(figures_dir, "player_fg_comparison.png"),
  comparison_plot,
  width = 7, height = 4.4, dpi = 300, bg = "white"
)
ggsave(
  file.path(figures_dir, "attempts_vs_difference.png"),
  attempt_plot,
  width = 7, height = 3.8, dpi = 300, bg = "white"
)

message("Saved the player summary and two figures.")
