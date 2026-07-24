# FigureForge

**面向 AI、可复现、基于案例的科研出版级数据可视化技能库。**

> 从复现到迁移(From reproduction to adaptation)。

[English](README.md) · 简体中文

FigureForge 把真实的论文配图复现,沉淀为可复用、可由 AI 驱动的绘图工作流。每个案例都把参考图、可复现数据、绘图代码、迁移说明和质量检查规则连接在一起——这样 AI 智能体(或人)就能挑出最接近的范例、迁移到全新的科研数据上,而不是凭空提示模型"画一张图"。

首个版本以 **R / ggplot2 优先**,源自长期更新的配图复现系列(*在模仿中精进数据可视化*)。待 R 工作流稳定后,将规划支持 Python。

---

## 为什么是 FigureForge

通用的"画一张 Nature 风格的图"提示,给你的只是一次猜测。FigureForge 给你的是**证据**:

- **基于案例选型** —— 从一张已经能跑通的真实图开始,而不是空白提示。
- **真实代码迁移** —— 复用具体、可复现的 `plot.R`,而不是模型合成的样板代码。
- **数据结构映射** —— 把你的列名映射到有文档记录的案例 schema 上。
- **可视化质检** —— 对照参考复现图和检查清单核验结果。
- **中英双语设计** —— 案例元数据与检索关键词同时包含中文图名与别名(`柱状图`、`箱线图`、`小提琴图`、`散点图`、`折线图`、`热图`、`分面图`、`多面板` ……)。

核心资产不是某一个指令文件,而是不断积累的案例库——范例、数据、脚本与元数据的总和。

## 工作原理

```
你的目标 + 数据  ─▶  检索图库  ─▶  选最接近的案例  ─▶  映射列名
                                                            │
        出版级图  ◀─  质检清单  ◀─  迁移改写 plot.R  ◀────────┘
```

驱动 `figureforge` 技能的 AI 智能体会:

1. 检查科研问题与真实输入数据结构。
2. 使用中英文检索案例元数据，并优先选择已经完成的案例。
3. **动手改写前**，打开案例的 `case.md`、`data.csv`、`plot.R` 和
   `qa.md`。
4. 检查依赖并建立明确的字段映射记录。
5. 在私有案例库之外迁移真实案例脚本。
6. 渲染、人工视觉检查，再用迁移验证器独立重渲染。
7. 报告所选案例、映射、命令、输出、QA、分发边界和残留限制。

## Skill + MCP 产品方向

FigureForge 将发展为 **Skill + MCP 双层产品**:

- **Skill 层** —— 教会 AI 智能体按案例工作:选择真实范例、检查元数据和代码、映射用户数据 schema、迁移绘图脚本、渲染并完成质检。
- **MCP 层** —— 把 FigureForge 暴露为其他 Agent 可调用的工具,让它们无需手动解析整个仓库,就能检索案例、读取元数据、校验案例结构、重建索引、渲染图形,并生成列映射草案。

规划中的 MCP 工具包括:

- `figureforge_health`
- `figureforge_list_cases`
- `figureforge_search_cases`
- `figureforge_get_case`
- `figureforge_validate_case`
- `figureforge_build_index`
- `figureforge_render_case`
- `figureforge_suggest_mapping`

MCP 服务应保持 **local-first**:它可以读取本地私有案例库,但公开发布时只应包含可再分发的案例与素材。完整设计与开发计划见 [`docs/superpowers/specs/2026-07-07-figureforge-skill-mcp-dual-layer-design.md`](docs/superpowers/specs/2026-07-07-figureforge-skill-mcp-dual-layer-design.md) 和 [`docs/superpowers/plans/2026-07-07-figureforge-skill-mcp-dual-layer.md`](docs/superpowers/plans/2026-07-07-figureforge-skill-mcp-dual-layer.md)。

## 仓库结构

```text
FigureForge/
├── README.md                    # 英文说明
├── README.zh.md                 # 本文件
├── PROJECT_HANDOFF.md           # 愿景、定位与路线图
├── docs/superpowers/            # 设计规格与实现计划
└── skills/figureforge/
    ├── SKILL.md                 # 技能入口与工作流
    ├── references/              # 图库索引 + 可复用指南
    │   ├── gallery-index.md     # 案例导航、元数据字段、别名
    │   ├── data-mapping.md      # 列映射与中文字段处理
    │   ├── ggplot-patterns.md   # 常用 ggplot2 组件
    │   ├── theme-and-export.md  # 出版级导出规范
    │   └── qa-checklist.md      # 最终核验清单
    ├── cases/                   # 案例语料(见下方说明)
    │   └── _template/           # 格式模板 —— 不是真实案例
    └── scripts/                 # R 辅助脚本(校验 / 渲染 / 索引)
```

### 关于案例语料

