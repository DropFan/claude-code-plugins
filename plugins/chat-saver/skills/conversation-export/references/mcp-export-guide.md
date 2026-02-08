# MCP Export Guide

## Overview

chat-saver supports exporting conversations to external platforms via MCP (Model Context Protocol) servers. Currently supported platforms:

- **Notion** — via `@notionhq/notion-mcp-server`
- **Feishu (飞书)** — via a local SSE-based MCP server

## Notion Setup

### Prerequisites

1. A Notion account with API access
2. A Notion integration token

### Getting NOTION_TOKEN

1. Go to [Notion Integrations](https://www.notion.so/my-integrations)
2. Click "New integration"
3. Name it (e.g., "chat-saver")
4. Select the workspace to use
5. Copy the "Internal Integration Secret"
6. Share the target Notion page/database with the integration

### Configuration

Edit `.mcp.json` in the chat-saver plugin directory and set the `NOTION_TOKEN`:

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

### Usage

The Notion MCP server provides tools to:
- Create new pages in a workspace
- Add content blocks (text, code, headings, etc.)
- Search existing pages

When exporting, chat-saver will:
1. Generate conversation content in Markdown
2. Create a new Notion page with the conversation title
3. Add the Markdown content as page blocks
4. Return the page URL

## Feishu (飞书) Setup

### Prerequisites

1. A Feishu account with developer access
2. A running Feishu MCP SSE server

### Configuration

The Feishu MCP server uses SSE (Server-Sent Events) protocol. Start the server locally, then configure in `.mcp.json`:

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

### Usage

The Feishu MCP server provides tools to:
- Create new documents in a space
- Add rich text content
- Manage document permissions

When exporting, chat-saver will:
1. Generate conversation content in Markdown
2. Create a new Feishu document with the conversation title
3. Add the Markdown content as document body
4. Return the document URL

## General Export Flow

Regardless of the target platform, the export process follows the same pattern:

1. **Content Generation** — Always generate Markdown first as the intermediate format
2. **Platform Adaptation** — The MCP tools handle converting Markdown to the platform's native format
3. **Metadata** — Include title (`Conversation: <topic> — <date>`), date, and project info
4. **Error Handling** — If MCP is unavailable, offer to save locally instead

## Error Handling

### MCP Server Not Available

If the MCP server is not configured or not running:

```
The <platform> MCP server is not available.

To set up:
1. Edit .mcp.json in the chat-saver plugin directory
2. <platform-specific instructions>

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
