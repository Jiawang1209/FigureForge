# FigureForge

**面向 AI 智能体、由案例增强的 R 科研绘图能力。**

> 输入真实数据，输出可复用 R 代码与出版级图形。

[English](README.md) · 简体中文

FigureForge 是一个绘图能力增强器：把自然语言需求和真实数据交给 AI
智能体，它会利用已经验证的绘图案例生成独立 R 工作流，而不是从空白开始
猜测图形实现。

FigureForge 默认使用 **R / ggplot2**，遇到特定科研图形时按需使用专业 R
包。Python 绘图不在当前范围内，仅保留为未来可能方向。

---

## FigureForge Skill 1.1.0

FigureForge Skill 1.1.0 是当前完成本地认证的发布版本。
FigureForge Skill 1.0.1 是此前已认证的历史发布版本。v1.1.0 认证证据记录于
[`docs/figureforge-skill-v1.1.0-release.md`](docs/figureforge-skill-v1.1.0-release.md)。

### 用户快速开始

向 AI 智能体提出：

> 使用 `xxx.csv` 数据，基于 FigureForge 帮我绘制一个散点图，并给我一份 R 脚本。

FigureForge 会：

1. 检查真实数据的列名、类型、缺失值和科研表达目标；
2. 选择一个主案例作为实现基线，仅在布局、标注或样式确有需要时参考可选
   辅助案例；
3. 将验证过的 R 方法迁移为独立脚本，由脚本读取输入文件并写入明确的输出
   目录；
4. 运行脚本、检查渲染结果并返回：
   - `plot.R` —— 可复用源代码；
   - `plot.png` —— 便于查看的预览图；
   - `plot.pdf` —— 出版级矢量图。

使用下面的稳定契约重新运行交付结果：

```bash
Rscript plot.R <input-file> <output-directory>
```

案例检索、schema 映射、案例元数据和任务级 QA 都在后台完成。普通用户无需
操作案例库，也无需编辑案例元数据。

### 案例增强带来的能力

- **有证据的起点** —— 一个主案例提供已经能运行的视觉语法与真实 R 实现。
- **聚焦组合** —— 可选辅助案例只补充当前需求确实需要的专业技术。
- **真实数据迁移** —— 智能体根据实际输入 schema 映射字段，不假设通用列名。
- **可复用交付** —— 结果是独立的 `plot.R`，不隐藏在仓库专属运行时之后。
- **可视化质检** —— 按需求和科研表达目标检查渲染后的 PNG 与 PDF。
- **双语检索** —— 中英文图名与别名都可用于选择案例。

### 产品方向

当前交付的是 FigureForge Skill。未来可通过 local-first MCP 层向其他
Agent 暴露案例检索、校验、渲染和 schema 映射能力。**MCP 状态为 planned 且尚未实现**，当前不分发 MCP server 或 endpoint。

## 维护者工作流

以下内容记录案例校验、打包、发布、私有案例库和旧版本兼容流程。它们是
普通用户绘图体验背后的可靠性机制，不是普通用户必须执行的步骤。

### v1.0.1 历史兼容与发布证据

FigureForge Skill 1.0.1 不依赖私有案例库即可独立使用。发布清单包含
15 个公开案例，其中 3 个真实开放数据案例记录了来源、许可、哈希、署名和
人工 verified QA，另有 12 个合成演示案例用于展示软件行为且不承载科研
结论。版本还包含 24 个合成压力测试夹具和 30 条确定性双语前向评测。
MCP 状态为 planned 且尚未实现。

本地 165 个案例组成的私有案例库、原始参考图、reproduction、审计输出和
实时触发转录都不会进入公开包。每个公开案例的 `case.yml`、
`distribution.yml`、可选的 `source.yml` 与 `qa.md` 决定其声明和分发边界。

### 安装与发现

生成仅包含公开资产的压缩包、清单及相邻 SHA-256 sidecar：

