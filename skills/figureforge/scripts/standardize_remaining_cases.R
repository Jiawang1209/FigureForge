#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
cases_dir <- if (length(args) >= 1) args[[1]] else "skills/figureforge/cases"
status_path <- if (length(args) >= 2) args[[2]] else "skills/figureforge/references/case-status.csv"

if (!dir.exists(cases_dir)) {
  stop("Cases directory not found: ", cases_dir)
}

case_dirs <- sort(list.dirs(cases_dir, full.names = TRUE, recursive = FALSE))
case_dirs <- case_dirs[basename(case_dirs) != "_template"]

sanitize_text <- function(x) {
  x <- gsub("[\r\n]+", " ", x)
  x <- gsub("\\s+", " ", x)
  trimws(x)
}

title_from_id <- function(case_id) {
  readable <- gsub("_", " ", case_id)
  readable <- gsub("-", " ", readable)
  paste("Case", sub("_.*$", "", case_id), ":", readable)
}

detect_kind <- function(case_id) {
  text <- tolower(case_id)
  has <- function(pattern) grepl(pattern, text, perl = TRUE)
  if (has("ggtree|进化树|tree|phylo")) return("tree")
  if (has("网络|ppi|network|cytoscape|gephi|互作")) return("network")
  if (has("circos|圈图|环状|圆形|甜甜圈|饼图|扇形|donut|pie")) return("polar")
  if (has("热图|heatmap|相关|corr|mantel|聚类")) return("heatmap")
  if (has("火山|volcano")) return("volcano")
  if (has("pca|pcoa|nmds|排序|ordination")) return("ordination")
  if (has("go|kegg|富集|气泡|bubble")) return("bubble")
  if (has("箱|小提琴|云雨|anova|方差|显著性|差异|violin|box")) return("box")
  if (has("时序|折线|双y|line|timeline")) return("line")
  if (has("地图|世界|采样|map")) return("map")
  if (has("桑基|河流|sankey|river")) return("flow")
  if (has("柱|bar|棒棒糖|lollipop")) return("bar")
  if (has("组合|拼图|table|表格|分面|facet")) return("facet")
  "scatter"
}

