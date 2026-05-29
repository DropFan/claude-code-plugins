---
name: lark-contact
version: 1.0.0
description: "飞书 / Lark 通讯录,用于按姓名 / 邮箱把员工解析成 open_id,以及按 open_id 反查员工的姓名 / 部门 / 邮箱 / 联系方式。当用户说出某人姓名而下一步需要发消息 / 加群 / 排日程时,先用本 skill 把姓名换成 ID;当输出里出现 open_id 需要展示成姓名给用户看,或用户直接询问某人的部门 / 邮箱 / 联系方式时,用本 skill 查。不负责部门树遍历、按部门列员工、组织架构图,这类需求走原生 OpenAPI。"
metadata:
  requires:
    bins: ["lark-cli"]
  cliHelp: "lark-cli contact --help"
---

<!-- cowork-exec-note -->
> **⚙️ Cowork / Claude Desktop 执行环境说明（自动注入）**
>
> 本技能依赖本地 `lark-cli`（`@larksuite/cli`，位于 `/opt/homebrew/bin/lark-cli`）及其 `~/.lark-cli` 登录态（应用密钥存于 macOS keychain）。
>
> 在 Cowork 中运行任何 `lark-cli` 命令时，**必须在本地 macOS 上执行**（使用 Desktop Commander 的 `start_process` / `interact_with_process`，或其它本地 shell 工具），**不要用隔离的 Linux 沙箱** `mcp__workspace__bash`——沙箱里没有 lark-cli、也读不到 keychain。
> 执行前确保 PATH 含 Homebrew：`export PATH="/opt/homebrew/bin:$PATH"`。
>
> （在 Claude Code 中可忽略本说明，lark-cli 在本机 shell 直接可用。）


# lark-contact

## 选哪个命令

**user 身份和 bot 身份是两条完全独立的路径**。先确定当前身份,再按下表选命令:

| 想做什么 | user 身份 | bot 身份 |
|---|---|---|
| 按姓名 / 邮箱搜员工拿 open_id | [`+search-user`](references/lark-contact-search-user.md) | 不支持 |
| 已知 open_id 取他人资料 | `+search-user --user-ids <id>` | [`+get-user --user-id <id>`](references/lark-contact-get-user.md) |
| 查看自己 | `+get-user` 或 `+search-user --user-ids me` | 不支持 |

已知 open_id 只是想发消息 / 排日程,不必经过 contact —— 直接 [`lark-im`](../lark-im/SKILL.md) / [`lark-calendar`](../lark-calendar/SKILL.md)。

## 典型场景

```bash
# 找张三给他发消息:先搜,确认 open_id,再发
lark-cli contact +search-user --query "张三" --has-chatted --as user
lark-cli im +messages-send --user-id ou_xxx --text "Hi!"
```

搜索命中多条且后续操作有副作用(发消息、邀请会议等),把候选列给用户挑;不要擅自选第一条。

## 注意事项

- **41050 / Permission denied** 受当前身份的可见范围限制(两条命令都可能遇到)。换 bot 身份或让管理员调整可见范围,细节见 [`lark-shared`](../lark-shared/SKILL.md)。
- **跨租户用户**(`is_cross_tenant=true`)多数业务字段为空字符串,这是飞书可见性规则,下游做空值兜底。
- **ID 类型**:默认 `open_id`。`+get-user` 可改 `--user-id-type union_id|user_id`;`+search-user` 只接受 `open_id`。

## 不在本 skill 范围

- 发消息 / 查聊天记录 → [`lark-im`](../lark-im/SKILL.md)
- 排日程 / 邀请会议 → [`lark-calendar`](../lark-calendar/SKILL.md)
- 部门树 / 按部门列员工 / 组织架构 ,通过 [`lark-openapi-explorer`](../lark-openapi-explorer/SKILL.md) 查找原生接口
