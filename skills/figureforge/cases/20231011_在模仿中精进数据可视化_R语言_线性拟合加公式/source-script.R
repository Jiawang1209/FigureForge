####----load R Package----####
library(tidyverse)
library(ggfun)
library(ggpmisc)
library(broom)
library(ggpubr)

set.seed(1115)
####----load Data----####
data("diamonds")

# random sampling 
data <- diamonds %>% sample_n(1500)

####----Plot----####

# linear fitting
# set formula
formula <- y ~ x

plot_linearfitting <- ggplot(data = data, aes(x = carat, y = price, group = cut, color = cut)) + 
  geom_point(aes(fill = cut, shape = cut), size = 4, color = "#000000", alpha = 0.7) + 
  geom_smooth(aes(color = cut), method = "lm", formula = formula, se = F) +
  stat_poly_eq(use_label(c("eq", "adj.R2", "P")),formula = formula, size = 4) +
  # stat_poly_eq(aes(label = ..eq.label.., color = cut), formula = formula, size = 4) + 
  scale_shape_manual(values = 21:25) + 
  scale_fill_manual(values = c("Fair" = "#7fc97f",
                               "Good" = "#beaed4",
                               "Very Good" = "#fdc086",
                               "Premium" = "#fb9a99",
                               "Ideal" = "#386cb0")) + 
  scale_color_manual(values = c("Fair" = "#7fc97f",
                                "Good" = "#beaed4",
                                "Very Good" = "#fdc086",
                                "Premium" = "#fb9a99",
                                "Ideal" = "#386cb0")) + 
  ggtitle(label = "linear fitting",
          subtitle = "linear fitting") + 
  theme_bw() + 
  theme(panel.grid = element_blank(),
        legend.background = element_roundrect(color = "#808080", linetype = 1),
        axis.text = element_text(size = 13, color = "#000000"),
        axis.title = element_text(size = 15),
        plot.title = element_text(hjust = 0.5, size = 20),
        plot.subtitle = element_text(hjust = 0.5, size = 15),
        legend.text = element_text(size = 10),
        legend.title = element_text(size = 15)
  )

plot_linearfitting


# correlation
plot_correlation <- ggplot(data = data, aes(x = carat, y = price, group = cut, color = cut)) + 
  geom_point(aes(fill = cut, shape = cut), size = 4, color = "#000000", alpha = 0.7) + 
  geom_smooth(aes(color = cut), method = "lm", formula = formula, se = F) +
  stat_cor(method = "pearson",parse = TRUE,size=4) + 
  scale_shape_manual(values = 21:25) + 
  scale_fill_manual(values = c("Fair" = "#7fc97f",
                               "Good" = "#beaed4",
                               "Very Good" = "#fdc086",
                               "Premium" = "#fb9a99",
                               "Ideal" = "#386cb0")) + 
  scale_color_manual(values = c("Fair" = "#7fc97f",
                                "Good" = "#beaed4",
                                "Very Good" = "#fdc086",
                                "Premium" = "#fb9a99",
                                "Ideal" = "#386cb0")) + 
  ggtitle(label = "Correlation",
          subtitle = "Correlation") + 
  theme_bw() + 
  theme(panel.grid = element_blank(),
        legend.background = element_roundrect(color = "#808080", linetype = 1),
        axis.text = element_text(size = 13, color = "#000000"),
        axis.title = element_text(size = 15),
        plot.title = element_text(hjust = 0.5, size = 20),
        plot.subtitle = element_text(hjust = 0.5, size = 15),
        legend.text = element_text(size = 10),
        legend.title = element_text(size = 15)
  )

plot_correlation

# correlation  linear fitting
plot_correlation_linearfitting <- ggplot(data = data, aes(x = carat, y = price, group = cut, color = cut)) + 
  geom_point(aes(fill = cut, shape = cut), size = 4, color = "#000000", alpha = 0.7) + 
  geom_smooth(aes(color = cut), method = "lm", formula = formula, se = F) +
  stat_cor(method = "pearson",parse = TRUE,size=4) + 
  stat_poly_eq(use_label(c("eq", "adj.R2", "P")),formula = formula, size = 4) +
  scale_shape_manual(values = 21:25) + 
  scale_fill_manual(values = c("Fair" = "#7fc97f",
                               "Good" = "#beaed4",
                               "Very Good" = "#fdc086",
                               "Premium" = "#fb9a99",
                               "Ideal" = "#386cb0")) + 
  scale_color_manual(values = c("Fair" = "#7fc97f",
                                "Good" = "#beaed4",
                                "Very Good" = "#fdc086",
                                "Premium" = "#fb9a99",
                                "Ideal" = "#386cb0")) + 
  ggtitle(label = "Correlation and linear fitting ",
          subtitle = "Correlation and linear fitting") + 
  theme_bw() + 
  theme(panel.grid = element_blank(),
        legend.background = element_roundrect(color = "#808080", linetype = 1),
        axis.text = element_text(size = 13, color = "#000000"),
        axis.title = element_text(size = 15),
        plot.title = element_text(hjust = 0.5, size = 20),
        plot.subtitle = element_text(hjust = 0.5, size = 15),
        legend.text = element_text(size = 10),
        legend.title = element_text(size = 15)
  ) + 
  facet_wrap(~cut)

plot_correlation_linearfitting

####----Save Result----####
purrr::map(ls(pattern = "plot_"),
           function(x){
             ggsave(filename = paste(x, ".pdf"),
                    plot = get(x), height = 7, width = 8)
           })


####----Session Info----####
sessionInfo()