kind_metadata <- function(kind) {
  switch(
    kind,
    tree = list(
      chart_type = "tree-style layout",
      chart_type_zh = "树形结构图",
      aliases = "tree plot, phylogenetic-style layout, dendrogram, 进化树, 树形图, 层级结构图",
      best_for = "Showing hierarchical relationships or branch-like structure with optional categorical annotation.",
      best_for_zh = "适合展示层级关系、进化树式分支结构，以及末端对象的分类注释。"
    ),
    network = list(
      chart_type = "network plot",
      chart_type_zh = "网络图",
      aliases = "network, graph, edge-node plot, PPI network, 网络图, 互作网络, 节点连线图",
      best_for = "Showing relationships among entities as nodes and edges, with node size or color encoding attributes.",
      best_for_zh = "适合展示实体之间的连接关系，并用节点大小或颜色表达属性。"
    ),
    polar = list(
      chart_type = "polar chart",
      chart_type_zh = "极坐标图 / 环形图",
      aliases = "polar bar, donut chart, pie chart, circos-like plot, 极坐标柱形图, 环形图, 圈图",
      best_for = "Showing cyclic, proportional, or circular summaries across a small to moderate number of categories.",
      best_for_zh = "适合展示类别占比、环形摘要或带有循环布局的分类数据。"
    ),
    heatmap = list(
      chart_type = "heatmap",
      chart_type_zh = "热图",
      aliases = "heatmap, correlation heatmap, tile plot, clustered heatmap, 热图, 相关性热图, 聚类热图",
      best_for = "Showing matrix-like values across rows and columns using color intensity.",
      best_for_zh = "适合用颜色强度展示行列矩阵中的数值模式。"
    ),
    volcano = list(
      chart_type = "volcano plot",
      chart_type_zh = "火山图",
      aliases = "volcano plot, differential expression scatter, fold-change plot, 火山图, 差异表达图",
      best_for = "Showing effect size and statistical significance together for differential analysis results.",
      best_for_zh = "适合同时展示差异分析中的效应量和显著性。"
    ),
    ordination = list(
      chart_type = "ordination scatter",
      chart_type_zh = "排序散点图",
      aliases = "PCA, PCoA, NMDS, ordination, dimensionality reduction, PCA图, PCoA图, NMDS图, 排序图",
      best_for = "Showing sample separation in reduced-dimensional space.",
      best_for_zh = "适合展示样本在降维空间中的分离、聚类和组间差异。"
    ),
    bubble = list(
      chart_type = "bubble plot",
      chart_type_zh = "气泡图",
      aliases = "bubble plot, enrichment bubble, GO bubble, KEGG bubble, 气泡图, 富集气泡图, GO富集, KEGG富集",
      best_for = "Showing ranked categories with size and color encoding two metrics.",
      best_for_zh = "适合展示富集条目或分类条目，并用气泡大小和颜色表达两个指标。"
    ),
    box = list(
      chart_type = "distribution comparison",
      chart_type_zh = "分布比较图",
      aliases = "boxplot, violin plot, jitter plot, significance plot, 箱线图, 小提琴图, 云雨图, 显著性图",
      best_for = "Comparing numeric distributions across groups with individual observations visible.",
      best_for_zh = "适合比较多个分组的数值分布，并显示样本点和差异趋势。"
    ),
    line = list(
      chart_type = "time series line chart",
      chart_type_zh = "时序折线图",
      aliases = "line chart, time series, confidence ribbon, longitudinal plot, 折线图, 时序图, 置信区间",
      best_for = "Showing trajectories over ordered time points or gradients.",
      best_for_zh = "适合展示多个组随时间或连续梯度变化的趋势。"
    ),
    map = list(
      chart_type = "geographic scatter",
      chart_type_zh = "地理散点图",
      aliases = "map scatter, geographic bubble, sampling map, 地图散点图, 采样点图, 地理气泡图",
      best_for = "Showing sampling locations or spatial observations using longitude and latitude.",
      best_for_zh = "适合在经纬度坐标上展示采样点或空间观测数据。"
    ),
    flow = list(
      chart_type = "flow diagram",
      chart_type_zh = "流向图 / 河流图",
      aliases = "sankey-like plot, river plot, flow diagram, 桑基图, 河流图, 流向图",
      best_for = "Showing how quantities move between ordered stages or categories.",
      best_for_zh = "适合展示数量在多个阶段或类别之间的流动关系。"
    ),
    bar = list(
      chart_type = "bar chart",
      chart_type_zh = "柱形图",
      aliases = "bar chart, grouped bar, lollipop chart, column chart, 柱形图, 分组柱形图, 棒棒糖图",
      best_for = "Comparing category-level values, optionally grouped or mirrored.",
      best_for_zh = "适合比较不同类别的数值大小，可扩展为分组、对称或棒棒糖样式。"
    ),
    facet = list(
      chart_type = "faceted composite plot",
      chart_type_zh = "分面组合图",
      aliases = "faceted plot, composite plot, multi-panel figure, 分面图, 组合图, 多面板图",
      best_for = "Showing repeated visual patterns across panels with shared encodings.",
      best_for_zh = "适合用一致的视觉编码展示多个面板或多个子任务。"
    ),
    list(
      chart_type = "scatter plot",
      chart_type_zh = "散点图",
      aliases = "scatter plot, grouped scatter, annotation scatter, 散点图, 分组散点图, 注释散点图",
      best_for = "Showing relationships between two numeric variables with grouping or labels.",
      best_for_zh = "适合展示两个数值变量之间的关系，并用颜色或标签表达分组。"
    )
  )
}

