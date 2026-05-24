rm(list = ls())

####----load R Package----####
library(tidyverse)
library(patchwork)
library(ggnewscale)


####----load Data----####
data("mtcars")

####----完整的相关性热图----####
corda <- data.frame(cor(mtcars))
corda
# 直接对角线设置为NA
diag(corda) <- NA

corda$ID <- rownames(corda)

df_1 <- corda %>%
  tidyr::pivot_longer(cols = -ID,
                      names_to = "Type", 
                      values_to = "Value")

df_1$ID <- factor(df_1$ID,levels = unique(df_1$ID))
df_1$Type <- factor(df_1$Type,levels = unique(df_1$ID))


p_all <- ggplot(df_1) + 
  geom_tile(data = df_1,
            mapping = aes(x = ID, y = Type), 
            fill = "white", color = "gray60", linewidth = 1) + 
  geom_point(data = df_1,
             mapping = aes(x = ID, y = Type, fill = Value, size = Value), 
             show.legend = F, shape = 21, color = "black") +
  geom_abline(slope = 1, intercept = 0, linewidth = 1) + 
  scale_fill_gradient(low = "#edf8b1", high = "#1d91c0") + 
  theme_minimal() +
  theme(
    panel.grid = element_blank(),
    aspect.ratio = 1,
    axis.text = element_text(color = "black", size = 20),
    axis.text.x = element_text(angle=45, hjust=0),
    plot.margin = margin(t = 1, r = 1, b = 1, l = 1, unit = "cm")
  ) +
  scale_x_discrete(position = "top") + 
  scale_size(range = c(7,14)) + 
  xlab('') + ylab('') 

p_all

ggsave(filename = "p_all.pdf",
       plot = p_all,
       height = 10,
       width = 10)

####----上斜三角----####
corda <- data.frame(cor(mtcars))
corda
# 直接对角线设置为NA
# diag(corda) <- NA

corda[lower.tri(corda)] <- NA

corda$ID <- rownames(corda)

df_upper <- corda %>%
  tidyr::pivot_longer(cols = -ID,
                      names_to = "Type", 
                      values_to = "Value") %>%
  na.omit()

df_upper$ID <- factor(df_upper$ID,levels = unique(rownames(corda)))
df_upper$Type <- factor(df_upper$Type,levels = unique(rownames(corda)))


p_upper <- ggplot(df_upper) + 
  geom_tile(data = df_upper,
            mapping = aes(x = ID, y = Type), 
            fill = "white", color = "gray60", linewidth = 1) + 
  geom_point(data = df_upper,
             mapping = aes(x = ID, y = Type, fill = Value, size = Value), 
             show.legend = F, shape = 21, color = "black") +
  geom_abline(slope = 1, intercept = 0, linewidth = 1) + 
  scale_fill_gradient(low = "#edf8b1", high = "#1d91c0") + 
  theme_minimal() +
  theme(
    panel.grid = element_blank(),
    aspect.ratio = 1,
    axis.text = element_text(color = "black", size = 20),
    axis.text.x = element_text(angle=45, hjust=0),
    # axis.text.y = element_text(angle = 45, hjust = 1),
    plot.margin = margin(t = 1, r = 1, b = 1, l = 1, unit = "cm")
  ) +
  scale_x_discrete(position = "top") + 
  scale_size(range = c(7,14)) + 
  xlab('') + ylab('') 

p_upper

ggsave(filename = "p_upper.pdf",
       plot = p_upper,
       height = 10,
       width = 10)

####----下斜三角----####
corda <- data.frame(cor(mtcars))
corda
# 直接对角线设置为NA
# diag(corda) <- NA

corda[upper.tri(corda)] <- NA

corda$ID <- rownames(corda)

df_lower <- corda %>%
  tidyr::pivot_longer(cols = -ID,
                      names_to = "Type", 
                      values_to = "Value") %>%
  na.omit()

df_lower$ID <- factor(df_lower$ID,levels = unique(rownames(corda)))
df_lower$Type <- factor(df_lower$Type,levels = unique(rownames(corda)))


