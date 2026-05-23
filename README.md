# qpdf PDF 操作 Skill

基于 [qpdf](https://qpdf.readthedocs.io) 的 Claude Code skill，提供**无损**的 PDF 页面级操作 —— 不重新渲染、不栅格化，保留原始内容流。

## 功能概览

| 操作 | 说明 |
|------|------|
| 替换页面 | 用另一个 PDF 的某一页替换当前 PDF 的指定页 |
| 提取页面 | 提取指定页码范围另存为新 PDF |
| 删除页面 | 删除指定页面（支持排除语法） |
| 插入页面 | 在指定位置插入另一个 PDF 的页面 |
| 合并 PDF | 将多个 PDF 拼接为一个 |
| 拆分 PDF | 按页拆分（每 N 页一个文件） |
| 旋转页面 | 支持相对角度旋转（+90/-90/180），可指定范围 |
| 重排页面 | 倒序、移动页面位置等 |
| PDF 信息 | 查看页数、加密状态、结构完整性检查 |

## 安装

确保系统已安装 qpdf 命令行工具：

```bash
# Debian/Ubuntu/WSL
sudo apt-get update && sudo apt-get install -y qpdf

# Fedora/RHEL
sudo dnf install -y qpdf

# Arch
sudo pacman -S qpdf

# macOS (Homebrew)
brew install qpdf

# Windows (winget)
winget install --id QPDF.QPDF -e
```

## Skill 结构

```
qpdf-pdf-ops/
├── SKILL.md                    # Skill 主文件
├── scripts/
│   ├── check_qpdf.sh           # 检测 qpdf 是否安装
│   ├── pdf_info.sh             # 查看 PDF 基本信息
│   └── replace_page.sh         # 替换单页的封装脚本
└── references/
    ├── recipes.md              # 常用操作配方（含示例与边缘情况）
    └── page-ranges.md          # qpdf 页码范围语法参考
```

## 使用示例

触发该 skill 后，Claude Code 将根据自然语言指令执行对应操作：

- "用 cover.pdf 的第 1 页替换 report.pdf 的第 3 页"
- "删除 5-7 页"
- "把这几个 PDF 合并成一个文件"
- "旋转第 2 页 90 度"
- "提取第 3-5 页另存为新 PDF"
- "把 PDF 拆成单页"

## 核心原理

大多数操作用一行命令即可完成：

```bash
qpdf PRIMARY.pdf --pages SRC RANGE ... -- OUT.pdf
```

- `PRIMARY.pdf` 提供文档级元数据（大纲、标签等）
- `--empty` 代替主文件可从零开始
- `.` 是主文件的简写
- 每个 `(文件, 范围)` 对按顺序贡献页面到输出
- 末尾的 `--` **必须保留**

详细语法见 `references/recipes.md` 和 `references/page-ranges.md`。

## 注意事项

- 所有操作生成**新文件**，不会覆盖原始 PDF（除非显式使用 `--replace-input`）
- 文件路径包含中文或其他特殊字符时，shell 命令中需要加引号
- 推荐使用相对旋转角度（`+90`、`-90`）而非绝对角度

## 友链

- [linux.do](https://linux.do/) — 技术交流社区

## 许可

MIT