make_data <- function(kind) {
  set.seed(20240524)
  heatmap_data <- expand.grid(
    row = paste0("Feature_", seq_len(12)),
    column = paste0("Sample_", seq_len(8)),
    KEEP.OUT.ATTRS = FALSE
  )
  heatmap_data$value <- round(rnorm(nrow(heatmap_data)), 3)
  heatmap_data$group <- rep(c("A", "B"), each = nrow(heatmap_data) / 2)

  line_data <- expand.grid(
    timepoint = seq_len(8),
    group = c("Control", "Treatment_A", "Treatment_B"),
    replicate = seq_len(5),
    KEEP.OUT.ATTRS = FALSE
  )
  line_data$value <- round(
    8 + line_data$timepoint * c(0.3, 0.55, 0.8)[match(line_data$group, c("Control", "Treatment_A", "Treatment_B"))] +
      rnorm(nrow(line_data), 0, 0.6),
    3
  )

  flow_data <- expand.grid(
    stage = paste0("Stage_", seq_len(4)),
    group = paste0("Group_", seq_len(5)),
    KEEP.OUT.ATTRS = FALSE
  )
  flow_data$value <- round(runif(nrow(flow_data), 10, 80), 1)

  facet_data <- expand.grid(
    feature = paste0("Feature_", seq_len(8)),
    panel = paste0("Panel_", seq_len(4)),
    KEEP.OUT.ATTRS = FALSE
  )
  facet_data$value <- round(runif(nrow(facet_data), 0, 1), 3)
  facet_data$group <- rep(c("A", "B"), length.out = nrow(facet_data))

  switch(
    kind,
    tree = data.frame(
      node = paste0("Tip_", seq_len(18)),
      parent = rep(paste0("Clade_", seq_len(6)), each = 3),
      group = rep(c("A", "B", "C"), length.out = 18),
      value = round(runif(18, 0.2, 1), 3)
    ),
    network = data.frame(
      from = paste0("Node_", sample(1:16, 32, replace = TRUE)),
      to = paste0("Node_", sample(1:16, 32, replace = TRUE)),
      weight = round(runif(32, 0.1, 1), 3),
      group = rep(c("module_1", "module_2", "module_3", "module_4"), length.out = 32)
    ),
    polar = data.frame(
      category = paste0("Category_", seq_len(12)),
      group = rep(c("Group_A", "Group_B", "Group_C"), each = 4),
      value = round(runif(12, 5, 35), 1)
    ),
    heatmap = heatmap_data,
    volcano = data.frame(
      feature = paste0("Gene_", seq_len(120)),
      log2FoldChange = round(rnorm(120, 0, 1.6), 3),
      padj = signif(runif(120, 0.0005, 0.95), 3)
    ),
    ordination = data.frame(
      sample = paste0("Sample_", seq_len(30)),
      group = rep(c("Control", "Treatment_A", "Treatment_B"), each = 10),
      axis1 = round(c(rnorm(10, -1), rnorm(10, 0.8), rnorm(10, 1.8)), 3),
      axis2 = round(c(rnorm(10, 0.3), rnorm(10, -0.8), rnorm(10, 0.9)), 3)
    ),
    bubble = data.frame(
      term = paste0("Pathway_", seq_len(18)),
      group = rep(c("GO_BP", "GO_MF", "KEGG"), each = 6),
      score = round(runif(18, 1.5, 8), 2),
      count = sample(5:80, 18)
    ),
    box = data.frame(
      group = rep(c("Control", "Low", "Medium", "High"), each = 24),
      value = round(c(rnorm(24, 4), rnorm(24, 5.2), rnorm(24, 6.1), rnorm(24, 7.3)), 3),
      batch = rep(c("Batch_1", "Batch_2", "Batch_3"), length.out = 96)
    ),
    line = line_data,
    map = data.frame(
      site = paste0("Site_", seq_len(36)),
      longitude = round(runif(36, 73, 135), 3),
      latitude = round(runif(36, 18, 53), 3),
      value = round(runif(36, 1, 100), 2),
      group = rep(c("North", "South", "West", "East"), length.out = 36)
    ),
    flow = flow_data,
    bar = data.frame(
      category = paste0("Category_", seq_len(14)),
      group = rep(c("A", "B"), length.out = 14),
      value = round(runif(14, 5, 50), 1)
    ),
    facet = facet_data,
    data.frame(
      x = round(rnorm(80), 3),
      y = round(rnorm(80), 3),
      group = rep(c("A", "B", "C", "D"), length.out = 80),
      label = paste0("Point_", seq_len(80))
    )
  )
}