p_lower <- ggplot(df_lower) + 
  geom_tile(data = df_lower,
            mapping = aes(x = ID, y = Type), 
            fill = "white", color = "gray60", linewidth = 1) + 
  geom_point(data = df_lower,
             mapping = aes(x = ID, y = Type, fill = Value, size = Value), 
             show.legend = F, shape = 21, color = "black") +
  geom_abline(slope = 1, intercept = 0, linewidth = 1) + 
  scale_fill_gradient(low = "#edf8b1", high = "#1d91c0") + 
  theme_minimal() +
  theme(
    panel.grid = element_blank(),
    aspect.ratio = 1,
    axis.text = element_text(color = "black", size = 20),
    axis.text.x = element_text(angle=45, hjust=1),
    # axis.text.y = element_text(angle = 45, hjust = 1),
    plot.margin = margin(t = 1, r = 1, b = 1, l = 1, unit = "cm")
  ) +
  scale_y_discrete(position = "right") + 
  scale_size(range = c(7,14)) + 
  xlab('') + ylab('') 

p_lower

ggsave(filename = "p_lower.pdf",
       plot = p_lower,
       height = 10,
       width = 10)

####----两个三角不同映射----####
dim(df_lower)
dim(df_upper)

p_diff_color <- ggplot(data = df_1) + 
  geom_tile(aes(x = ID, y = Type),
            fill = "white", color = "gray60", linewidth = 1) + 
  geom_point(data = df_lower %>% dplyr::filter(ID != Type),
             mapping = aes(x = ID, y = Type, fill = Value, size = Value),
             show.legend = F, shape = 21, color = "black") + 
  scale_fill_gradient(low = "#bfd3e6", high = "#88419d") + 
  new_scale_fill() + 
  geom_point(data = df_upper %>% dplyr::filter(ID != Type),
             mapping = aes(x = ID, y = Type, fill = Value, size = Value),
             show.legend = F, shape = 21, color = "black") + 
  scale_fill_gradient(low = "#ccebc5", high = "#2b8cbe") + 
  geom_abline(slope = 1, intercept = 0, linewidth = 1) + 
  theme_minimal() + 
  theme(
    panel.grid = element_blank(),
    aspect.ratio = 1,
    axis.text = element_text(color = "black", size = 20),
    plot.margin = margin(t = 1, r = 1, b = 1, l = 1, unit = "cm")
  ) + 
  scale_size(range = c(7,14)) + 
  xlab('') + ylab('')

p_diff_color 

ggsave(filename = "p_diff_color.pdf",
       plot = p_diff_color,
       height = 10,
       width = 10)


p_diff_color2 <- ggplot(data = df_1) + 
  geom_tile(aes(x = ID, y = Type),
            fill = "white", color = NA, linewidth = NA) + 
  geom_tile(data = df_lower %>% dplyr::filter(ID != Type),
             mapping = aes(x = ID, y = Type, fill = Value),
             show.legend = F, color = "black") + 
  scale_fill_gradient(low = "#bfd3e6", high = "#88419d") + 
  new_scale_fill() + 
  geom_tile(data = df_upper %>% dplyr::filter(ID != Type),
             mapping = aes(x = ID, y = Type, fill = Value),
             show.legend = F, color = "black") + 
  scale_fill_gradient(low = "#ccebc5", high = "#2b8cbe") + 
  # geom_abline(slope = 1, intercept = 0, linewidth = 1) + 
  theme_minimal() + 
  theme(
    panel.grid = element_blank(),
    aspect.ratio = 1,
    axis.text = element_text(color = "black", size = 20),
    plot.margin = margin(t = 1, r = 1, b = 1, l = 1, unit = "cm")
  ) + 
  scale_size(range = c(7,14)) + 
  xlab('') + ylab('')

p_diff_color2 

ggsave(filename = "p_diff_color2.pdf",
       plot = p_diff_color2,
       height = 10,
       width = 10)


####----combine----####
p_all + 
p_upper + 
p_lower + 
p_diff_color + 
p_diff_color2 + 
  plot_layout(nrow = 2) + 
  plot_annotation(tag_levels = "A") & 
  theme(plot.tag = element_text(size = 30))

ggsave(filename = "p_combine.pdf",
       height = 28,
       width = 28)


####----sessionInfo----####
sessionInfo()