本仓库提供的是**技能框架**——工作流、参考文档、辅助脚本和一份案例模板。完整的精选案例语料(165+ 配图复现)位于本地的 `skills/figureforge/cases/`,但**默认被 gitignore、保持私有**,因为很多案例包含无法再分发的第三方参考图与源数据。

克隆本仓库,你将获得运行工作流、撰写自己案例所需的一切;原始配图与受限数据不在其中。

## 案例格式

每个真实案例都是一个自包含的文件夹:

```text
skills/figureforge/cases/<case-id>/
├── case.md            # 元数据 + 迁移说明(必需)
├── data.csv           # 绘图数据(必需)
├── plot.R             # 可复现绘图脚本(必需)
├── reproduction.pdf   # / .png —— 我们的复现图(若有)
├── qa.md               # 完成案例的明确核验记录
├── distribution.yml    # 可选；缺失即 private_only
└── original.png       # 参考图,仅在允许再分发时提供
```

`case.md` 遵循一组固定标题,使其在各案例间保持机器可读且一致:

```text
## Chart Type            ## Visual Encoding
## Chart Type Chinese    ## ggplot Components
## Aliases               ## Adaptation Notes
## Best For              ## Common Pitfalls
## Best For Chinese
## Data Provenance
## Data Schema
## Required R Packages
```

模板见 `skills/figureforge/cases/_template/case.md`。`_template` 文件夹只是格式指南,**不是**真实的配图复现案例。

## 辅助脚本

从仓库根目录使用 `/usr/local/bin/Rscript` 运行 R 工作流:

```bash
# 校验案例文件夹是否具备必需文件与 case.md 标题
/usr/local/bin/Rscript skills/figureforge/scripts/validate_case.R <case_dir>

# 用中英文元数据和 schema 角色检索案例
/usr/local/bin/Rscript skills/figureforge/scripts/search_cases.R \
  --query "相关性 热图" --completed-only

# 重建机器可读的案例索引(CSV)
/usr/local/bin/Rscript skills/figureforge/scripts/index_cases.R \
  [cases_dir] [output_csv]

# 检查单个案例声明的全部依赖
/usr/local/bin/Rscript skills/figureforge/scripts/check_dependencies.R \
  --case-dir <case_dir> --strict

# 使用案例或新输入执行标准 plot.R 参数契约
/usr/local/bin/Rscript skills/figureforge/scripts/render_case.R \
  <case_dir> --input <input_csv> --output <output_path>

# 校验并独立重渲染新数据迁移
/usr/local/bin/Rscript skills/figureforge/scripts/validate_adaptation.R \
  <adaptation_dir> --render --output <validation_output>

# 校验有证据支持的终态阻塞记录
/usr/local/bin/Rscript skills/figureforge/scripts/validate_blocker.R \
  <case_dir>

# 将待处理案例规划为确定性的证据优先批次
/usr/local/bin/Rscript skills/figureforge/scripts/plan_case_batches.R \
  --readiness <case-readiness.csv> \
  --output <batch-manifest.csv> \
  --batch-size 20
```

这些脚本负责检索和核验；绘图逻辑仍保持案例专属、独立可读，而不是藏进
通用绘图框架。

## 案例完成度审计

拥有 `case.md`、`data.csv` 和 `plot.R` 只能证明案例结构存在，不能证明它
使用了真实源数据、忠实复现了原图，或者可以公开分发。

使用下面的只读命令审计本地案例库：

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/audit_cases.R \
  --cases-dir /absolute/path/to/skills/figureforge/cases \
  --output-dir outputs/figureforge-audit \
  --rscript /usr/local/bin/Rscript \
  --render
```

审计会分别记录七类证据：

- `raw`：存在规范文件之外的原始资料；
- `scaffolded`：检测到批量生成的临时脚手架；
- `runnable`：一次隔离的全新渲染成功；
- `reproduced`：存在非空的复现图文件；
- `qa_verified`：存在明确且完整的 `qa.md` 记录；
- `public_ready`：已经审核并明确允许公开分发；
- `private_only`：尚未允许公开，或明确只能私有使用。

完整案例库审计还会记录 `terminal_outcome`：

- `completed`：无脚手架、可运行、有复现证据且 QA 已验证；
- `blocked`：严格证据记录通过 `validate_blocker.R`；
- `pending`：尚未满足任何一种终态合同。

支持的阻塞类别包括 `blocked_source_missing`、`blocked_dependency`、
`blocked_visual_reference`、`blocked_corrupt_asset`、
`blocked_ambiguous_mapping` 和 `blocked_rights`。已验证 QA 与有效 blocker
不能并存；工作量和耗时不能作为阻塞证据。

scaffolded（脚手架化）案例不等于已完成案例。成功运行只能证明代码可以
执行，不能证明视觉一致。缺少分发审核时一律默认为 `private_only`。审计
报告写入被忽略的 `outputs/`，不得与私有案例信息一起提交。

按照完整案例契约验证一个已经开发的案例，并在案例目录外重新渲染：

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/validate_case.R <case_dir> --complete --render --output <output_path>
```

