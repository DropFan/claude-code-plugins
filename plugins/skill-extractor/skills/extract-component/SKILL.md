---
name: Extract Component
description: This skill should be used when the user asks to "extract skill", "extract a skill", "save as skill", "create skill from conversation", "extract command", "generate command", "save as command", "extract agent", "generate agent", "save as agent", "extract pattern", "extract reusable pattern", "summarize as skill", "turn this into a skill", "make this a command", "package this as", "save this workflow", "distill this pattern", "提取技能", "提炼模式", "总结为 skill", "保存为技能", "生成 command", "生成命令", "提取为命令", "提取 agent", "生成 agent", "保存为 agent", "把这个变成技能", "把这个提炼出来", "保存这个工作流", "提取可复用模式", or wants to extract reusable components (skills, commands, agents) from the current conversation history.
version: 0.1.0
---

# Extract Component

## Overview

Analyze the current conversation history and extract reusable patterns into Claude Code components — Skills, Commands, or Agents. This skill identifies valuable methodology, operation sequences, and decision workflows from the conversation and generates properly formatted component files.

## Intent Classification

When the user triggers this skill, determine the extraction intent:

1. **Explicit type** — User specifies what they want (e.g., "extract a skill", "make this a command")
2. **Auto-detect** — User wants extraction but hasn't specified the type (e.g., "extract pattern", "save this workflow")

### Component Type Guidelines

- **Skill** — A methodology, technique, or approach for solving a category of problems. Skills describe *how to think about* a problem, with progressive disclosure of details. Best for: debugging strategies, review processes, design methodologies, domain-specific expertise.
- **Command** — A concrete sequence of operations that can be executed with parameters. Commands are action-oriented with clear inputs and outputs. Best for: build workflows, deployment steps, data processing pipelines, repetitive multi-step tasks.
- **Agent** — An autonomous workflow that requires decision-making, branching logic, and tool usage. Agents operate independently within defined boundaries. Best for: code review workflows, test generation, documentation creation, complex analysis tasks.

## Execution

Route to the `/skill-extractor:extract` command with the user's intent:

1. If the user specified a type, pass it as an argument (e.g., `/skill-extractor:extract skill`)
2. If auto-detect, pass no type argument — the command will analyze and recommend

Invoke the command: `/skill-extractor:extract $ARGUMENTS`