plot_template <- function(kind) {
  common <- c(
    "#!/usr/bin/env Rscript",
    "",
    "args <- commandArgs(trailingOnly = TRUE)",
    "input_path <- if (length(args) >= 1) args[[1]] else \"data.csv\"",
    "output_path <- if (length(args) >= 2) args[[2]] else \"figure.pdf\"",
    "",
    "if (!file.exists(input_path)) stop(\"Input data file not found: \", input_path)",
    "if (!requireNamespace(\"ggplot2\", quietly = TRUE)) stop(\"Missing required R package(s): ggplot2\")",
    "data <- read.csv(input_path, check.names = FALSE)",
    ""
  )
  body <- switch(
    kind,
    tree = c(
      "parents <- unique(data$parent)",
      "parent_pos <- data.frame(parent = parents, x = seq_along(parents), y = 2)",
      "tip_pos <- transform(data, x = match(parent, parents) + seq(-0.25, 0.25, length.out = 3)[ave(seq_along(node), parent, FUN = seq_along)], y = 1)",
      "tip_pos <- merge(tip_pos, parent_pos, by = \"parent\", suffixes = c(\"\", \"_parent\"))",
      "plot <- ggplot2::ggplot() +",
      "  ggplot2::geom_segment(data = tip_pos, ggplot2::aes(x = x_parent, xend = x, y = y_parent, yend = y), color = \"gray55\") +",
      "  ggplot2::geom_point(data = parent_pos, ggplot2::aes(x = x, y = y), size = 3, color = \"gray25\") +",
      "  ggplot2::geom_point(data = tip_pos, ggplot2::aes(x = x, y = y, fill = group, size = value), shape = 21, color = \"black\") +",
      "  ggplot2::scale_y_continuous(NULL, breaks = NULL) +",
      "  ggplot2::scale_x_continuous(NULL, breaks = NULL) +",
      "  ggplot2::labs(fill = \"Group\", size = \"Value\") +",
      "  ggplot2::theme_void(base_size = 11)"
    ),
    network = c(
      "nodes <- sort(unique(c(data$from, data$to)))",
      "pos <- data.frame(node = nodes, angle = seq(0, 2 * pi, length.out = length(nodes) + 1)[seq_along(nodes)])",
      "pos$x <- cos(pos$angle); pos$y <- sin(pos$angle)",
      "edges <- merge(data, pos, by.x = \"from\", by.y = \"node\")",
      "edges <- merge(edges, pos, by.x = \"to\", by.y = \"node\", suffixes = c(\"\", \"_to\"))",
      "plot <- ggplot2::ggplot() +",
      "  ggplot2::geom_segment(data = edges, ggplot2::aes(x = x, y = y, xend = x_to, yend = y_to, alpha = weight), color = \"gray55\") +",
      "  ggplot2::geom_point(data = pos, ggplot2::aes(x = x, y = y), size = 4, color = \"#287D8EFF\") +",
      "  ggplot2::coord_equal() +",
      "  ggplot2::scale_alpha(range = c(0.25, 0.8)) +",
      "  ggplot2::theme_void(base_size = 11)"
    ),
    polar = c(
      "plot <- ggplot2::ggplot(data, ggplot2::aes(x = category, y = value, fill = group)) +",
      "  ggplot2::geom_col(width = 0.85, color = \"white\") +",
      "  ggplot2::coord_polar() +",
      "  ggplot2::labs(x = NULL, y = \"Value\", fill = \"Group\") +",
      "  ggplot2::theme_minimal(base_size = 11) +",
      "  ggplot2::theme(axis.text.x = ggplot2::element_text(size = 8), panel.grid.minor = ggplot2::element_blank())"
    ),
    heatmap = c(
      "plot <- ggplot2::ggplot(data, ggplot2::aes(x = column, y = row, fill = value)) +",
      "  ggplot2::geom_tile(color = \"white\", linewidth = 0.25) +",
      "  ggplot2::scale_fill_gradient2(low = \"#3B4CC0\", mid = \"white\", high = \"#B40426\") +",
      "  ggplot2::labs(x = NULL, y = NULL, fill = \"Value\") +",
      "  ggplot2::theme_minimal(base_size = 10) +",
      "  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))"
    ),
    volcano = c(
      "data$group <- ifelse(data$padj < 0.05 & data$log2FoldChange > 1, \"Up\", ifelse(data$padj < 0.05 & data$log2FoldChange < -1, \"Down\", \"Not significant\"))",
      "plot <- ggplot2::ggplot(data, ggplot2::aes(x = log2FoldChange, y = -log10(padj), color = group)) +",
      "  ggplot2::geom_hline(yintercept = -log10(0.05), linetype = \"dashed\", color = \"gray55\") +",
      "  ggplot2::geom_vline(xintercept = c(-1, 1), linetype = \"dashed\", color = \"gray55\") +",
      "  ggplot2::geom_point(alpha = 0.75, size = 1.8) +",
      "  ggplot2::scale_color_manual(values = c(Down = \"#3B4CC0\", `Not significant` = \"gray70\", Up = \"#B40426\")) +",
      "  ggplot2::labs(x = \"log2 fold change\", y = \"-log10 adjusted p-value\", color = NULL) +",
      "  ggplot2::theme_classic(base_size = 11)"
    ),
    ordination = c(
      "plot <- ggplot2::ggplot(data, ggplot2::aes(x = axis1, y = axis2, fill = group)) +",
      "  ggplot2::geom_hline(yintercept = 0, linetype = \"dashed\", color = \"gray65\") +",
      "  ggplot2::geom_vline(xintercept = 0, linetype = \"dashed\", color = \"gray65\") +",
      "  ggplot2::geom_point(shape = 21, size = 3.5, color = \"black\") +",
      "  ggplot2::labs(x = \"Axis 1\", y = \"Axis 2\", fill = \"Group\") +",
      "  ggplot2::theme_classic(base_size = 11)"
    ),
    bubble = c(
      "data$term <- factor(data$term, levels = rev(data$term[order(data$score)]))",
      "plot <- ggplot2::ggplot(data, ggplot2::aes(x = group, y = term, size = count, color = score)) +",
      "  ggplot2::geom_point(alpha = 0.85) +",
      "  ggplot2::scale_color_viridis_c(option = \"C\") +",
      "  ggplot2::labs(x = NULL, y = NULL, size = \"Count\", color = \"Score\") +",
      "  ggplot2::theme_minimal(base_size = 11)"
    ),
    box = c(
      "plot <- ggplot2::ggplot(data, ggplot2::aes(x = group, y = value, fill = group)) +",
      "  ggplot2::geom_boxplot(width = 0.55, outlier.shape = NA, alpha = 0.75) +",
      "  ggplot2::geom_jitter(width = 0.14, size = 1.5, alpha = 0.65) +",
      "  ggplot2::labs(x = NULL, y = \"Value\", fill = NULL) +",
      "  ggplot2::theme_classic(base_size = 11)"
    ),
    line = c(
      "summary_data <- aggregate(value ~ timepoint + group, data, function(x) c(mean = mean(x), se = stats::sd(x) / sqrt(length(x))))",
      "summary_data$mean <- summary_data$value[, \"mean\"]",
      "summary_data$se <- summary_data$value[, \"se\"]",
      "summary_data$value <- NULL",
      "plot <- ggplot2::ggplot(summary_data, ggplot2::aes(x = timepoint, y = mean, color = group, fill = group)) +",
      "  ggplot2::geom_ribbon(ggplot2::aes(ymin = mean - se, ymax = mean + se), alpha = 0.18, color = NA) +",
      "  ggplot2::geom_line(linewidth = 0.9) +",
      "  ggplot2::geom_point(size = 2) +",
      "  ggplot2::labs(x = \"Time point\", y = \"Mean value\", color = \"Group\", fill = \"Group\") +",
      "  ggplot2::theme_classic(base_size = 11)"
    ),
    map = c(
      "plot <- ggplot2::ggplot(data, ggplot2::aes(x = longitude, y = latitude, size = value, fill = group)) +",
      "  ggplot2::geom_point(shape = 21, alpha = 0.75, color = \"black\") +",
      "  ggplot2::coord_fixed(xlim = range(data$longitude) + c(-2, 2), ylim = range(data$latitude) + c(-2, 2)) +",
      "  ggplot2::labs(x = \"Longitude\", y = \"Latitude\", size = \"Value\", fill = \"Group\") +",
      "  ggplot2::theme_minimal(base_size = 11)"
    ),
    flow = c(
      "plot <- ggplot2::ggplot(data, ggplot2::aes(x = stage, y = value, fill = group, group = group)) +",
      "  ggplot2::geom_area(position = \"fill\", alpha = 0.85) +",
      "  ggplot2::labs(x = NULL, y = \"Proportion\", fill = \"Group\") +",
      "  ggplot2::theme_minimal(base_size = 11)"
    ),
    bar = c(
      "data$category <- factor(data$category, levels = data$category[order(data$value)])",
      "plot <- ggplot2::ggplot(data, ggplot2::aes(x = category, y = value, fill = group)) +",
      "  ggplot2::geom_col(width = 0.72, color = \"white\") +",
      "  ggplot2::coord_flip() +",
      "  ggplot2::labs(x = NULL, y = \"Value\", fill = \"Group\") +",
      "  ggplot2::theme_classic(base_size = 11)"
    ),
    facet = c(
      "plot <- ggplot2::ggplot(data, ggplot2::aes(x = feature, y = value, fill = group)) +",
      "  ggplot2::geom_col(width = 0.72) +",
      "  ggplot2::facet_wrap(~ panel, ncol = 2) +",
      "  ggplot2::labs(x = NULL, y = \"Value\", fill = \"Group\") +",
      "  ggplot2::theme_minimal(base_size = 10) +",
      "  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))"
    ),
    c(
      "plot <- ggplot2::ggplot(data, ggplot2::aes(x = x, y = y, fill = group)) +",
      "  ggplot2::geom_point(shape = 21, size = 2.6, alpha = 0.8, color = \"black\") +",
      "  ggplot2::labs(x = \"X\", y = \"Y\", fill = \"Group\") +",
      "  ggplot2::theme_classic(base_size = 11)"
    )
  )
  c(common, body, "", "ggplot2::ggsave(output_path, plot = plot, height = 6, width = 8)", "message(\"Wrote figure: \", output_path)")
}

