# MCP Export Guide

## Overview

chat-saver supports exporting conversations to external platforms via MCP (Model Context Protocol) servers.

**This plugin does not ship pre-configured MCP servers.** There are two ways to get started:

1. **Quick setup**: Run `/chat-saver:setup` and select the MCP export option — the wizard will generate the configuration for you
2. **Use existing servers**: If you already have Notion/Feishu MCP servers configured in your environment, chat-saver will auto-detect them

Currently supported platforms:

- **Notion** — via `@notionhq/notion-mcp-server`
- **Feishu (飞书)** — via Feishu/Lark MCP server

## Notion Setup

### Prerequisites

1. A Notion account with API access
2. A Notion integration token

### Getting NOTION_TOKEN

1. Go to [Notion Integrations](https://www.notion.so/my-integrations)
2. Click "New integration"
3. Name it (e.g., "claude-code")
4. Select the workspace to use
5. Copy the "Internal Integration Secret"
6. Share the target Notion page/database with the integration

### Configuration

Add the Notion MCP server to your **project** `.mcp.json` or **global** `~/.claude/.mcp.json`:

```json
{
  "mcpServers": {
    "notion-mcp": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@notionhq/notion-mcp-server"],
      "env": {
        "NOTION_TOKEN": "ntn_your_token_here"
      }
    }
  }
}
```

If you already have a Notion MCP server configured (under any name), chat-saver will auto-detect it — no additional setup needed.

### Usage

When exporting, chat-saver will:
1. Detect available Notion MCP tools (matching `mcp__*notion*`)
2. Generate conversation content in Markdown
3. Create a new Notion page with the conversation title
4. Add the Markdown content as page blocks
5. Return the page URL

## Feishu (飞书) Setup

### Prerequisites

1. A Feishu account with developer access
2. A running Feishu MCP server (SSE or stdio)

### Configuration

Add the Feishu MCP server to your `.mcp.json`:

**SSE mode:**
```json
{
  "mcpServers": {
    "feishu-mcp": {
      "type": "sse",
      "url": "http://localhost:8090/sse"
    }
  }
}
```

**stdio mode (if available):**
```json
{
  "mcpServers": {
    "feishu-mcp": {
      "type": "stdio",
      "command": "your-feishu-mcp-binary",
      "args": []
    }
  }
}
```

If you already have a Feishu or Lark MCP server configured, chat-saver will auto-detect it.

### Usage

When exporting, chat-saver will:
1. Detect available Feishu/Lark MCP tools (matching `mcp__*feishu*` or `mcp__*lark*`)
2. Generate conversation content in Markdown
3. Create a new Feishu document with the conversation title
4. Add the Markdown content as document body
5. Return the document URL

## Auto-Detection Logic

chat-saver detects MCP servers by matching tool name patterns:

| Platform | Tool pattern |
|----------|-------------|
| Notion | `mcp__*notion*` |
| Feishu | `mcp__*feishu*` or `mcp__*lark*` |

This means:
- The MCP server can be named anything (e.g., `my-notion`, `notion-mcp`, `notion`)
- It can be configured at project or global level
- No duplicate server instances — chat-saver reuses your existing setup

## Error Handling

### MCP Server Not Available

If no matching MCP tools are detected:

```
No <platform> MCP server detected in your environment.

To set up:
1. Add the MCP server to your .mcp.json (project or ~/.claude/.mcp.json)
2. <platform-specific instructions>

See the chat-saver plugin's mcp-export-guide.md for details.

Would you like to save locally instead?
```

### Authentication Failure

If the token is invalid or expired:

```
Authentication failed for <platform>.
Please check your token in .mcp.json.
```

### Network Error

If the MCP server is unreachable:

```
Cannot connect to <platform> MCP server.
Please verify the server is running and accessible.
```
