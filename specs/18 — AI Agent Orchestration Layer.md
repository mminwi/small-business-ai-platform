## 1. High‑level architecture

## 1.1 Three‑tier agent layout

- Tier 1 – Orchestrator agent
  - Receives user/system goals (e.g., “prepare a quote”, “analyze last week’s tickets”).
  - Performs planning, selects which module coordinators to invoke, sequences them, aggregates results, and enforces global policies (auth, safety, logging).
- Tier 2 – Module coordinator agents
  - One per product module: CRM, Inventory, Projects, Help Desk, Scheduling, Billing, etc.
  - Translate high‑level intents into concrete tool calls, database queries, or sub‑tasks for task agents within that module.
- Tier 3 – Task agents
  - Single‑responsibility agents: “parse_email_to_ticket”, “generate_followup_email”, “summarize_inventory_discrepancies”, etc.
  - Typically single‑call or short‑loop agents with strongly typed JSON I/O.

Logical services around this:

- LLM Gateway: Thin service that wraps Claude API, including model selection, temperature, tool definitions, and logging of prompts/responses.
- Task Router: Receives orchestration requests, invokes orchestrator agent, manages queues and message buses.
- Agent Registry: Catalog of agents (name, version, capabilities, schemas, prompts).
- State & Context Store: DB + object storage for task states, artifacts, conversation logs, Markdown specs, and JSON traces.
- Tool Layer: Your existing microservices/module APIs exposed to Claude as tools (function‑calling).

Illustrative logical diagram (text):

- Client (UI / API) → Task Router → Orchestrator Agent (Claude)
- Orchestrator ↔ Module Coordinators (Claude with different prompts/tools)
- Module Coordinators ↔ Task Agents (Claude with narrower tools/contexts)
- All Agents ↔ Tool Layer (DB, services, external APIs)
- All steps log to State Store and use Message Bus for async tasks.

## 2. Orchestration patterns

## 2.1 Supervisor–worker

Use this for most business workflows (estimates, tickets, CRM flows).

- Orchestrator:
  - Decomposes goal into sub‑tasks.
  - Assigns each sub‑task to a module coordinator.
  - Maintains global plan and verifies outputs before marking workflow complete.
- Coordinators:
  - Further decompose into tasks, call tools or task agents, enforce module‑local rules.
- Workers (task agents):
  - Produce strictly structured JSON outputs; have no cross‑module visibility.

Key rules:

- One orchestrator per workflow instance.
- Coordinators should manage 3–10 task agents each, not more.
- Orchestrator is responsible for detecting derailment (“off‑topic”, invalid JSON) and re‑prompting or re‑issuing tasks.

Good fits: multi‑step quoting, onboarding flows, multi‑module reports, cross‑module data cleanup.

## 2.2 Pipeline pattern

Use when work is naturally linear and data flows one‑way.

- Example pipeline:
  - Ingest → Normalize → Enrich → Decide → Persist.
- Each stage is an agent or a fixed tool call.
- State is passed as a single JSON “payload” with explicit version.

Good fits:

- Parsing raw email to ticket, auto‑reply, then posting to Help Desk.
- Periodic batch jobs (weekly metrics, daily summaries).

## 2.3 Event‑driven pattern

Use for background and reactive operations.

- Core idea: agents subscribe to events on a bus (e.g., “ticket.created”, “inventory.low_stock”), and the orchestrator (or an Event Coordinator agent) decides when to invoke them.
- Avoid having each agent independently listen to events; keep one Event Coordinator that filters and maps events to workflows.

Good fits:

- Automatically draft responses on new tickets.
- Trigger follow‑up tasks when project milestones are reached.
- Cross‑module hygiene like deduping contacts after imports.

## 3. Data structures and schemas

You want consistent message envelopes plus well‑typed payloads.

## 3.1 Task envelope schema

All inter‑agent messages use a standard envelope:

