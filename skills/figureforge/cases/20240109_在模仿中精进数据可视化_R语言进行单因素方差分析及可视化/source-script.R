####----load R Package----####
library(tidyverse)
library(agricolae)
library(broom)
library(car)
library(ggfun)
library(agricolae)

####----load R Data----####

# Numeric data
data_1 <- read.csv(file = "Example_data.csv")

# group info
group_df <- read.csv(file = "Example_group.csv")


####----Statistical Asnalysis----####

# 正态性检验
# 然后把方差齐的结果导出来 (表格形式)

shapiro.test_out <- data.frame()

for (var in colnames(data_1)) {
  shapiro.test_out <- rbind(shapiro.test_out, 
                            broom::tidy(shapiro.test(data_1[[var]])) %>% dplyr::mutate(group = var)
                            )
}

shapiro.test_out

write.csv(shapiro.test_out,
          file = "shapiro.test_out.csv",
          quote = F)

# 然后把方差齐的结果导出来 (图片形式)
data_1 %>%
  tidyr::pivot_longer(cols = contains("Group"),
                      names_to = "Group",
                      values_to = "Value") %>%
  dplyr::mutate(Group2 = str_split(Group, pattern = "_", simplify = T)[,1]) %>%
  ggplot(aes(sample = Value, color = Group2, group = Group2)) + 
  stat_qq() + 
  stat_qq_line() + 
  facet_wrap(~Group2, scales = "free") + 
  theme_bw()

ggsave(filename = "shapiro.test_out.pdf",
       height = 7.5,
       width = 10)


# wide to long
df_long <- data_1 %>%
  tidyr::pivot_longer(cols = contains("Group"),
                      names_to = "Group",
                      values_to = "Value") %>%
  dplyr::mutate(Group2 = str_split(Group, pattern = "_", simplify = T)[,1])

# 方差齐性检验
leveneTest(Value ~ Group2, data = df_long)

broom::tidy(leveneTest(Value ~ Group2, data = df_long))

bartlett.test(Value ~ Group2, data = df_long)

broom::tidy(bartlett.test(Value ~ Group2, data = df_long))

# 单因素方差分析
aov_out <- aov(Value ~ Group2, data = df_long)
summary(aov_out)

broom::tidy(aov_out)

model.tables(aov_out, "means")

# 多重比较
TukeyHSD(aov_out)

# 字母标记法
aov_out_letters <- LSD.test(aov_out, "Group2", p.adj = "bonferroni")
aov_out_letters2 <- duncan.test(aov_out, "Group2")

# 获得字母标记法的结果
aov_out_letters$groups



####----Plot and Save----####
df_long %>%
  dplyr::arrange(Value, Group2) %>%
  dplyr::left_join(group_df, by=c("Group2" = "Group")) %>%
  dplyr::mutate(Group2 = factor(Group2, levels = group_df$Group, ordered = T)) %>%
  ggplot(aes(x = Group2, y = Value)) +
  geom_point(aes(color = Info), stat = "summary", fun = "mean", size = 3) + 
  stat_summary(fun.data = "mean_se", geom="errorbar", width = 0.25, color = "black") + 
  annotate(geom = "rect", xmin = -Inf, xmax = 4.5, ymin = -Inf, ymax = Inf, fill = "#969696", alpha = 0.5) +
  annotate(geom = "rect", xmin = 4.5, xmax = 8.5, ymin = -Inf, ymax = Inf, fill = "#ffffff", alpha = 0.5) +
  annotate(geom = "rect", xmin = 8.5, xmax = Inf, ymin = -Inf, ymax = Inf, fill = "#969696", alpha = 0.5) + 
  annotate(geom = "text", x = 2.5, y = 35, label = "V.splendidus", color = "#4daf4a", size = 6, fontface = 'italic') + 
  annotate(geom = "text", x = 6.5, y = 35, label = "V.cyclitrophicus", color = "#984ea3", size = 6, fontface = 'italic') + 
  annotate(geom = "text", x = 10.5, y = 35, label = "V.sp.", color = "#377eb8", size = 6, fontface = 'italic') + 
  stat_summary(fun.data = "mean_se", geom="errorbar", width = 0.25, color = "black") + 
  geom_point(aes(color = Info), stat = "summary", fun = "mean", size = 3) + 
  scale_colour_manual(values = c("V.sp." = "#377eb8", "V.cyclitrophicus" = "#984ea3",  "V.splendidus" = "#4daf4a")) + 
  geom_text(data = aov_out_letters$groups %>% as.data.frame() %>% rownames_to_column(var = "Group2"),
            aes(x = Group2, y = Value + 1, label = groups), size = 5) + 
  theme_classic() + 
  theme(axis.text.x = element_text(size = 15, angle = 45, hjust = 1, color = "#000000"),
        axis.text.y = element_text(size = 15, color = "#000000"),
        axis.title = element_text(size = 15, color = "#000000"),
        legend.title = element_text(size = 15, color = "#000000"),
        legend.text = element_text(size = 10),
        legend.background = element_roundrect(color = "#000000", linetype = 1))

ggsave(filename = "One-way_ANOVA.pdf",
       height = 6,
       width = 8.5)
  

  



