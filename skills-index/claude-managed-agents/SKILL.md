---
name: claude-managed-agents
description: Use when building, designing, or deploying a Claude managed agent via the Anthropic /v1/agents API — client support bots, internal tools, automation agents, any agent that needs memory, sessions, MCP tools, or persistent identity across runs.
---

# Claude Managed Agents

## Overview

Claude managed agents are persistent, named AI agents deployed via `POST /v1/agents` on the Anthropic platform. They have their own identity, system prompt, model, tool access, and (via `agent_toolset_20260401`) built-in memory and sessions — no custom infra needed.

## When to Use

- Client wants a support bot, scheduling agent, or internal tool
- Agent needs to persist across conversations (memory/sessions)
- Agent needs to call Slack, Notion, or other MCP-connected services
- You want to deploy without building a backend

## API Call Pattern

```bash
curl -X POST https://api.anthropic.com/v1/agents \
  -H "Content-Type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: managed-agents-2026-04-01" \
  -d '{...agent JSON...}'
```

**The beta header `managed-agents-2026-04-01` is required — calls fail without it.**

## Agent JSON Schema

```json
{
  "name": "string",
  "description": "string — what the agent does, shown in platform UI",
  "model": "claude-haiku-4-5 | claude-sonnet-4-6 | claude-opus-4-7",
  "system": "string — full system prompt",
  "mcp_servers": [
    { "name": "notion", "type": "url", "url": "https://mcp.notion.com/mcp" },
    { "name": "slack",  "type": "url", "url": "https://mcp.slack.com/mcp" }
  ],
  "tools": [
    { "type": "agent_toolset_20260401", "default_config": { "enabled": true } },
    {
      "type": "mcp_toolset",
      "mcp_server_name": "notion",
      "default_config": { "permission_policy": { "type": "always_allow" } }
    }
  ],
  "metadata": { "template": "string — optional tag" }
}
```

## Toolset Types

| Type | What it gives the agent |
|------|------------------------|
| `agent_toolset_20260401` | Memory, sessions, sub-agent spawning — the managed runtime |
| `mcp_toolset` | Access to one named MCP server's tools |

**Always include `agent_toolset_20260401` unless the agent is purely stateless.**

`mcp_toolset` permission policies:
- `always_allow` — agent calls tools without approval (good for automated agents)
- `ask_user` — prompts for approval per call
- `deny` — blocks the toolset

## Known Hosted MCP URLs

| Service | URL |
|---------|-----|
| Notion | `https://mcp.notion.com/mcp` |
| Slack | `https://mcp.slack.com/mcp` |
| Others | Check plugin marketplace / provider docs |

## Model Selection

| Model | Use for |
|-------|---------|
| `claude-haiku-4-5` | High-volume Q&A, support routing, simple lookups — cheapest |
| `claude-sonnet-4-6` | Reasoning + tool use, drafting, moderate complexity |
| `claude-opus-4-7` | Complex multi-step agentic tasks, research, coding agents |

## System Prompt Patterns

### Support Agent (KB + escalation)
```
You are a [role] for [business]. For each question:
1. Search [knowledge source] — quote the passage and link the source. Never paraphrase policy from memory.
2. Reply: direct answer → source link → one proactive next step.
3. If confidence < 80%, post a handoff to [escalation channel] with: full question, what you searched, what you found, best hypothesis. Tell the customer a human is taking over.

Match the customer's tone. Warm but concise. One emoji max.
```

### Web-Aware Local Business Agent
```
You are a [role] for [Business] ([website]). Help customers with [topics].
Use web_fetch to retrieve current info from [website] when relevant.
Use web_search for [supplemental info types].
Be warm, professional, concise.
Never make up [prices / availability / staff names] — acknowledge what you don't know and direct them to [contact method].
```

## Guardrail Rules (always include for client agents)

- Never fabricate prices, availability, or staff names
- When uncertain, acknowledge and redirect to human contact
- Cite sources — don't paraphrase policy from memory
- Escalate low-confidence answers rather than guessing

## Real Examples

### Mountain Edge Plumbing (web-aware, haiku)
```json
{
  "name": "Mountain Edge Plumbing Support",
  "model": "claude-haiku-4-5",
  "tools": [{ "type": "agent_toolset_20260401", "default_config": { "enabled": true } }]
}
```
Simple web-aware support agent — no MCP servers needed since it uses `web_fetch`/`web_search` from the managed toolset.

### Support Agent Template (Notion + Slack, sonnet)
```json
{
  "name": "Support agent",
  "model": "claude-sonnet-4-6",
  "mcp_servers": [
    { "name": "notion", "type": "url", "url": "https://mcp.notion.com/mcp" },
    { "name": "slack",  "type": "url", "url": "https://mcp.slack.com/mcp" }
  ],
  "tools": [
    { "type": "agent_toolset_20260401" },
    { "type": "mcp_toolset", "mcp_server_name": "notion", "default_config": { "permission_policy": { "type": "always_allow" } } },
    { "type": "mcp_toolset", "mcp_server_name": "slack",  "default_config": { "permission_policy": { "type": "always_allow" } } }
  ]
}
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing beta header | Add `anthropic-beta: managed-agents-2026-04-01` |
| `mcp_toolset` with no matching `mcp_servers` entry | `mcp_server_name` must match a name in `mcp_servers[]` |
| Skipping `agent_toolset_20260401` | Agent loses memory/sessions — add it unless intentionally stateless |
| Overpromising in system prompt | Add explicit guardrails: never fabricate, redirect unknowns |
| Using Opus for simple Q&A | Use Haiku — 5x cheaper, fast enough for support |