```bash
Rscript skills/figureforge/scripts/package_skill.R \
  --archive /tmp/figureforge-skill-1.0.1.tar.gz \
  --manifest /tmp/figureforge-skill-1.0.1-manifest.csv
```

安装到仓库级 Skill 根目录：

```bash
mkdir -p .agents/skills
tar -xzf /tmp/figureforge-skill-1.0.1.tar.gz -C .agents/skills
test -s .agents/skills/figureforge/SKILL.md
```

用户级安装可改为对应的用户 Skill 根目录。压缩包本身以 `figureforge/`
为根，不会额外生成 `skills/figureforge/` 嵌套层。

为后续命令设置安装根目录：

```bash
export FIGUREFORGE_SKILL_ROOT="$PWD/.agents/skills/figureforge"
```

Codex 可从 `.agents/skills/figureforge` 发现该 Skill。显式请求可以使用
`$figureforge`；只有真实列名、中文或英文图形需求的隐式请求也包含在触发
说明中。

### R 运行时与公开工作流

需要启动子 R 进程的命令按以下顺序解析 Rscript：显式 `--rscript`、
`FIGUREFORGE_RSCRIPT`、兼容路径 `/usr/local/bin/Rscript`，最后是
`PATH` 中的 `Rscript`。显式配置无效时会直接失败，不会静默降级。

```bash
export FIGUREFORGE_RSCRIPT="${FIGUREFORGE_RSCRIPT:-Rscript}"

"$FIGUREFORGE_RSCRIPT" \
  "$FIGUREFORGE_SKILL_ROOT/scripts/doctor.R"

"$FIGUREFORGE_RSCRIPT" \
  "$FIGUREFORGE_SKILL_ROOT/scripts/search_cases.R" \
  --public --query "相关性 heatmap" --limit 5

"$FIGUREFORGE_RSCRIPT" \
  "$FIGUREFORGE_SKILL_ROOT/scripts/match_schema.R" \
  --case public-timeseries-band --input <input.csv> --output <match.csv>

"$FIGUREFORGE_RSCRIPT" \
  "$FIGUREFORGE_SKILL_ROOT/scripts/create_adaptation.R" \
  --case public-timeseries-band --input <input.csv> \
  --workspace <external_adaptation_dir>

"$FIGUREFORGE_RSCRIPT" \
  "$FIGUREFORGE_SKILL_ROOT/scripts/visual_qa.R" \
  --render <external_adaptation_dir>/output.pdf \
  --report <external_report_dir>/visual-qa.json
```

所有迁移工作区和渲染输出都必须位于安装目录之外。随包演示会强制执行该
边界。合成案例的迁移结果在获得授权人工检查前保持
`Status: review_required`；自动 QA 永远不能授予 verified 状态。

```bash
sh "$FIGUREFORGE_SKILL_ROOT/examples/public-demo/run_demo.sh" \
  /tmp/figureforge-public-demo
```

### 验证、评测与升级

安装前验证外层 sidecar、压缩包结构、allowlist 成员、字节数和每个文件的
哈希：

```bash
Rscript skills/figureforge/scripts/verify_release.R \
  --archive /tmp/figureforge-skill-1.0.1.tar.gz \
  --manifest /tmp/figureforge-skill-1.0.1-manifest.csv \
  --extract-dir /tmp/figureforge-skill-1.0.1-verified
```

运行确定性双语评测目录：

```bash
Rscript skills/figureforge/scripts/evaluate_skill.R \
  --catalog skills/figureforge/references/trigger-evals-v1.csv \
  --output-dir /tmp/figureforge-forward-evals \
  --report /tmp/figureforge-forward-evals.csv \
  --rscript "${FIGUREFORGE_RSCRIPT:-Rscript}"
```

真实 Codex 触发探针是显式启用且有界的发布门：

```bash
bash scripts/run_figureforge_live_evals.sh \
  --output-dir outputs/figureforge-v101/live-evals/manual
```

