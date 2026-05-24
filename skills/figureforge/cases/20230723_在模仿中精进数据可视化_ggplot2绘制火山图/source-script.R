# load R Package
library(tidyverse)
library(ggrepel)
library(ggfun)

# load Data
DEG <- read_delim(file = "DEG_log2FoldChange.csv", delim = ",")
  
# Up and Down
DEG %>%
  dplyr::mutate(Change = case_when(
    log2FoldChange1 > 0.25 & log2FoldChange2 > 0.25 ~ "Up",
    log2FoldChange1 < -0.25 & log2FoldChange2 < -0.25 ~ "Down",
    .default = "Normal"
  )) %>%
  dplyr::mutate(value = 0.5*(log2FoldChange1 + log2FoldChange2)) -> DEG_2
  
table(DEG_2$Change)

p_2 <- ggplot(data = DEG_2) + 
  geom_hline(yintercept = 0, linetype = "dashed") + 
  geom_vline(xintercept = 0, linetype = "dashed") + 
  geom_point(aes(x = log2FoldChange1, y = log2FoldChange2, color = Change)) + 
  scale_color_manual(values = c("Down" = "#92c5de", "Up" = "#f4a582", "Normal" = "#bababa")) + 
  geom_density_2d(data = DEG_2 %>% dplyr::filter(Change == "Normal"),
                  aes(x = log2FoldChange1, y = log2FoldChange2),
                  color = "black") + 
  geom_text_repel(data = DEG_2 %>% dplyr::filter(Change == "Up") %>% 
                    dplyr::arrange(desc(log2FoldChange1),desc(log2FoldChange2)) %>% head(20),
                  aes(x = log2FoldChange1, y = log2FoldChange2, label = Gene),
                  color = "#d6604d",
                  nudge_x = .15,
                  box.padding = 0.5,
                  nudge_y = 0.15,
                  segment.curvature = -0.1,
                  segment.ncp = 3,
                  segment.angle = 20) + 
  geom_text_repel(data = DEG_2 %>% dplyr::filter(Change == "Down") %>% 
                    dplyr::arrange(log2FoldChange1,log2FoldChange2) %>% head(20),
                  aes(x = log2FoldChange1, y = log2FoldChange2, label = Gene),
                  color = "#4393c3",
                  nudge_x = .15,
                  box.padding = 0.5,
                  nudge_y = 0.15,
                  segment.curvature = -0.1,
                  segment.ncp = 3,
                  segment.angle = 20) + 
  ylim(c(-2, 4)) + 
  xlim(c(-2, 2)) + 
  theme_bw() + 
  theme(legend.background = element_roundrect(color = "#808080", linetype = 1),
        legend.position = c(0.1, 0.8))

p_2

ggsave(filename = "figure.pdf",
       plot = p_2,
       height = 6,
       width = 8)  

