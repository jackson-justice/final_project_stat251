# STAT 251 Final Project: NBA Clutch Shooting

Project by Joe Asay, Brian Taylor, and Jackson Justice.

We compare each NBA player's field-goal percentage in clutch and non-clutch situations during the 2025-26 regular season. A clutch attempt occurs in the final five minutes of the fourth quarter or overtime when the score margin is five points or fewer.

## Final proposal

- `proposal.pdf`: finished two-page proposal
- `proposal.qmd`: editable Quarto source
- `final_project_details.pdf`: assignment instructions

The proposal does not display R code. The analysis scripts are kept separately so the results can be reproduced.

## Getting started

You need Git, R, and either RStudio, Positron, or another editor. The code does not depend on a particular IDE.

Because all three group members are repository collaborators, clone the shared repository instead of creating forks:

```bash
git clone https://github.com/jackson-justice/final_project_stat251.git
cd final_project_stat251
```

Open the cloned folder in Positron, or open `stat251-clutch.Rproj` in RStudio. From the R console, install the two packages once:

```r
install.packages(c("hoopR", "tidyverse"))
```

Run the complete analysis from the project root in the R console inside RStudio or Positron:

```r
source("R/run_all.R")
```

If `Rscript` is available in your terminal, the equivalent PowerShell or terminal command is:

```powershell
Rscript .\R\run_all.R
```

`source()` is an R command and will not work directly at a PowerShell `PS>` prompt.

The first run downloads the NBA data and may take a few minutes. Later runs reuse the downloaded files. The scripts create `data/raw`, `data/processed`, and the two figures automatically.

To rebuild the proposal PDF, install Quarto and run this command in a terminal:

```bash
quarto render proposal.qmd
```

## What each script does

1. `R/acquire_data.R` downloads and caches the play-by-play and schedule.
2. `R/clean_data.R` keeps regular-season field goals and marks clutch attempts.
3. `R/eda.R` creates the player summary and proposal figures.
4. `R/run_all.R` runs those three scripts in order.

Generated data files are ignored by Git because they are large and can be recreated. The figures and proposal PDF should be committed when they change.

## GitHub workflow for the group

Use a separate branch for each task. Before starting new work:

```bash
git switch main
git pull
git switch -c your-name-short-task
```

Examples are `jackson-update-proposal`, `joe-check-data`, or `brian-add-analysis`.

After making and testing a change:

```bash
git add .
git commit -m "Describe the change"
git push -u origin your-name-short-task
```

Open a pull request on GitHub from the branch into `main`. For analysis changes or changes to reported results, ask one teammate to review before merging. For a tiny typo or formatting fix, the group can agree that the author may merge it without a review. GitHub only requires a review if branch-protection rules are configured.

After the pull request is merged:

```bash
git switch main
git pull
git branch -d your-name-short-task
```

A few habits prevent most problems:

- Pull `main` before creating a new branch.
- Avoid having two people edit the same file at the same time.
- Do not commit files inside `data/raw` or `data/processed`.
- Keep `main` in a working state; use branches for unfinished work.
- Write short commit messages that explain what changed.

A teammate who prefers a graphical interface can follow the same workflow with GitHub Desktop while using either RStudio or Positron for the R code.

## Project layout

```text
final_project_stat251/
|-- R/
|   |-- acquire_data.R
|   |-- clean_data.R
|   |-- eda.R
|   `-- run_all.R
|-- data/                 # generated data; not committed
|-- figures/              # figures used by the proposal
|-- proposal.qmd
|-- proposal.pdf
|-- final_project_details.pdf
|-- README.md
`-- stat251-clutch.Rproj
```

## Data source

The scripts use the R package [`hoopR`](https://hoopr.sportsdataverse.org/) to retrieve NBA.com data.