从 1.0.0 升级到 1.0.1 时，先保留外部 adaptation，在已安装目录旁验证
1.0.1 暂存目录；再把精确的 `.agents/skills/figureforge` 目标重命名为
目标专属备份，原子重命名暂存版本并完成验证，最后只删除该精确备份。不要
把新旧文件合并到同一目录，否则会留下过期的 v1.0.0 文件。

发布边界、来源哈希、测试证据和仅本地发布政策见
[`docs/figureforge-skill-v1.0.1-release.md`](docs/figureforge-skill-v1.0.1-release.md)。

### 案例系统原理

通用的"画一张 Nature 风格的图"提示,给你的只是一次猜测。FigureForge 给你的是**证据**:

- **基于案例选型** —— 从一张已经能跑通的真实图开始,而不是空白提示。
- **真实代码迁移** —— 复用具体、可复现的 `plot.R`,而不是模型合成的样板代码。
- **数据结构映射** —— 把你的列名映射到有文档记录的案例 schema 上。
- **可视化质检** —— 对照参考复现图和检查清单核验结果。
- **中英双语设计** —— 案例元数据与检索关键词同时包含中文图名与别名(`柱状图`、`箱线图`、`小提琴图`、`散点图`、`折线图`、`热图`、`分面图`、`多面板` ……)。

核心资产不是某一个指令文件,而是不断积累的案例库——范例、数据、脚本与元数据的总和。

### 维护中的案例工作流

```
你的目标 + 数据  ─▶  检索图库  ─▶  选最接近的案例  ─▶  映射列名
                                                            │
        出版级图  ◀─  质检清单  ◀─  迁移改写 plot.R  ◀────────┘
```

驱动 `figureforge` 技能的 AI 智能体会:

1. 检查科研问题与真实输入数据结构。
2. 使用中英文检索案例元数据，并优先选择已经完成的案例。
3. **动手改写前**，查阅所选案例的元数据、数据、脚本和 QA 证据。
4. 检查依赖并建立明确的字段映射记录。
5. 在私有案例库之外迁移真实案例脚本。
6. 渲染、人工视觉检查，再用迁移验证器独立重渲染。
7. 报告所选案例、映射、命令、输出、QA、分发边界和残留限制。

### Skill + MCP 产品方向

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

### 仓库结构

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

#### 关于案例语料

本仓库提供的是**技能框架**——工作流、参考文档、辅助脚本和一份案例模板。完整的精选案例语料(165+ 配图复现)位于本地的 `skills/figureforge/cases/`,但**默认被 gitignore、保持私有**,因为很多案例包含无法再分发的第三方参考图与源数据。

克隆本仓库,你将获得运行工作流、撰写自己案例所需的一切;原始配图与受限数据不在其中。

### 案例格式

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

### 辅助脚本

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

### 案例完成度审计

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

### 撰写新案例

1. 添加或选择真实源数据、源代码和复现证据。
2. 在 `case.md` 填写来源、schema、可视化编码、依赖、迁移说明、易错点和
   中英文别名。
3. 在保留原始资料的前提下，把真实数据规范化为 `data.csv`。
4. 把 `plot.R` 重构为接受明确输入、输出路径。
5. 在案例目录外渲染，并与真实参考图视觉对照。
6. 保存完整 `qa.md`，分开发审查另行处理。
7. 执行 `validate_case.R --complete --render`，再更新本地索引。

### 已验证的 Skill MVP

