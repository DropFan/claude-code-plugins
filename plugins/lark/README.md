# lark

Feishu/Lark skills for Claude Code and Cowork, driven by the local `lark-cli` (`@larksuite/cli`). Mirrors the upstream lark-cli skill set: IM, Docs, Base, Sheets, Calendar, Drive, Wiki, Task, OKR, VC, Mail, and more — see the full list below.

## Installation

1. Install and authenticate the CLI:

   ```bash
   npm i -g @larksuite/cli
   lark-cli config init
   lark-cli auth login
   ```

2. Install the plugin from this marketplace (inside Claude Code):

   ```
   /plugin marketplace add DropFan/claude-code-plugins
   /plugin install lark@tiger-plugins
   ```

In Cowork, run lark-cli on the local Mac (e.g. via Desktop Commander), not the Linux sandbox — each SKILL.md carries an auto-injected note with details.

## Skills

<!-- SKILLS_LIST_START -->
| Skill | Description |
| --- | --- |
| [lark-approval](skills/lark-approval/SKILL.md) | 飞书审批：查询和处理审批待办/已办/实例，搜索可发起审批定义、查看定义详情并发起原生审批实例。 |
| [lark-apps](skills/lark-apps/SKILL.md) | 妙搭（Spark/Miaoda）应用开发与托管：应用创建、本地全栈开发、云端生成迭代、创意设计（UI mockup / 可交互原型 / 线框图 / 落地页 / 仪表盘 / 幻灯片 deck / 视觉探索）、AI相关能力和飞书平台能力或者其他外部能力集成、日志/Trace/监控指标/PV/UV 查询、环境变量管理、应用角色与成员管理、自动化触发器（定时/记录变更/Webhook/飞书审批）。 |
| [lark-attendance](skills/lark-attendance/SKILL.md) | 飞书考勤打卡：查询自己的考勤打卡记录 |
| [lark-base](skills/lark-base/SKILL.md) | 飞书多维表格（Base）操作：建表、字段、记录、视图、统计、公式/lookup、表单、仪表盘、workflow、角色权限；遇到 Base/多维表格/bitable 或 /base/ 链接时使用。 |
| [lark-calendar](skills/lark-calendar/SKILL.md) | 飞书日历：管理日历日程和会议室。 |
| [lark-contact](skills/lark-contact/SKILL.md) | 飞书 / Lark 通讯录:按姓名 / 邮箱解析成 open_id,或按 open_id 反查姓名 / 部门 / 邮箱 / 联系方式 / 个人状态 / 签名。 |
| [lark-doc](skills/lark-doc/SKILL.md) | 飞书云文档（Docx / Wiki 文档）：读取和编辑飞书文档内容。 |
| [lark-drive](skills/lark-drive/SKILL.md) | 飞书云空间（云盘/云存储）：管理 Drive 文件和文件夹，包含上传/下载、创建文件夹、复制/移动/删除、查看元数据、评论/权限/订阅、标题、版本、飞书文档密级标签（secure labels）和本地文件导入。 |
| [lark-event](skills/lark-event/SKILL.md) | Lark/Feishu real-time event listening / subscribing / consuming: stream events as NDJSON via `lark-cli event consume <EventKey>` (covers IM messages/reactions/chat changes, Approval status changes, Task updates, VC meeting started/joined/ended, Minutes generated, Whiteboard updated, etc.). |
| [lark-im](skills/lark-im/SKILL.md) | 飞书即时通讯：收发消息和管理群聊。 |
| [lark-mail](skills/lark-mail/SKILL.md) | 飞书邮箱：Use when user mentions 起草邮件、写邮件、草稿、发送/回复/转发邮件、查阅邮件、看邮件、搜索邮件、邮件文件夹、邮件标签、邮件联系人、监听新邮件、邮件收信规则等；use for mail/email intent only. |
| [lark-markdown](skills/lark-markdown/SKILL.md) | 飞书 Markdown：查看、创建、上传、编辑和比较 Markdown 文件。 |
| [lark-minutes](skills/lark-minutes/SKILL.md) | 飞书妙记：搜索妙记、查看妙记基础信息、下载/上传音视频、读取或编辑妙记的产物内容、改标题、替换说话人/关键词、申请妙记查看/编辑权限。 |
| [lark-note](skills/lark-note/SKILL.md) | 飞书会议纪要（Note）直查：已知 note_id 时查询纪要详情、展示类型、关联文档 token，并读取 unified 原始逐字记录。 |
| [lark-okr](skills/lark-okr/SKILL.md) | 飞书 OKR：管理目标与关键结果。 |
| [lark-openapi-explorer](skills/lark-openapi-explorer/SKILL.md) | 飞书/Lark 原生 OpenAPI 探索：从官方文档库中挖掘未经 CLI 封装的原生 OpenAPI 接口。 |
| [lark-shared](skills/lark-shared/SKILL.md) | Use for lark-cli setup/auth tasks: auth login/status/logout, user vs bot identity, business-domain permissions (--domain, including all/docs/drive), missing scopes, revoking authorization, or handling _notice JSON. |
| [lark-sheets](skills/lark-sheets/SKILL.md) | 飞书电子表格：创建和操作电子表格。 |
| [lark-skill-maker](skills/lark-skill-maker/SKILL.md) | 创建 lark-cli 的自定义 Skill。 |
| [lark-slides](skills/lark-slides/SKILL.md) | 飞书幻灯片：创建和编辑幻灯片。 |
| [lark-task](skills/lark-task/SKILL.md) | 飞书任务：管理任务、清单和任务智能体。 |
| [lark-vc](skills/lark-vc/SKILL.md) | 飞书视频会议：搜索历史会议记录、查询会议纪要（总结/待办/章节/逐字稿）、查询参会人快照。 |
| [lark-vc-agent](skills/lark-vc-agent/SKILL.md) | 飞书视频会议会中能力：用于让应用机器人真实加入或离开正在进行的会议，并读取当前身份可见的会中事件、发送会中文本消息或会中表情。 |
| [lark-whiteboard](skills/lark-whiteboard/SKILL.md) | 飞书画板：查询和编辑飞书云文档中的画板。 |
| [lark-wiki](skills/lark-wiki/SKILL.md) | 飞书知识库：管理知识空间、空间成员和文档节点。 |
| [lark-workflow-meeting-summary](skills/lark-workflow-meeting-summary/SKILL.md) | 会议纪要整理工作流：汇总指定时间范围内的会议纪要并生成结构化报告。 |
| [lark-workflow-standup-report](skills/lark-workflow-standup-report/SKILL.md) | 日程待办摘要：编排 calendar +agenda 和 task +get-my-tasks，生成指定日期的日程与未完成任务摘要。 |
<!-- SKILLS_LIST_END -->

## Syncing with upstream

Skill content is copied verbatim from the upstream `larksuite/cli` skills by `scripts/lark-rebuild.py` (in the repository root, not shipped with the plugin):

1. `npx skills add larksuite/cli -g -y` — refresh the upstream skills in `~/.agents/skills`
2. `python3 scripts/lark-rebuild.py [--version X.Y.Z]` — re-copy the skills, inject the Cowork note, regenerate the table above, update the plugin version, and run `scripts/sync-plugins.sh` to propagate the metadata to `marketplace.json` and the root README
3. `git add plugins/lark .claude-plugin/marketplace.json README.md`, then commit

By convention the plugin version follows the `@larksuite/cli` release it was synced from — pass `--version` to keep them aligned; without it the patch version is bumped by one.

Note: local edits to files under `skills/` are overwritten by the next rebuild; fixes that must persist belong in the upstream repository.