```
json{
  "$schema": "https://schema.yourapp.com/agent-message-envelope-v1.json",
  "message_id": "uuid",
  "parent_message_id": "uuid|null",
  "correlation_id": "workflow-uuid",
  "timestamp": "2026-02-18T12:04:00Z",
  "from_agent": "orchestrator.global.v1",
  "to_agent": "crm.coordinator.v1",
  "intent": "prepare_quote",
  "status": "pending",
  "priority": "normal",
  "payload_version": "1.0.0",
  "payload": {
    "type": "prepare_quote_request",
    "data": {
      "customer_id": "cust_123",
      "project_summary_md_path": "s3://specs/projects/abc123.md",
      "constraints": {
        "max_discount_pct": 10,
        "currency": "USD"
      }
    }
  },
  "context_refs": [
    {
      "kind": "markdown_spec",
      "uri": "s3://agents/orchestrator/global_spec_v3.md"
    },
    {
      "kind": "conversation_log",
      "uri": "s3://logs/conversations/conv_789.jsonl"
    }
  ],
  "trace": {
    "workflow_name": "quote_generation",
    "step": "crm_prepare_quote",
    "attempt": 1
  }
}
```

Notes:

- `correlation_id` ties all messages in one workflow.
- `parent_message_id` lets you reconstruct a tree (or DAG) of calls.
- `context_refs` are URIs to Markdown docs, previous messages, or tool outputs rather than inlining everything.

## 3.2 Task queue record schema

For a DB‑backed task queue (e.g., Postgres):

```
json{
  "$schema": "https://schema.yourapp.com/task-queue-record-v1.json",
  "task_id": "uuid",
  "queue_name": "orchestrator.incoming",
  "created_at": "2026-02-18T12:04:00Z",
  "run_at": "2026-02-18T12:04:05Z",
  "locked_at": null,
  "locked_by": null,
  "status": "pending",
  "attempt": 0,
  "max_attempts": 3,
  "message_envelope": { /* envelope as above */ },
  "last_error": null
}
```

This lets you support:

- Delayed tasks (`run_at`).
- Retries with backoff (increment `attempt`, calculate new `run_at`).
- Different queues per tier (e.g., `orchestrator.incoming`, `crm.coordinator`, `helpdesk.tasks`).

## 3.3 Inter‑agent communication payloads

Define separate JSON Schemas per intent, all versioned.

Example: `prepare_quote_request`:

```
json{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://schema.yourapp.com/payloads/prepare-quote-request-v1.json",
  "type": "object",
  "required": ["customer_id", "project_summary_md_path"],
  "properties": {
    "customer_id": { "type": "string" },
    "project_summary_md_path": { "type": "string", "format": "uri" },
    "constraints": {
      "type": "object",
      "properties": {
        "max_discount_pct": { "type": "number" },
        "currency": { "type": "string" }
      },
      "additionalProperties": false
    }
  },
  "additionalProperties": false
}
```

Use the same style for:

- `prepare_quote_result`
- `ticket_summarization_request/result`
- `inventory_check_request/result`, etc.

JSON Schema is well supported and works nicely with tool definitions and validation.

## 3.4 Result aggregation structures

Orchestrator’s internal aggregation object for a workflow:

```
json{
  "workflow_id": "workflow-uuid",
  "goal": "prepare_customer_quote",
  "status": "in_progress",
  "steps": [
    {
      "step_id": "step-1",
      "name": "fetch_customer_context",
      "agent": "crm.coordinator.v1",
      "intent": "get_customer_summary",
      "input_payload_ref": "s3://payloads/workflow-uuid/step-1-input.json",
      "output_payload_ref": "s3://payloads/workflow-uuid/step-1-output.json",
      "status": "completed"
    },
    {
      "step_id": "step-2",
      "name": "estimate_labor",
      "agent": "projects.coordinator.v1",
      "intent": "estimate_labor_for_scope",
      "status": "pending"
    }
  ],
  "final_artifacts": [
    {
      "kind": "quote_markdown",
      "uri": "s3://quotes/workflow-uuid/quote_v1.md"
    }
  ]
}
```

Store this as a JSONB column or file for traceability and debugging.

## 4. Markdown + JSON as primary interchange

## 4.1 Types of Markdown docs

Define a consistent naming and structure convention:

- Agent spec docs
  - `agents/orchestrator.global_spec_v3.md`
  - `agents/crm.coordinator_spec_v1.md`