本地私有案例库共有 165 个已审计案例。完整语料八批全部完成后，已有 152
个案例通过完整案例契约：包括原有 15 个 MVP 案例和新增恢复的 137 个案例。
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
第五批加入微生物分类扇形与聚类树、分类组合图、注释网络、表格与柱图组合、
甜甜圈构成、简单几何图形、曼哈顿图、GO 注释与富集、图例工程、WGCNA
模块树、代谢物 IQR 点区间图和 GO 重排彩色标签。第六批加入单细胞 UMAP、
置信带时序图、河流组成图、PPI 多布局、双比较差异表达气泡图、微生物相关
网络、单染色体组成轨道、GO 圈图和相关性/Mantel 连线矩阵。最新带渲染
第七批继续加入聚类与注释热图、相关性圈图与网络、单组及多组差异表达图、
互作 circos、分面 ANOVA 和进阶采样地图。第八批关闭最后 10 个待处理案例，
加入饼图节点网络、嵌套分类气泡、分组物种组成柱形图、带符号文本和侧边注释
的相关性热图、Venn 图、相关性/显著性四面板、双核心调控网络、漫画字体图和
旋转三角热图。最终带渲染审计记录为 152 个完成、13 个有证据支持的阻塞、
0 个待处理；阻塞细分为 6 个
`blocked_source_missing`、3 个 `blocked_ambiguous_mapping` 和 4 个
`blocked_visual_reference`。由于尚未获得再分发许可，165 个案例均为
`private_only`。

三组不同的新数据迁移证明工作流不只会复现：

- R `HairEyeColor` → 三种标注策略的扇形图；
- R `USArrests` → 带正负号与绝对值编码的相关性气泡热图；
- R `ChickWeight` → 四组饮食、95% t 区间和局部插图的时序图。

每组迁移都有不同输入、字段映射、迁移后的 `plot.R`、精确命令、渲染
PDF、书面 QA 和独立重渲染结果，保存在被忽略的
`outputs/figureforge-adaptations/`。

### 路线图

- [x] 完成 15 个私有 R/ggplot2 MVP 案例的真实来源核对、全新渲染和
      书面视觉 QA。
- [x] 完成完整语料第一批：新增开发并完整验证 20 个案例。
- [x] 完成完整语料第二批：再新增开发并完整验证 20 个案例。
- [x] 完成完整语料第三批：再新增开发并完整验证 20 个案例。
- [x] 完成完整语料第四批：新增完整验证 19 个案例，并将 1 个案例以通过
      校验的原始资料缺失证据归入阻塞终态。
- [x] 完成完整语料第五批：新增完整验证 16 个案例，并将 4 个案例以原始
      资料缺失、视觉参考缺失或映射不明确证据归入阻塞终态。
- [x] 完成完整语料第六批：新增完整验证 14 个案例，并将 6 个案例以原始
      资料缺失、视觉参考缺失或映射不明确证据归入阻塞终态。
- [x] 完成完整语料第七批：新增完整验证 18 个案例，并将 2 个案例以视觉
      参考缺失证据归入阻塞终态。
- [x] 完成完整语料第八批：将最后 10 个案例全部完成并通过完整验证。
- [x] 使用三份不同新数据和三种图形完成端到端迁移验证。
- [x] 将全部 165 个私有案例逐个处理为 completed 或有充分证据的 blocked，
      不再存在 pending。
- [ ] 只有 Skill 与案例库最终验收后，才开发 local-first FigureForge MCP
      server。
- [ ] 完成独立分发审查后再扩充公开精选图库。
- [ ] R 优先工作流稳定后,补充 Python 案例。
- [ ] 探索软件/资源、数据描述符或方法学方向的发表。

完整愿景与定位见 [`PROJECT_HANDOFF.md`](PROJECT_HANDOFF.md)。

### 当前状态

**FigureForge Skill 1.1.0 是当前完成本地认证的发布版本。**
FigureForge Skill 1.0.1 是此前已认证的历史发布版本。当前包包含 15 个公开
案例（3 个真实开放数据案例和 12 个合成演示案例）、24 个压力测试夹具和
30 条确定性双语前向评测。165 个私有案例中有 152 个满足完整契约，其余
13 个具有通过校验的案例级阻塞记录，待处理数为 0；私有案例库不进入公开
包。MCP 状态为 planned 且尚未实现，当前不分发 MCP endpoint 或 server。

### 许可

公开框架采用仓库 MIT [`LICENSE`](LICENSE)。每个公开案例另有明确的
`distribution.yml`。私有案例和第三方源素材不属于公开发布范围。
