MAIN_COLOR <- "#042037"
SECONDARY_COLOR <- "#D4A86A"
THIRD_COLOR <- "#3F88C5"

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
