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

1. 澄清你的绘图目标、数据类型、目标输出、技术生态与使用语言。
2. 在 `references/gallery-index.md` 与案例元数据中检索匹配的图类型与别名。
3. **动手改写前**,先打开案例的 `case.md`、`plot.R` 与数据文件。
4. 从你的数据到案例 schema,建立一张列映射表。
5. 改写案例专属脚本,保留有价值的可视化结构。
6. 渲染图形并执行质检清单。
7. 报告所用案例、映射决策、产出文件、已做的核验以及残留限制。

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
skills/figureforge/cases/NNN-case-name/
├── case.md            # 元数据 + 迁移说明(必需)
├── data.csv           # 绘图数据(必需)
├── plot.R             # 可复现绘图脚本(必需)
├── reproduction.pdf   # / .png —— 我们的复现图(若有)
└── original.png       # 参考图,仅在允许再分发时提供
```

`case.md` 遵循一组固定标题,使其在各案例间保持机器可读且一致:

```text
## Chart Type            ## Visual Encoding
## Chart Type Chinese    ## ggplot Components
## Aliases               ## Adaptation Notes
## Best For              ## Common Pitfalls
## Best For Chinese
## Data Schema
```

模板见 `skills/figureforge/cases/_template/case.md`。`_template` 文件夹只是格式指南,**不是**真实的配图复现案例。

## 辅助脚本

所有脚本都是纯 `Rscript`,从仓库根目录运行:

```bash
# 校验案例文件夹是否具备必需文件与 case.md 标题
Rscript skills/figureforge/scripts/validate_case.R <case_dir>

# 将案例的 plot.R 渲染为图像文件
Rscript skills/figureforge/scripts/render_case.R <case_dir> [output_path]

# 重建机器可读的案例索引(CSV)
Rscript skills/figureforge/scripts/index_cases.R [cases_dir] [output_csv]
```

`render_case.R` 与 `validate_case.R` 刻意保持简单、案例专属——让每个案例独立可懂、可复现,而不是被藏进一个通用绘图框架里。

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

scaffolded（脚手架化）案例不等于已完成案例。成功运行只能证明代码可以
执行，不能证明视觉一致。缺少分发审核时一律默认为 `private_only`。审计
报告写入被忽略的 `outputs/`，不得与私有案例信息一起提交。

## 撰写新案例

1. 添加或选定一个真实的配图复现。
2. 填写 `case.md`:图类型、数据 schema、可视化编码、ggplot2 组件、迁移说明、易错点,以及中英别名。
3. 让 `plot.R` 保持案例专属且可复现。
4. 渲染:`Rscript .../render_case.R <case_dir>`。
5. 校验结构:`Rscript .../validate_case.R <case_dir>`。
6. 更新索引:`Rscript .../index_cases.R`。
7. 在称之为"出版级"之前,跑一遍质检清单。

## 路线图

- [ ] 精选 12–20 个 R/ggplot2 案例作为 MVP,覆盖柱状图、箱线图、小提琴图、带标签散点图、趋势线、热图、分面图、多面板与复杂注释。
- [ ] 验证 AI 智能体能端到端地选取并迁移一个案例到新数据集。
- [ ] 构建 local-first 的 FigureForge MCP server,支持案例检索、元数据读取、结构校验、索引重建、图形渲染与列映射建议。
- [ ] 工作流被证明有用后,扩充精选图库。
- [ ] R 优先工作流稳定后,补充 Python 案例。
- [ ] 探索软件/资源、数据描述符或方法学方向的发表。

完整愿景与定位见 [`PROJECT_HANDOFF.md`](PROJECT_HANDOFF.md)。

## 当前状态

Skill MVP 开发阶段。工作流、参考文档、公开模板、辅助脚本和案例审计契约
已经建立。私有语料库目前是候选案例清单；只有通过真实数据核对、全新
渲染、复现证据和书面 QA 的案例才会计为完成。公开精选案例集仍在整理。

## 许可

尚未选定许可协议。**在公开复用或再分发前请先添加许可。** 注意:个别案例可能引用受其自身条款约束的第三方配图与数据。