默认验证命令只检查结构。`--complete` 还会要求真实数据来源、R 包声明、
不存在脚手架标记、标准绘图参数契约、复现图证据和已验证的 QA；
`--render` 再增加一次全新执行证据。公开分发许可仍然是独立审核，缺失时
默认为 `private_only`。

## 撰写新案例

1. 添加或选择真实源数据、源代码和复现证据。
2. 在 `case.md` 填写来源、schema、可视化编码、依赖、迁移说明、易错点和
   中英文别名。
3. 在保留原始资料的前提下，把真实数据规范化为 `data.csv`。
4. 把 `plot.R` 重构为接受明确输入、输出路径。
5. 在案例目录外渲染，并与真实参考图视觉对照。
6. 保存完整 `qa.md`，分开发审查另行处理。
7. 执行 `validate_case.R --complete --render`，再更新本地索引。

## 已验证的 Skill MVP

本地私有案例库共有 165 个已审计案例。完整语料前四批完成后，已有 94
个案例通过完整案例契约：包括原有 15 个 MVP 案例和新增恢复的 79 个案例。
除原有分组散点、气泡、火山图、PCA、拟合趋势、ANOVA、扇形图、热图、
时序图、双向柱形图、进化树注释、网络图和无缝多面板外，现还覆盖多轨道
GO 富集圈图、五圈柱形扇形树、树与组成面板、表型注释热图、雷达小多图、
分组气泡矩阵、旭日图和基因组共线性圈图。第二批还加入启动子元件矩阵、
真实 STRING PPI 网络、PCoA/NMDS 对照、冲击图、qRT-PCR 面板、对称柱图、
自定义富集气泡图、分组热图及四种进化树布局。第三批继续加入雨云图与
小提琴分布、微生物功能基因双向柱、环形棒棒糖和环状柱、桑基图、Marker
热图、双 Y 轴与患者配对图、表达量进阶火山图、染色体核型定位、雷达轮廓和
带组成扇形的世界采样地图。第四批加入带边际统计的 PCA、treemap、扇形
glyph、GO/KEGG 面板、circos 与基因家族组合图、启动子矩阵、PPI、表达热图、
qRT-PCR、恢复原始资料后的 Nature Microbiology 进化树、配对树和富集图。
带渲染审计记录为 94 个完成、1 个有证据支持的
`blocked_source_missing`、70 个待处理。由于尚未获得再分发许可，165 个
案例均为 `private_only`。

三组不同的新数据迁移证明工作流不只会复现：

- R `HairEyeColor` → 三种标注策略的扇形图；
- R `USArrests` → 带正负号与绝对值编码的相关性气泡热图；
- R `ChickWeight` → 四组饮食、95% t 区间和局部插图的时序图。

每组迁移都有不同输入、字段映射、迁移后的 `plot.R`、精确命令、渲染
PDF、书面 QA 和独立重渲染结果，保存在被忽略的
`outputs/figureforge-adaptations/`。

## 路线图

- [x] 完成 15 个私有 R/ggplot2 MVP 案例的真实来源核对、全新渲染和
      书面视觉 QA。
- [x] 完成完整语料第一批：新增开发并完整验证 20 个案例。
- [x] 完成完整语料第二批：再新增开发并完整验证 20 个案例。
- [x] 完成完整语料第三批：再新增开发并完整验证 20 个案例。
- [x] 完成完整语料第四批：新增完整验证 19 个案例，并将 1 个案例以通过
      校验的原始资料缺失证据归入阻塞终态。
- [x] 使用三份不同新数据和三种图形完成端到端迁移验证。
- [ ] 将剩余 70 个私有案例逐个处理为 completed 或有充分证据的 blocked。
- [ ] 只有 Skill 与案例库最终验收后，才开发 local-first FigureForge MCP
      server。
- [ ] 完成独立分发审查后再扩充公开精选图库。
- [ ] R 优先工作流稳定后,补充 Python 案例。
- [ ] 探索软件/资源、数据描述符或方法学方向的发表。

完整愿景与定位见 [`PROJECT_HANDOFF.md`](PROJECT_HANDOFF.md)。

## 当前状态

**Skill MVP 已实现并通过本地验证。** 案例检索、索引、依赖诊断、安全
渲染、案例验证、迁移验证、模板、参考文档和三组新数据证明已经就绪。
165 个私有案例中有 94 个满足完整契约，70 个仍为待处理，1 个具有通过
校验的 `blocked_source_missing` 记录。公开精选案例集仍在整理；MCP
Server 仍是规划项，在 Skill 与案例库最终验收前保持暂停且尚未实现。

## 许可

尚未选定许可协议。**在公开复用或再分发前请先添加许可。** 注意:个别案例可能引用受其自身条款约束的第三方配图与数据。
