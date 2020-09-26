library(readstata13)
library(data.table)
library(magrittr)
library(ggplot2)

source("code/set_my_theme.R")

data <- read.dta13("data/derived.dta") %>% as.data.table()

relevant_data <- data[
    age1 >= 50 & age1 <= 70 & jobsit1 <= 3 & worked_at50 == 1 &
    wavepart == 124 & hist >= 100 & hist != 101
]

relevant_data[,
    .(twr = mean(twr, na.rm = TRUE)),
    .(country, wave, hist)
] %>%
    ggplot(aes(wave, twr, color = factor(hist))) +
    geom_line() +
    geom_point() +
    scale_color_manual(
        values = c(MAIN_COLOR, SECONDARY_COLOR, THIRD_COLOR),
        guide = guide_legend(title = "Working history")
    ) +
    scale_x_continuous(breaks = c(1, 2, 4), minor_breaks = NULL) +
    facet_wrap(~ country) +
    labs(y = "Mean score on total word recall") +
    theme(legend.position = c(.85, 0.25), legend.justification = c("right", "top"))
ggsave("results/twr_hist_waves_R.eps", width = 8, height = 4, scale = 0.85)
