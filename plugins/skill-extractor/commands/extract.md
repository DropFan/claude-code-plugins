---
allowed-tools: Bash(pwd:*), Bash(date:*), Bash(mkdir:*), Bash(ls:*), Write, Read, Glob, AskUserQuestion
description: Analyze conversation history and extract reusable skills, commands, or agents
argument-hint: "[type: skill|command|agent|auto] [--name <component-name>]"
---

## Context

- Working directory: !`pwd`
- Current date: !`date '+%Y-%m-%d %H:%M'`

## Task

Analyze the current conversation history and extract reusable patterns into Claude Code component files (Skill, Command, or Agent).

**User arguments:** $ARGUMENTS

### Step 0: Load Configuration

1. Use the Read tool to check if `.claude/skill-extractor.local.md` exists in the project root
2. If it exists, parse the YAML frontmatter between `---` markers to extract:
   - `default_output_dir` — default save directory (default: `~/.claude/skills/`)
   - `default_type` — default component type: `auto`, `skill`, `command`, or `agent` (default: `auto`)
3. If the file does not exist, silently use built-in defaults (no error)
4. Settings are overridden by explicit command arguments

### Step 1: Analyze Conversation History

Scan the complete conversation history and identify extractable patterns. Look for:

**Potential Skills** (methodology / technique):
- A debugging approach that involved multiple analysis steps
- A review or evaluation methodology with specific criteria
- A problem-solving strategy with decision points
- Domain-specific knowledge applied to solve a problem
- A multi-step reasoning process that could be reused

**Potential Commands** (executable operation sequence):
- A repeated sequence of tool calls or shell commands
- A data processing or transformation pipeline
- A build, test, or deployment workflow
- A file generation or scaffolding process with clear parameters

**Potential Agents** (autonomous decision workflow):
- A complex analysis that required branching decisions
- A multi-file investigation with dynamic scope
- A code generation task requiring context-aware decisions
- A review or audit workflow with autonomous judgment

For each identified pattern, produce a candidate with:
- **Name** — Descriptive kebab-case name (e.g., `debug-memory-leak`, `scaffold-react-component`)
- **Type suggestion** — Skill, Command, or Agent
- **Summary** — 1-2 sentence description of what the pattern does
- **Key content** — The core steps, logic, or methodology to preserve

If no extractable patterns are found, inform the user and exit gracefully.

### Step 2: User Confirmation

Present the candidate list to the user and let them choose what to extract.

**2a: Select candidate**

If multiple candidates are found, use AskUserQuestion to let the user choose which pattern(s) to extract. If only one candidate is found, proceed with it (confirm with the user).

**2b: Confirm component type**

If $ARGUMENTS specifies a type (`skill`, `command`, or `agent`), use that type directly.

Otherwise, use AskUserQuestion to let the user confirm or override the suggested type:
- **Skill** — Reusable methodology or technique (SKILL.md with progressive disclosure)
- **Command** — Executable operation with parameters (command.md with allowed-tools)
- **Agent** — Autonomous workflow with decision-making (agent.md with tools and model)

**2c: Confirm name**

If `--name` is provided in $ARGUMENTS, use it. Otherwise, suggest the candidate name and let the user confirm or provide an alternative.

**2d: Choose save location**

Use AskUserQuestion to let the user choose where to save:
- **Personal global skills** — `~/.claude/skills/` (available in all projects)
- **Personal global commands** — `~/.claude/commands/` (available in all projects)
- **Project-local** — `.claude/` directory in current project (project-specific)
- **Plugin directory** — A specific plugin's directory (for plugin development)

If the user chooses "Plugin directory", ask for the plugin path or auto-detect from the current working directory.

### Step 3: Generate Component File

Based on the confirmed type, generate the component file following Claude Code's expected formats.

#### For Skill type:

Generate `<name>/SKILL.md` with this structure:

```markdown
---
name: <Display Name>
description: <CSO trigger description — list trigger phrases, NOT a workflow summary>
version: 0.1.0
---

# <Display Name>

## Overview

<1-2 paragraph description of what this skill does and when to use it>

## <Core Section 1>

<Extracted methodology, steps, criteria, or knowledge>

## <Core Section 2>

<Additional details, examples, edge cases>
```

**Critical: The `description` field must follow CSO principles** — it lists trigger phrases that should activate this skill (e.g., "Use when the user asks to..."), NOT a summary of the workflow. Think of it as a matching pattern.

#### For Command type:

Generate `<name>.md` with this structure:

```markdown
---
allowed-tools: <comma-separated list of tools this command needs>
description: <Brief one-line description of what the command does>
argument-hint: "<expected arguments format>"
---

## Context

- Working directory: !`pwd`
- Current date: !`date '+%Y-%m-%d %H:%M'`

## Task

<Description of what this command does>

**User arguments:** $ARGUMENTS

### Step 1: <First Step Name>

<Step details extracted from conversation>

### Step 2: <Second Step Name>

<Step details>
```

**For `allowed-tools`**: Only include tools that the command actually needs. Common tools:
- `Bash(pwd:*), Bash(date:*)` — Almost always needed for context
- `Read, Write` — File operations
- `Glob, Grep` — Search operations
- `AskUserQuestion` — User interaction
- `Bash(mkdir:*), Bash(ls:*)` — Directory operations

#### For Agent type:

Generate `<name>.md` with this structure:

```markdown
---
name: <Display Name>
description: <When this agent should be used — trigger conditions>
model: sonnet
color: <choose: blue|green|yellow|orange|red|purple|cyan|magenta>
tools: <comma-separated list of tools>
---

# <Display Name>

## Role

<What this agent does and its expertise>

## Process

### Step 1: <Phase Name>

<Instructions for this phase>

### Step 2: <Phase Name>

<Instructions>

## Output

<What the agent should return to the caller>
```

### Step 4: Preview and Save

**4a: Preview**

Display the complete generated file content to the user for review. Show:
- File type and name
- Target save path
- Full file content

**4b: User approval**

Use AskUserQuestion to confirm:
- **Save as-is** — Write the file
- **Edit first** — Let the user suggest modifications, then regenerate
- **Cancel** — Abort without saving

**4c: Write file**

1. Determine the full save path based on type and location:
   - Skill: `<location>/skills/<name>/SKILL.md` or `<location>/<name>/SKILL.md`
   - Command: `<location>/commands/<name>.md` or `<location>/<name>.md`
   - Agent: `<location>/agents/<name>.md` or `<location>/<name>.md`

2. Create parent directories if needed:
   ```bash
   mkdir -p <parent_directory>
   ```

3. Check if the file already exists. If so, warn and ask whether to overwrite.

4. Write the file using the Write tool.

**4d: Report**

Report the result:

```
Component extracted!

  Type: <Skill|Command|Agent>
  Name: <component-name>
  File: <absolute-path>

Usage:
  <usage instructions based on type and location>
```

Usage instructions by location:
- **~/.claude/skills/**: "Available globally. Claude will auto-discover this skill."
- **~/.claude/commands/**: "Available globally. Use with `/<command-name>`."
- **.claude/**: "Available in this project. Claude will auto-discover when working here."
- **Plugin directory**: "Available when the plugin is installed. Use with `/<plugin>:<command>`."
