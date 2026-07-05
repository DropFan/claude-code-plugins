---
name: lark-whiteboard
version: 1.0.0
description: >
  飞书画板：查询和编辑飞书云文档中的画板。支持导出画板为预览图片、导出原始节点结构、使用多种格式更新画板内容。
  当用户需要查看画板内容、导出画板图片、编辑画板时使用此 skill。不负责：飞书云文档内容编辑（lark-doc）、文档内嵌电子表格/Base（lark-sheets / lark-base）。
metadata:
  requires:
    bins: ["lark-cli"]
  cliHelp: "lark-cli whiteboard --help"
---

<!-- cowork-exec-note -->
> **⚙️ Cowork / Claude Desktop 执行环境说明（自动注入）**
>
> 本技能依赖本地 `lark-cli`（`@larksuite/cli`，可用 `command -v lark-cli` 定位）及其 `~/.lark-cli` 登录态（应用密钥存于 macOS keychain）。
>
> 在 Cowork 中运行任何 `lark-cli` 命令时，**必须在本地 macOS 上执行**（使用 Desktop Commander 的 `start_process` / `interact_with_process`，或其它本地 shell 工具），**不要用隔离的 Linux 沙箱** `mcp__workspace__bash`——沙箱里没有 lark-cli、也读不到 keychain。
> 执行前确保 npm 全局 bin 目录（`npm prefix -g` 输出目录下的 `bin`）在 PATH 中。
>
> （在 Claude Code 中可忽略本说明，lark-cli 在本机 shell 直接可用。）


> [!IMPORTANT]
> - 运行 `lark-cli --version`，确认可用，无需询问用户。
> - 运行 `npx -y @larksuite/whiteboard-cli@^0.2.12 -v`，确认可用，无需询问用户。

**CRITICAL — 开始前 MUST 先用 Read 工具读取 [`../lark-shared/SKILL.md`](../lark-shared/SKILL.md)，其中包含认证、权限处理**

---

## 快速决策

**身份**：画板操作默认使用 `--as user`。仅当需要以应用身份上传时使用 `--as bot`。

| 用户需求                                    | 行动                                                                                            |
|-----------------------------------------|-----------------------------------------------------------------------------------------------|
| 查看画板内容 / 导出图片 / 导出 SVG 矢量图 | [`+query --output_as image/svg`](references/lark-whiteboard-query.md)                             |
| 获取画板的 Mermaid/PlantUML 代码               | [`+query --output_as code`](references/lark-whiteboard-query.md)                              |
| 检查画板是否由代码绘制                             | [`+query --output_as code`](references/lark-whiteboard-query.md)                              |
| 仅微调节点文字/颜色                         | `+query --output_as raw` → 手动改 JSON → `+update --input_format raw`                            |
| 用户**已提供** Mermaid/PlantUML/SVG 代码，或明确指定用该格式 | 自己生成/使用代码 → [`+update --input_format mermaid/plantuml/svg`](references/lark-whiteboard-update.md) |
| 新建/创作复杂图表（架构/流程/组织等）                    | → **[§ 创作 Workflow](references/lark-whiteboard-workflow.md#创作-workflow)**                     |
| 修改/重绘已有画板                               | → **[§ 修改 Workflow](references/lark-whiteboard-workflow.md#修改-workflow)**                     |

## Shortcuts

| Shortcut | 说明 |
|---|---|
| [`+query`](references/lark-whiteboard-query.md) | 查询画板，导出为预览图片、SVG 矢量图、代码或原始节点结构。 |
| [`+update`](references/lark-whiteboard-update.md) | 更新画板，支持 PlantUML、Mermaid、SVG 或 OpenAPI 原生格式 |

---

## 不在本 skill 范围
- 文档内容编辑 → lark-doc [lark-doc](../lark-doc/SKILL.md)
- 在文档中创建画板 → [lark-doc-whiteboard.md](../lark-doc/references/lark-doc-whiteboard.md)
- 表格 / Base 操作 → [lark-sheets](../lark-sheets/SKILL.md) / [lark-base](../lark-base/SKILL.md)