schema_for <- function(kind) {
  switch(
    kind,
    tree = "node, parent, group, value",
    network = "from, to, weight, group",
    polar = "category, group, value",
    heatmap = "row, column, value, group",
    volcano = "feature, log2FoldChange, padj",
    ordination = "sample, group, axis1, axis2",
    bubble = "term, group, score, count",
    box = "group, value, batch",
    line = "timepoint, group, replicate, value",
    map = "site, longitude, latitude, value, group",
    flow = "stage, group, value",
    bar = "category, group, value",
    facet = "feature, panel, value, group",
    "x, y, group, label"
  )
}

encoding_for <- function(kind) {
  switch(
    kind,
    tree = "Branch segments encode parent-child relationships; node fill encodes group; point size encodes value.",
    network = "Segments encode edges; point positions form a circular layout; edge alpha encodes weight.",
    polar = "Angular position encodes category; radial length encodes value; fill encodes group.",
    heatmap = "Tile position encodes row and column; fill color encodes value.",
    volcano = "X encodes effect size; Y encodes significance; color encodes differential direction.",
    ordination = "X/Y encode reduced-dimension axes; fill color encodes sample group.",
    bubble = "Y encodes ranked term; X encodes category group; size encodes count; color encodes score.",
    box = "X encodes group; Y encodes numeric value; points show observations over distribution summaries.",
    line = "X encodes time; Y encodes mean value; ribbon encodes uncertainty; color encodes group.",
    map = "X/Y encode longitude and latitude; point size encodes value; fill encodes group.",
    flow = "X encodes stage; stacked area height encodes group proportion.",
    bar = "Y encodes category; bar length encodes value; fill encodes group.",
    facet = "Facet panel encodes repeated subgroup; bar height encodes value; fill encodes group.",
    "X and Y encode numeric coordinates; fill encodes group."
  )
}

