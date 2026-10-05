# 04_figures.R
# Purpose: read the two small CSVs that Stata exported and turn them into two PDF figures.
# Libraries and Setup
library(ggplot2)
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

# --- Figure 1: observed group averages over time ---

did <- read.csv("output/plot_data/did_trends.csv")
did$group <- factor(did$treated, levels = c(0, 1),
                    labels = c("Never treated", "Reform districts"))

# Plot
p_did <- ggplot(did, aes(x = year, y = mean_delay, color = group)) +
  geom_vline(xintercept = 2018.5, linetype = "dashed", color = "grey55") +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  scale_color_manual(values = c("#555555", "#2166AC")) +
  scale_x_continuous(breaks = 2015:2022) +
  labs(x = "Year", y = "Mean delay (days)", color = NULL,
       caption = "Synthetic data. Reform begins in 2019; observed outcomes only.") +
  theme_classic(base_size = 11) +
  theme(legend.position = "bottom")

# Save the DiD figure
ggsave("output/figures/did.pdf", plot = p_did,
       width = 6.2, height = 3.5, units = "in")

# --- Figure 2: binned means and fitted lines from the Stata RD regression ---

rd <- read.csv("output/plot_data/rd_bins.csv")
rd$group <- factor(rd$eligible, levels = c(0, 1),
                  labels = c("Below cutoff", "Eligible"))

# Plot
p_rd <- ggplot(rd, aes(x = score, color = group)) +
  geom_vline(xintercept = 50, linetype = "dashed", color = "grey55") +
  geom_point(aes(y = duration_days), size = 2) +
  geom_line(aes(y = fitted_duration, group = group), linewidth = 0.8) +
  scale_color_manual(values = c("#555555", "#2166AC")) +
  labs(x = "Priority score", y = "Case duration (days)", color = NULL,
       caption = "Synthetic data. Two-point bins; separate local linear fits.") +
  theme_classic(base_size = 11) +
  theme(legend.position = "bottom")

# Save the RD figure
ggsave("output/figures/rd.pdf", plot = p_rd,
       width = 6.2, height = 3.5, units = "in")
