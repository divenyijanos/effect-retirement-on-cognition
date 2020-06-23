library(readstata13)
library(data.table)
library(magrittr)
library(ggplot2)

MAIN_COLOR <- "#042037"
mytheme <- function (base_size = 11, base_family = "", base_line_size = base_size/22,
    base_rect_size = base_size/22) {
    theme_minimal(base_size = base_size, base_family = base_family,
        base_line_size = base_line_size, base_rect_size = base_rect_size) %+replace%
        theme(
            panel.border = element_rect(fill = NA, colour = "grey20"),
            panel.grid = element_line(colour = "grey92"),
            panel.grid.minor = element_line(size = rel(0.5))
        )
}
theme_set(mytheme())

data <- read.dta13("data/derived.dta") %>% as.data.table()

relevant_data <- data[
    wave == 1 & age1 >= 50 & age1 <= 70 & jobsit1 <= 3 & worked_at50 == 1,
    .(twr_sd = (twr - mean(twr, na.rm = TRUE)) / sd(twr, na.rm = TRUE), yrs_in_ret, age, female),
    countrycode
]

coefs_by_country <- lapply(relevant_data[, unique(countrycode)], function(c) {
    reg <- lm(twr_sd ~ yrs_in_ret + age + female, data = relevant_data[countrycode == c])
    data.table(
        countrycode = c,
        beta = reg$coefficients[["yrs_in_ret"]],
        se = sqrt(diag(vcov(reg)))[["yrs_in_ret"]]
    )
}) %>% rbindlist()

ggplot(coefs_by_country, aes(x = countrycode)) +
    geom_pointrange(aes(y = beta, ymin = beta - 2*se, ymax = beta + 2*se), color = MAIN_COLOR) +
    geom_hline(yintercept = 0, color = "grey20") +
    labs(x = "", y = "")
ggsave("results/country_coefs_R.eps", width = 8, height = 4, scale = 0.85)
