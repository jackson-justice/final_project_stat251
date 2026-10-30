# Create the player summary and two proposal figures.
#
# CHANGE SUMMARY:
# 1. Added clutch and non-clutch three-point field goals made (3PFGM).
# 2. Replaced FG% calculations with effective FG% (eFG%).
# 3. Updated both visualizations to compare eFG% instead of FG%.
# 4. Kept existing CSV and figure filenames for compatibility.

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

    # UNCHANGED: FGM and FGA are still needed for eFG%.
    clutch_fgm = sum(made & clutch, na.rm = TRUE),
    clutch_fga = sum(clutch, na.rm = TRUE),

    # ADDED: Made three-pointers in clutch situations.
    clutch_3pfgm = sum(
      made & clutch & points_attempted == 3,
      na.rm = TRUE
    ),

    # ADDED: Total clutch three-point attempts.
    clutch_3pa = sum(clutch & points_attempted == 3, na.rm = TRUE),

    # UNCHANGED: Non-clutch FGM and FGA.
    non_clutch_fgm = sum(made & !clutch, na.rm = TRUE),
    non_clutch_fga = sum(!clutch, na.rm = TRUE),

    # ADDED: Made three-pointers in non-clutch situations.
    non_clutch_3pfgm = sum(
      made & !clutch & points_attempted == 3,
      na.rm = TRUE
    ),
    
    # ADDED: Total non-clutch three-point attempts.
    non_clutch_3pa = sum(!clutch & points_attempted == 3, na.rm = TRUE),

    # ADDED: Derive 2PT attempts and makes for Bayesian analysis.
    clutch_2pa = clutch_fga - clutch_3pa,
    clutch_2pm = clutch_fgm - clutch_3pfgm,

    non_clutch_2pa = non_clutch_fga - non_clutch_3pa,
    non_clutch_2pm = non_clutch_fgm - non_clutch_3pfgm,

    .groups = "drop"
  ) |>
  filter(clutch_fga > 0, non_clutch_fga > 0) |>
  mutate(
    # CHANGED: Replace traditional FG% with eFG%.
    #
    # eFG% = (FGM + 0.5 * 3PFGM) / FGA
    #
    # The additional 0.5 accounts for the extra point
    # awarded for a made three-pointer.

    clutch_efg_pct = (
      clutch_fgm + 0.5 * clutch_3pfgm
    ) / clutch_fga,

    non_clutch_efg_pct = (
      non_clutch_fgm + 0.5 * non_clutch_3pfgm
    ) / non_clutch_fga,

    # CHANGED: Compare clutch and non-clutch eFG%.
    efg_pct_difference = clutch_efg_pct - non_clutch_efg_pct
  ) |>
  arrange(desc(clutch_fga))

processed_dir <- file.path("data", "processed")
figures_dir <- "figures"
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, showWarnings = FALSE)

# UNCHANGED: Same CSV filename, now includes eFG% metrics.
write_csv(player_summary, file.path(processed_dir, "player_shooting_summary.csv"))

plot_theme <- theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title.position = "plot"
  )

percent_labels <- scales::label_percent(accuracy = 1)

# --------------------------------------------------
# FIGURE 1: CLUTCH VS. NON-CLUTCH eFG%
# --------------------------------------------------

comparison_plot <- player_summary |>
  slice_max(clutch_fga, n = 20, with_ties = FALSE) |>

  # CHANGED: Order players by eFG% difference.
  ggplot(aes(y = reorder(player_name, efg_pct_difference))) +
  geom_segment(
    aes(
      # CHANGED: Plot eFG% instead of FG%.
      x = non_clutch_efg_pct,
      xend = clutch_efg_pct,
      yend = player_name
    ),
    color = "grey75",
    linewidth = 0.8
  ) +
  geom_point(
    # CHANGED: Non-clutch eFG%.
    aes(x = non_clutch_efg_pct, color = "Non-clutch"),
    size = 2.5
  ) +
  geom_point(
    # CHANGED: Clutch eFG%.
    aes(x = clutch_efg_pct, color = "Clutch"),
    size = 2.5
  ) +
  scale_color_manual(
    values = c("Clutch" = "#B22222", "Non-clutch" = "#315A7D"),
    name = NULL
  ) +
  scale_x_continuous(labels = percent_labels) +
  labs(
    # CHANGED: Titles and axis labels specify eFG%.
    title = "Clutch and non-clutch effective field-goal percentage",
    subtitle = "Twenty players with the most clutch field-goal attempts",
    x = "Effective field-goal percentage (eFG%)",
    y = NULL
  ) +
  plot_theme +
  theme(
    legend.position = "top",
    panel.grid.major.y = element_blank()
  )

# --------------------------------------------------
# FIGURE 2: eFG% DIFFERENCE VS. CLUTCH ATTEMPTS
# --------------------------------------------------

attempt_plot <- ggplot(
  player_summary,

  # CHANGED: Use eFG% difference on the y-axis.
  aes(x = clutch_fga, y = efg_pct_difference)
) +
  geom_hline(yintercept = 0, color = "grey40", linewidth = 0.6) +
  geom_point(color = "#315A7D", alpha = 0.6, size = 1.8) +
  scale_y_continuous(labels = percent_labels) +
  labs(
    # CHANGED: Labels describe eFG% rather than FG%.
    title = "Observed eFG% difference and clutch attempts",
    subtitle = "Players with both clutch and non-clutch attempts",
    x = "Clutch field-goal attempts",
    y = "Clutch eFG% minus non-clutch eFG%"
  ) +
  plot_theme

# UNCHANGED: Preserve existing filenames so proposal.qmd
# and other references to the figures continue working.
# The figures now show eFG% instead of traditional FG%.

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

message("Saved the player eFG% summary and two figures.")
