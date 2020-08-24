library(data.table)
library(ggplot2)

source("code/set_my_theme.R")

gender_coefs <- data.table(
    gender = c("Men", "Women"),
    wave = c(rep("wave 1-2", 4), rep("wave 2-4", 4), rep("wave 1-4", 4)),
    method = c("2SLS", "2SLS", "OLS", "OLS"),
    score = c(rep("TWR", 12), rep("numeracy", 12), rep("fluency", 12)),
    beta = c(-0.021, -0.021, -0.026, -0.003, -0.048, -0.040, -0.010, -0.015, -0.033, -0.047, -0.016, -0.016, -0.029, -0.030, -0.012, -0.012, -0.006, -0.004, -0.006, -0.001, -0.013, -0.005, -0.014, -0.004, -0.037, -0.047, 0.001, -0.007, -0.032, -0.032, 0.004, -0.000, -0.037, -0.047, 0.001, -0.007),
    se = c(0.017, 0.020, 0.016, 0.020, 0.011, 0.012, 0.011, 0.013, 0.0081, 0.0090, 0.0087, 0.0100, 0.017, 0.020, 0.017, 0.019, 0.0029, 0.0027, 0.0029, 0.0029, 0.0075, 0.0079, 0.0081, 0.0088, 0.0074, 0.0081, 0.0080, 0.009, 0.0099, 0.011, 0.0099, 0.011, 0.0074, 0.0081, 0.0080, 0.0090)
)

all_coefs <- data.table(
    gender = "All",
    wave = c(rep("wave 1-2", 6), rep("wave 2-4", 6), rep("wave 1-4", 6)),
    method = c(rep("2SLS", 3), rep("OLS", 3)),
    score = c("TWR", "numeracy", "fluency"),
    beta = c(-0.017, -0.028, -0.026,- 0.015, -0.012, -0.003, -0.045, -0.005, -0.031,- 0.012, -0.004, 0.002, -0.040, -0.008, -0.041,- 0.016, -0.010, -0.003),
    se = c(0.013, 0.013, 0.012, 0.013, 0.013, 0.011, 0.0081, 0.0020, 0.0073, 0.0082, 0.0021, 0.0075, 0.0060, 0.0055, 0.0055, 0.0065, 0.0059, 0.0060)
)

coefs <- rbind(gender_coefs, all_coefs) %>%
    .[, score := ordered(score, labels = c("TWR", "numeracy", "fluency"))]

ggplot(coefs, aes(x = wave, y = beta, color = gender)) +
    geom_hline(yintercept = 0, size = 0.2) +
    geom_point(position = position_dodge(width = 0.5)) +
    geom_linerange(aes(ymin = beta - 1.96 * se, ymax = beta + 1.96 * se), position = position_dodge(width = 0.5)) +
    scale_color_manual(values = c(THIRD_COLOR, MAIN_COLOR, SECONDARY_COLOR)) +
    facet_grid(method ~ score) +
    labs(x = "Period", y = "Estimate") +
    theme(legend.position = "bottom")
ggsave("results/my_coeffs_by_gender.eps", width = 8, height = 6, scale = 0.85)
