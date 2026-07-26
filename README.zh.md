# FigureForge

**面向 AI 智能体、由案例增强的 R 科研绘图能力。**

FigureForge 是一个绘图能力增强器：把真实数据和绘图需求交给 AI 智能体，
即可获得可复用 R 代码与出版级图形。

[English](README.md) · 简体中文

## 安装

在需要使用 FigureForge 的项目中，运行下面可安全升级的 POSIX shell 代码：

```sh
# figureforge-install:start
(
set -eu

FIGUREFORGE_REPO_URL=${FIGUREFORGE_REPO_URL:-https://github.com/Jiawang1209/FigureForge.git}
figureforge_target=.agents/skills/figureforge
figureforge_clone=$(mktemp -d "${TMPDIR:-/tmp}/figureforge-clone.XXXXXX")
figureforge_stage_root=
figureforge_backup_root=
figureforge_published=0

figureforge_cleanup() {
  figureforge_status=$?
  trap - 0 HUP INT TERM
  if [ "$figureforge_published" -eq 0 ] &&
     [ -n "$figureforge_backup_root" ] &&
     [ -e "$figureforge_backup_root/figureforge" ]; then
    if [ ! -e "$figureforge_target" ] && [ ! -L "$figureforge_target" ]; then
      mv "$figureforge_backup_root/figureforge" "$figureforge_target" ||
        figureforge_status=1
    else
      printf '%s\n' "Previous install preserved at $figureforge_backup_root/figureforge" >&2
      figureforge_backup_root=
    fi
  fi
  for figureforge_dir in \
    "$figureforge_stage_root" "$figureforge_backup_root" "$figureforge_clone"
  do
    if [ -n "$figureforge_dir" ] && [ -d "$figureforge_dir" ]; then
      rm -rf "$figureforge_dir" || figureforge_status=1
    fi
  done
  exit "$figureforge_status"
}
trap figureforge_cleanup 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

git clone --quiet "$FIGUREFORGE_REPO_URL" "$figureforge_clone/repo"
test -s "$figureforge_clone/repo/skills/figureforge/SKILL.md"
mkdir -p .agents/skills
figureforge_stage_root=$(mktemp -d ".agents/skills/.figureforge-stage.XXXXXX")
cp -R "$figureforge_clone/repo/skills/figureforge" \
  "$figureforge_stage_root/figureforge"
test -s "$figureforge_stage_root/figureforge/SKILL.md"

figureforge_backup_root=$(mktemp -d ".agents/skills/.figureforge-backup.XXXXXX")
if [ -e "$figureforge_target" ] || [ -L "$figureforge_target" ]; then
  mv "$figureforge_target" "$figureforge_backup_root/figureforge"
fi
mv "$figureforge_stage_root/figureforge" "$figureforge_target"
figureforge_published=1
rm -rf "$figureforge_backup_root" "$figureforge_stage_root" "$figureforge_clone"
figureforge_backup_root=
figureforge_stage_root=
figureforge_clone=
trap - 0 HUP INT TERM
)
# figureforge-install:end
```

其他兼容 Skill 的智能体也可以使用同一个 `skills/figureforge` 目录：将其
复制到该智能体支持的 Skill 根目录即可。

## 使用

向 AI 智能体提出：

> 使用 data.csv 数据，基于 FigureForge Skill 帮我绘制一个散点图，并给我一份 R 脚本。

Skill 会检查真实数据、迁移经过验证的绘图方法、渲染结果，并返回独立脚本
及其图形。

案例生成只有实际使用案例证据并通过严格的追踪验证，才可以声称使用了 FigureForge 案例知识。
通用回退仍可完成绘图，但必须使用 `claim: general_method`，且不得声称由案例支撑。
案例检索、证据读取以及隐藏追踪的创建和校验均由 Skill 在后台完成；普通用户无需操作案例库。
无论采用哪种模式，Skill 都只在模式选择前记录检索词的 SHA-256、受控的抽象检索意图和带哈希的 CSV 检索回执；原始检索词不会被持久化。
这些哈希属于可关联的伪名化标识，并非加密；检索词必须保持抽象，不得包含秘密或个人标识。
默认可见输出仍是 `plot.R`、`plot.png` 和 `plot.pdf`；隐藏的案例追踪与检索回执仅用于审计。

## Iris PCA 演示

可用下面的具体提示体验完整公开示例：

> 使用 examples/iris-pca/iris.csv 数据，基于 FigureForge Skill 创建一张 PCA 双标图，完成渲染，并给我一份 R 脚本。

也可以直接运行仓库中的演示：

```bash
Rscript examples/iris-pca/plot.R examples/iris-pca/iris.csv examples/iris-pca
```

GitHub 上的 [HTML 链接](examples/iris-pca/index.html)显示的是报告源代码。
克隆仓库后，请在本地打开 `examples/iris-pca/index.html`（macOS 可运行
`open examples/iris-pca/index.html`，其他系统可使用浏览器的“打开文件”）。
另见[源文件目录与说明](examples/iris-pca/README.md)。

## 默认输出

FigureForge 默认向用户交付且恰好交付：

- `plot.R`
- `plot.png`
- `plot.pdf`

使用以下稳定契约重新运行交付脚本：

```bash
Rscript plot.R <input-file> <output-directory>
```

## 文档

- [Skill 入口](skills/figureforge/SKILL.md)
- [绘图工作流](skills/figureforge/references/plotting-workflow.md)
- [维护者工作流](skills/figureforge/references/maintainer-workflow.md)
- [FigureForge Skill 1.1.0 当前认证](docs/figureforge-skill-v1.1.0-release.md)
- [可移植认证证据](docs/figureforge-skill-v1.1.0-evidence/README.md)
- [重新认证流程](docs/figureforge-skill-v1.1.0-recertification.md)
- [当前状态](docs/figureforge-skill-mvp-status.md)
- [历史 v1.0.1 发布证据](docs/figureforge-skill-v1.0.1-release.md)

## 范围

FigureForge 默认使用 R 和 ggplot2；科研图形确有需要时，再引入专业 R 包。

FigureForge Skill 1.1.0 是当前完成本地认证的发布版本。机器可读身份绑定
准确的发布输入 commit 与包清单；后续仅文档 commit 可以承载该认证，而
无需改变已认证源码 commit。
FigureForge Skill 1.0.1 是此前已认证的历史发布版本。随包提供 15 个公开案例。

本地 `skills/figureforge/cases/` 私有案例库和受限来源材料不会公开分发；
简洁的发布边界见上方发布证据与当前状态链接。Python 绘图和 MCP 不在当前
已发布范围内。**MCP 状态为 planned 且尚未实现。**

## 许可

FigureForge 使用 [MIT 许可证](LICENSE)。