- Tool spec docs
  - `tools/helpdesk.create_ticket.md`
- Workflow playbooks
  - `workflows/quote_generation_v2.md`
- Domain reference docs
  - `domain/inventory_concepts_v1.md`, `domain/project_management_v1.md`.

Each doc has a standard skeleton:

```
text# Agent: Orchestrator (global) v3

## Purpose
Short paragraph describing what the agent **does** and what it does **not** do.

## Inputs
- Envelope payloads: list intent types this agent accepts.
- Context: markdown specs, JSON logs.

## Outputs
- Envelope payloads: list result types it produces.
- Artifacts: markdown summaries, JSON reports.

## Responsibilities
- Decompose user/business goals into module-level tasks.
- Enforce global policies.
- Aggregate results and produce final artifact(s).

## Non-goals
- Direct database access.
- Business logic that belongs in module coordinators.

## Tools Available
- list of tools and their JSON schemas or links.

## Examples
### Example 1: Prepare quote
- Input: ...
- Subtasks: ...
- Expected outputs: ...

## Versioning
- Changes in v3 vs v2: ...
```

Coordinators and task agents follow the same template, which will become more valuable as Claude’s capabilities improve (it can better read and obey longer, more nuanced specs).

## 4.2 Markdown workflow spec pattern

Example: `workflows/helpdesk_ticket_v1.md`:

```
text# Workflow: Help Desk Ticket Creation v1

## Trigger
- New email received at support@...
- Or user describes an issue in chat.

## Goal
Create a well-structured ticket and a first draft reply.

## Steps
1. Orchestrator → helpdesk.coordinator:
   - intent: create_ticket_from_raw_input
   - payload: raw email/chat text, customer identifiers (if available).
2. helpdesk.coordinator:
   - calls tools: parse_email_headers, match_customer, classify_issue.
   - if confidence < 0.7 → ask_user_for_clarification via chat.
3. helpdesk.coordinator → helpdesk.task.summarize_issue:
   - produce structured JSON: ticket fields and short summary.
4. helpdesk.coordinator:
   - calls tool: helpdesk.create_ticket.
   - calls task agent: helpdesk.task.draft_reply.
5. Orchestrator:
   - aggregates ticket_id and reply draft.
   - returns result to UI and logs artifacts.

## Error Handling
- If any step fails hard, orchestrator creates a minimal ticket and flags for human review.

## Metrics
- Time from trigger to ticket created.
- Classification confidence distribution.
```

Agents can be instructed to read specific workflow docs and follow them step‑by‑step.

## 4.3 JSON inside Markdown

For clarity, you can embed canonical JSON schemas and example payloads inside Markdown code blocks and reference them by section anchors (e.g., “see §3.2 JSON schema”). Claude tends to respect explicit, labeled “JSON schema” and “Example request/response” sections when instructed to.

## 5. Prompt engineering patterns

## 5.1 Global prompt structure

Each agent gets:

1. System message with role, constraints, and tool list.
2. One or more “spec excerpts” from Markdown (purpose, responsibilities, non‑goals).
3. A small number of examples (few‑shot).
4. A strongly worded output contract + JSON Schema excerpt.

## Orchestrator system prompt template

```
textYou are the Orchestrator agent for a small-business platform.

Role:
- Convert high-level goals into calls to module coordinator agents.
- Never call module-specific tools directly; instead, delegate via envelopes.
- Maintain one coherent plan per workflow_id and keep steps logically consistent.

You MUST:
- Read the attached agent spec and workflow spec carefully.
- Produce only valid JSON envelopes when delegating, matching the provided schemas.
- Keep your reasoning private; do not expose intermediate plans except when explicitly requested in the prompt.

You MUST NOT:
- Invent data that should come from tools (databases, CRMs, inventory).
- Perform actions outside your tool list.

When you need work from another agent:
- Produce a JSON envelope with "to_agent", "intent", and "payload" fields.
- Conform exactly to the JSON Schema for that payload type.
- Use "correlation_id" given in the input.

When returning the final result to the caller:
- Produce a single JSON object summarizing the outcome and any artifact URIs.
```

You’d pass:

- Additional context: selected sections from the orchestrator spec doc and the relevant workflow doc.
- Tool definitions for inter‑agent calls as function‑calling tools.

## 5.2 Coordinator prompt template

```
textYou are the {MODULE_NAME} Coordinator agent.

Module: {MODULE_NAME} (e.g., CRM, Help Desk, Inventory).
Your responsibilities:
- Translate module-related intents into tools and task agent calls.
- Enforce module-specific rules and constraints.
- Return structured JSON payloads back to the Orchestrator.

Non-goals:
- Cross-module decision making.
- Global planning or policy enforcement.

Input:
- A single agent message envelope with "intent" and "payload" specific to this module.
- Optional references to markdown specs and prior artifacts.

Output:
- A single JSON object that conforms to the "{INTENT}_result" schema unless otherwise specified.

You MUST:
- Call tools when information is missing.
- Use task agents when generating long-form content or summaries.
- Fail fast with a structured error object if schemas cannot be satisfied after 2 attempts.
```

## 5.3 Task agent prompt template

```
textYou are a narrow task agent: {TASK_NAME}.

You do one thing:
{TASK_DESCRIPTION}

Input JSON schema:
{INPUT_SCHEMA_SNIPPET}

Output JSON schema:
{OUTPUT_SCHEMA_SNIPPET}

Rules:
- Do not include explanation or commentary; output ONLY a single JSON object.
- Do not include comments or trailing commas.
- If input is ambiguous, return an "error" object that still conforms to the output schema.

Example input:
```json
{EXAMPLE_INPUT}
```

Example output:

```
json
{EXAMPLE_OUTPUT}
text
### 5.4 Pattern for bounded roles and non‑goals

Always include a short “Non‑goals” list and “You MUST NOT” rules. It strongly reduces overreach, hallucinated tools, and cross‑module confusion.[11][12]


## 6. Error handling and fallback

### 6.1 Classification of errors

- Validation errors  
  - JSON doesn’t match schema, missing fields, wrong types.  
- Tool errors  
  - HTTP 4xx/5xx from services, timeouts, rate limits.  
- Reasoning errors  
  - Incoherent plan, repeated loops, ignoring constraints.  
- Safety/policy errors  
  - Attempt to perform disallowed actions or produce disallowed content.

### 6.2 Envelope‑level error representation

Normalize all errors into a predictable output:

```json
{
  "type": "error",
  "code": "VALIDATION_FAILED",
  "message": "payload missing required field 'customer_id'",
  "details": {
    "schema_id": "prepare-quote-request-v1",
    "path": "$.payload.data"
  },
  "retryable": false
}
```

Agents are instructed: if they cannot produce the expected schema, they must instead return an `error` object that still matches the “result schema” (with a union type for `result | error`).

## 6.3 Retry and fallback strategies

- Retries
  - Infrastructure: automatic retry on transient errors (timeouts, 5xx) with exponential backoff.
  - Agent-level: allow orchestrator to re‑issue a task with extra clarification if coordinator returns `VALIDATION_FAILED` or ambiguous results.
- Fallback paths
  - Fallback LLM model (cheaper vs. more capable) only for non‑critical tasks; for critical path use single high‑quality model for consistency.
  - Human‑in‑the‑loop: create a “review required” ticket or workflow step when confidence or quality is low.
- Guardrails
  - Orchestrator always checks: if coordinator result has `type: "error"` and `retryable: false`, the workflow must end by notifying a human or producing a partial result flagged for review.

## 6.4 Self‑healing prompts

When validation fails, your infrastructure can:

1. Run a small “repair” prompt: give Claude the invalid JSON and the schema, ask it to fix it.
2. If repair also fails, bubble up an error.

You can define a dedicated “json_repair” task agent for this.

## 7. Structuring Markdown specs for future LLMs

You want docs that are:

- Strictly structured, so LLMs can easily parse with section headings.
- Redundant enough that as models get better, they pick up more nuance without breaking older behavior.

Guidelines:

