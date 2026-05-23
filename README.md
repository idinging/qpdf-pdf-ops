# qpdf PDF 操作 Skill

基于 [qpdf](https://qpdf.readthedocs.io) 的 Claude Code skill，提供**无损**的 PDF 页面级操作 —— 不重新渲染、不栅格化，保留原始内容流。

## Quick Install

在 Claude Code 里运行：

```bash
/plugin marketplace add idinging/qpdf-pdf-ops
/plugin install qpdf-pdf-ops@qpdf-pdf-ops
```

安装后**重启 Claude Code** 即可加载。系统需要先装好 qpdf（见下文）。

## 安装

### 一、安装 qpdf 命令行工具

```bash
sudo apt-get install -y qpdf       # Debian/Ubuntu/WSL
sudo dnf install -y qpdf           # Fedora/RHEL
sudo pacman -S qpdf                # Arch
brew install qpdf                  # macOS
winget install --id QPDF.QPDF -e   # Windows
```

### 二、在 Claude Code 中安装本 skill

本仓库符合 Claude Code 官方 **plugin marketplace** 规范，安装一次即可：

```bash
# 1. 添加 marketplace（一次性）
/plugin marketplace add idinging/qpdf-pdf-ops

# 2. 安装 plugin
/plugin install qpdf-pdf-ops@qpdf-pdf-ops
```

安装后**重启 Claude Code** 加载 skill。

> 已有 Claude Code 用户也可用本地路径加载：
> `claude --plugin-dir ./skills/qpdf-pdf-ops`

## 功能概览

| 操作 | 说明 | 脚本 |
|------|------|------|
| 替换页面 | 用另一个 PDF 的某一页替换指定页 | `replace_page.sh` |
| 提取页面 | 按范围提取页面 | `extract_pages.sh` |
| 删除页面 | 按范围删除页面 | `delete_pages.sh` |
| 合并 PDF | 拼接多个 PDF | `merge_pdfs.sh` |
| 拆分 PDF | 按页或每 N 页拆分 | `split_pdf.sh` |
| 旋转页面 | 相对/绝对角度，可指定范围 | (直接 `qpdf --rotate`) |
| 重排页面 | 倒序、移动页面位置 | (直接 `qpdf --pages`) |
| 插入页面 | 在指定位置插入页面 | (直接 `qpdf --pages`) |
| PDF 信息 | 大小、页数、PDF 版本、加密、完整性 | `pdf_info.sh` |
| 加密 / 解密 | 加密、解密、修改权限 | (直接 `qpdf --encrypt` / `--decrypt`) |

## 仓库结构

```
qpdf-pdf-ops/                          # GitHub repo (= marketplace)
├── .claude-plugin/
│   └── marketplace.json               # marketplace 索引（列出本仓库提供的 plugin）
├── plugins/
│   └── qpdf-pdf-ops/                  # plugin 实体（独立子目录）
│       ├── .claude-plugin/
│       │   └── plugin.json            # plugin 元信息
│       └── skills/
│           └── qpdf-pdf-ops/          # skill 本体
│               ├── SKILL.md
│               ├── scripts/           # 7 个封装脚本
│               └── references/        # recipes.md + page-ranges.md
├── .github/workflows/
│   └── skill-lint.yml                 # PR/push 触发 lint + smoke test
├── bin/
│   └── skill-lint                     # 校验 SKILL.md / 引用 / 可执行权限
└── README.md
```

## 使用示例

安装并重启 Claude Code 后，触发短语包括（中英文均可）：

- "用 cover.pdf 的第 1 页替换 report.pdf 的第 3 页"
- "删除 5-7 页" / "去掉最后一页"
- "把这几个 PDF 合并成一个文件"
- "旋转第 2 页 90 度" / "把 PDF 倒序"
- "提取第 3-5 页另存为新 PDF"
- "把 PDF 拆成单页"
- "这个 PDF 有密码，帮我解开"

## 核心原理

大多数操作用一行命令完成：

```bash
qpdf PRIMARY.pdf --pages SRC RANGE ... -- OUT.pdf
```

- `PRIMARY.pdf` 提供文档级元数据（大纲、标签等）
- `--empty` 代替主文件可从零开始
- `.` 是主文件的简写
- 每个 `(文件, 范围)` 对按顺序贡献页面到输出
- 末尾的 `--` **必须保留**

详细语法见 `plugins/qpdf-pdf-ops/skills/qpdf-pdf-ops/references/recipes.md` 与 `page-ranges.md`。

## 给贡献者

```bash
# 本地 lint
./bin/skill-lint

# 也可指定单个 skill 目录
./bin/skill-lint plugins/qpdf-pdf-ops/skills/qpdf-pdf-ops
```

PR 提交时 `.github/workflows/skill-lint.yml` 会自动跑 lint + qpdf 脚本 smoke test。

## 注意事项

- 所有操作生成**新文件**，不会覆盖原始 PDF（除非显式 `--replace-input`）
- 文件路径包含中文或其他特殊字符时，shell 命令中需加引号
- 推荐使用相对旋转角度（`+90`、`-90`）而非绝对角度
- 加密 PDF 操作前先询问用户密码，不要猜测

## 友链

- [linux.do](https://linux.do/) — 技术交流社区 - **学AI，上L站！**

## 许可

MIT