components_for <- function(kind) {
  switch(
    kind,
    tree = "geom_segment, geom_point, scale_size, theme_void",
    network = "geom_segment, geom_point, coord_equal, scale_alpha, theme_void",
    polar = "geom_col, coord_polar, theme_minimal",
    heatmap = "geom_tile, scale_fill_gradient2, theme_minimal",
    volcano = "geom_point, geom_hline, geom_vline, scale_color_manual, theme_classic",
    ordination = "geom_point, geom_hline, geom_vline, theme_classic",
    bubble = "geom_point, scale_color_viridis_c, theme_minimal",
    box = "geom_boxplot, geom_jitter, theme_classic",
    line = "geom_ribbon, geom_line, geom_point, theme_classic",
    map = "geom_point, coord_fixed, theme_minimal",
    flow = "geom_area, position fill, theme_minimal",
    bar = "geom_col, coord_flip, theme_classic",
    facet = "geom_col, facet_wrap, theme_minimal",
    "geom_point, theme_classic"
  )
}

write_case <- function(case_dir) {
  case_id <- basename(case_dir)
  if (file.exists(file.path(case_dir, "case.md"))) {
    return(data.frame(case_id = case_id, status = "existing", kind = detect_kind(case_id), reason = "Already has case.md"))
  }

  kind <- detect_kind(case_id)
  meta <- kind_metadata(kind)
  data <- make_data(kind)
  write.csv(data, file.path(case_dir, "data.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  writeLines(plot_template(kind), file.path(case_dir, "plot.R"), useBytes = TRUE)

  r_files <- list.files(case_dir, pattern = "\\.[Rr]$", full.names = TRUE, recursive = FALSE)
  r_files <- r_files[basename(r_files) != "plot.R"]
  if (length(r_files) > 0) {
    file.copy(r_files[[1]], file.path(case_dir, "source-script.R"), overwrite = TRUE)
  } else {
    writeLines(c("# Source script was not present in the raw folder.", "# This standardized case uses a compact reproducible data scaffold."), file.path(case_dir, "source-script.R"), useBytes = TRUE)
  }

  pdf_files <- list.files(case_dir, pattern = "\\.pdf$", full.names = TRUE, recursive = FALSE, ignore.case = TRUE)
  pdf_files <- pdf_files[basename(pdf_files) != "reproduction.pdf"]
  if (length(pdf_files) > 0) {
    file.copy(pdf_files[[1]], file.path(case_dir, "reproduction.pdf"), overwrite = TRUE)
  }

  case_md <- c(
    paste0("# ", title_from_id(case_id)),
    "",
    "## Chart Type",
    paste0(meta$chart_type),
    "",
    "## Chart Type Chinese",
    paste0(meta$chart_type_zh),
    "",
    "## Aliases",
    paste0(meta$aliases),
    "",
    "## Best For",
    paste0(meta$best_for),
    "",
    "## Best For Chinese",
    paste0(meta$best_for_zh),
    "",
    "## Data Schema",
    paste0("`data.csv` columns: ", schema_for(kind), "."),
    "",
    "## Visual Encoding",
    encoding_for(kind),
    "",
    "## ggplot Components",
    components_for(kind),
    "",
    "## Adaptation Notes",
    "Use this case as a compact FigureForge scaffold. Replace `data.csv` with real analysis output while preserving the same column names, then tune scales, labels, and ordering in `plot.R`.",
    "",
    "## Common Pitfalls",
    "Check factor ordering before export, keep labels short enough for the chosen canvas, and rerun `render_case.R` after changing the data schema."
  )
  writeLines(case_md, file.path(case_dir, "case.md"), useBytes = TRUE)
  data.frame(case_id = case_id, status = "standardized", kind = kind, reason = "Generated compact reproducible scaffold")
}

status <- do.call(rbind, lapply(case_dirs, write_case))
dir.create(dirname(status_path), recursive = TRUE, showWarnings = FALSE)
write.csv(status, status_path, row.names = FALSE, fileEncoding = "UTF-8")
message("Wrote status: ", status_path)
message("Standardized new cases: ", sum(status$status == "standardized"))
message("Existing cases: ", sum(status$status == "existing"))