- Use consistent headings: `Purpose`, `Responsibilities`, `Non-goals`, `Inputs`, `Outputs`, `Tools`, `Examples`, `Versioning`.
- Keep examples short but exact: input, output, and notes.
- Include “Versioning” with explicit “Breaking changes” vs “Non‑breaking”.
- Include explicit “Escalation Rules” for when to hand off to humans or other agents.
- Maintain a top‑level `AGENTS_INDEX.md` that lists agents, their versions, and links.

Example index snippet:

```
text# Agent Index

## Tier 1 – Orchestrator
- orchestrator.global.v3 → agents/orchestrator.global_spec_v3.md

## Tier 2 – Coordinators
- crm.coordinator.v1 → agents/crm.coordinator_spec_v1.md
- helpdesk.coordinator.v1 → agents/helpdesk.coordinator_spec_v1.md

## Tier 3 – Task agents
- helpdesk.task.summarize_issue.v1 → agents/helpdesk.summarize_issue_v1.md
- inventory.task.check_low_stock.v1 → agents/inventory.check_low_stock_v1.md
```

Claude will be able to navigate this index to load relevant specs as it improves.

## 8. Practical Claude API implementation

## 8.1 Claude tool use concepts

Claude’s tool use works by:

- You define tools with JSON schemas (functions, parameters).
- Claude decides whether and how to call them.
- Your code executes tools and sends results back in a structured format.
- Claude then produces a final answer or further tool calls.

This mapping aligns perfectly with your agents:

- Inter‑agent messaging is modeled as tools (e.g., `send_to_agent`).
- Module coordinators can be implemented as tools from the orchestrator’s point of view, or as separate Claude calls several layers deep.
- Real platform actions (DB, APIs) are tools at each coordinator/task layer.

## 8.2 Example: orchestrator calling a coordinator via tool

Define a tool in the orchestrator’s Claude call:

```
json{
  "name": "send_to_agent",
  "description": "Send a message envelope to another agent in the system.",
  "input_schema": {
    "type": "object",
    "required": ["to_agent", "intent", "payload"],
    "properties": {
      "to_agent": { "type": "string" },
      "intent": { "type": "string" },
      "payload": { "type": "object" }
    }
  }
}
```

The orchestrator uses this tool to construct envelopes; your server:

1. Receives the `tool_use` from Claude.
2. Validates payload against the known schema for that `intent`.
3. Inserts into the appropriate queue (`queue_name` = coordinator).
4. Returns a `tool_result` with `message_id` and `queue_name`.

Later, when the coordinator finishes, your infrastructure calls Claude again (in coordinator mode) with the envelope and required context.

## 8.3 Context management

Key constraints: context window size and cost.

Patterns:

- Thin, focused contexts per call
  - Orchestrator sees: high‑level goal, aggregated state summary, relevant workflow spec sections, and a small sample of prior steps (not entire history).
  - Coordinators see: envelope payload, module spec docs, and relevant artifacts only.
  - Task agents see: just the input JSON + minimal instructions + schema snippet.
- Externalized memory
  - Conversation logs, artifacts, and agent history are stored externally and referenced via URIs; you pull in only what’s needed (e.g., last 3 tickets for this customer).
- Sliding windows for ongoing conversations
  - Use summarization agents to compress long conversations and keep a compact “state summary” document.

A simple context builder function per call:

1. Determine agent role and workflow stage.
2. Fetch relevant Markdown specs, truncating to a maximum token budget.
3. Fetch last N related envelopes or a summary.
4. Build `system` + `assistant` (if needed) + `user` messages for Claude.

## 8.4 Message pattern for Claude calls

For a coordinator call:

- `system`: Coordinator role and behavior (template above).
- `user`: Envelope payload + excerpt of workflow spec + any necessary domain docs.
- `tools`: Module tools + task agent tools if you choose to route through tools, or none if you treat task agents as separate Claude calls.
- Expect:
  - Either `tool_use` calls (which you execute and return) followed by final JSON result, or direct final JSON result.

## 8.5 Logging and observability

- Store full Claude request/response objects in an audit log (with redaction of sensitive fields).
- Correlate by `correlation_id`.
- Build an admin UI that shows:
  - Workflow tree (orchestrator → coordinators → tasks).
  - Each Claude call with inputs and outputs.
  - Validation errors and retries.

This will be crucial when something “feels off” in production.