# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 双目录结构与同步规则

本仓库同时支持两种 skill 安装方式：**Claude Code plugin** 和 **skills.sh (npx skills)**。两者对 skill 文件的查找路径不同，因此维护了两份内容相同的目录：

| 目录 | 用途 | 查找方 |
|------|------|--------|
| `skills/` | **规范源（canonical source）**，供 skills.sh 发现 | `npx skills add idinging/qpdf-pdf-ops` |
| `plugin/skills/` | skill 实现，与 `skills/` 同步 | plugin 内部加载 SKILL.md |
| `plugin/commands/` | **plugin 注册入口**，Claude Code plugin 系统通过此目录发现 skill | `/plugin install` → `/reload-plugins` |

**同步规则：修改 skill 内容时，只改 `skills/`，改完后立即同步到 `plugin/skills/`：**

```bash
# 把 skills/ 的改动复制到 plugin/skills/
cp -r skills/* plugin/skills/
```

**禁止**直接修改 `plugin/skills/` 下的文件，它始终是 `skills/` 的拷贝。提交前用 diff 验证同步无遗漏：

```bash
diff -r skills plugin/skills
```

**`plugin/commands/` 是 plugin 专属目录**，没有 `skills/` 下的对应物，可直接编辑。每个 `.md` 文件是 Claude Code 发现 skill 的注册点，内容精简（frontmatter + 简要用法），运行时委托给 `skills/` 中的 SKILL.md。

## 常用命令

```bash
# 本地 lint（校验 SKILL.md 格式 + 脚本可执行 + 引用完整）
./bin/skill-lint

# Lint 单个 skill 目录
./bin/skill-lint skills/qpdf-pdf-ops

# 检查两个 skill 目录是否同步
diff -r skills plugin/skills

# 从 skills/ 同步到 plugin/skills/
cp -r skills/* plugin/skills/
```

## 架构

```
qpdf-pdf-ops/                    # GitHub repo (= marketplace 根)
├── .claude-plugin/
│   └── marketplace.json         # marketplace 索引, source 字段指向 "./plugin"
├── plugin/                      # Claude Code plugin 实体
│   ├── .claude-plugin/
│   │   └── plugin.json          # plugin 元信息（name, version, keywords）
│   ├── commands/                # ← plugin 注册入口（Claude Code 通过此目录发现 skill）
│   │   └── qpdf-pdf-ops.md      # 精简注册文件，委托给 skills/qpdf-pdf-ops/SKILL.md
│   └── skills/                  # ← skills/ 的拷贝
│       └── qpdf-pdf-ops/
│           ├── SKILL.md         # 必须与 skills/ 下的一致
│           ├── scripts/         # 7 个 shell 脚本
│           └── references/      # recipes.md + page-ranges.md
├── skills/                      # 规范源，唯一手动编辑的 skill 目录
│   └── qpdf-pdf-ops/
│       ├── SKILL.md
│       ├── scripts/
│       └── references/
├── skills.sh.json               # skills.sh 网站展示分组配置
├── bin/skill-lint               # SKILL.md 校验脚本
├── .github/workflows/
│   └── skill-lint.yml           # CI：lint + JSON 校验 + qpdf smoke test
└── README.md
```

### 关键文件说明

- **`SKILL.md`** — 前置元数据必须包含 `name`（kebab-case, ≤64字符, 与目录名一致）和 `description`（≤1024字符, 无尖括号）。skill-lint 脚本会自动校验这些规则。
- **`marketplace.json`** — `source` 字段指向 `"./plugin"`，Claude Code 据此定位 plugin 实体。
- **`plugin.json`** — version 字段在发版时需手动更新，与 marketplace 的 description/tags/keywords 保持语义一致但不要求完全相同。
- **`skills.sh.json`** — 仅影响 skills.sh 网站的展示排序，不影响 CLI 安装行为。

### SKILL.md YAML 易错点

**description 必须用双引号包裹，避免 YAML 解析失败导致 plugin 系统显示 "0 skills"。**

三种常见的 YAML 解析失败场景：

| 问题字符 | 说明 | 错误示例 |
|----------|------|----------|
| `:` 后跟空格 | YAML 将其解释为 key-value 分隔符 | `description: foo: bar` |
| `"`（ASCII 双引号） | 在未加引号字符串中表示引号区域开始/结束 | `description: "合并PDF"` |
| `#` | 被解释为注释开始 | `description: fix #1 bug` |

**正确写法：**

```yaml
# ❌ 错误 — 未加引号，包含 : 和 "
description: Lossless: merge PDFs, "合并PDF".

# ✅ 正确 — 整体用双引号包裹，内部 " 用 \" 转义
description: "Lossless: merge PDFs, \"合并PDF\"."

# ✅ 也可用单引号包裹（内部不能有单引号）
description: 'Lossless: merge PDFs.'
```

**验证 YAML 可解析：**

```bash
python3 -c "
import yaml
with open('skills/qpdf-pdf-ops/SKILL.md') as f:
    parts = f.read().split('---')
    yaml.safe_load(parts[1])
    print('YAML OK')
"
```

`./bin/skill-lint` 不检查 YAML 解析，只校验 name/description 格式规则。因此 YAML 错误需要额外验证。建议修改 SKILL.md 元数据后运行上述 Python 命令确认。

## CI

`.github/workflows/skill-lint.yml` 在 PR 和 push 到 main/master 时触发，监听 `plugin/**`、`skills/**`、`.claude-plugin/**` 变更。流程：安装 qpdf → 运行 `./bin/skill-lint` → 验证 JSON 合法性 → smoke-test 脚本。
