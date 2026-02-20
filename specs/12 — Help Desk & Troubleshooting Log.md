## Core entities and data structures

Design around a small set of entities:

- Ticket
- Customer, Contact, Organization
- Asset (customer equipment, environment)
- IssueTemplate / Category
- Resolution
- Comment / Message
- KnowledgeBaseArticle, FAQEntry, KBTag
- User (agent), Team / Queue
- Integration mappings (CRM, email, chat, phone)

## Ticket

Represents a single request or incident, independent of channel.

Key behaviors: lifecycle state machine, assignment, SLA tracking, AI vs human handling.

**Ticket JSON schema (simplified)**

```
json{
  "$id": "Ticket",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "ticket_number": { "type": "string" },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" },
    "closed_at": { "type": ["string", "null"], "format": "date-time" },

    "status": {
      "type": "string",
      "enum": [
        "new",
        "triage",
        "waiting_customer",
        "waiting_internal",
        "in_progress",
        "pending_release",
        "resolved",
        "closed"
      ]
    },
    "priority": {
      "type": "string",
      "enum": ["low", "normal", "high", "urgent"],
      "default": "normal"
    },
    "impact": {
      "type": "string",
      "enum": ["single_user", "multiple_users", "site_down"],
      "default": "single_user"
    },
    "channel": {
      "type": "string",
      "enum": ["email", "phone", "portal", "chat", "api"]
    },

    "subject": { "type": "string" },
    "description": { "type": "string" },

    "customer_id": { "type": "string", "format": "uuid" },
    "contact_id": { "type": ["string", "null"], "format": "uuid" },
    "organization_id": { "type": ["string", "null"], "format": "uuid" },

    "asset_ids": {
      "type": "array",
      "items": { "type": "string", "format": "uuid" }
    },

    "assigned_user_id": { "type": ["string", "null"], "format": "uuid" },
    "assigned_team_id": { "type": ["string", "null"], "format": "uuid" },

    "category_id": { "type": ["string", "null"], "format": "uuid" },
    "sub_category_id": { "type": ["string", "null"], "format": "uuid" },
    "issue_template_id": { "type": ["string", "null"], "format": "uuid" },

    "sla_policy_id": { "type": ["string", "null"], "format": "uuid" },
    "first_response_at": { "type": ["string", "null"], "format": "date-time" },
    "first_response_by_user_id": {
      "type": ["string", "null"],
      "format": "uuid"
    },

    "ai_first_response": { "type": "boolean", "default": false },
    "ai_confidence": { "type": ["number", "null"], "minimum": 0, "maximum": 1 },

    "resolution_id": { "type": ["string", "null"], "format": "uuid" },
    "resolution_summary": { "type": ["string", "null"] },

    "customer_visible": { "type": "boolean", "default": true },
    "tags": {
      "type": "array",
      "items": { "type": "string" }
    },

    "csat_score": {
      "type": ["integer", "null"],
      "minimum": 1,
      "maximum": 5
    },
    "csat_comment": { "type": ["string", "null"] },

    "source_message_ids": {
      "type": "array",
      "items": { "type": "string", "format": "uuid" }
    },

    "custom_fields": {
      "type": "object",
      "additionalProperties": true
    }
  },
  "required": ["id", "ticket_number", "created_at", "status", "subject", "channel"]
}
```

## Customer, Contact, Organization

Align these with your existing lightweight CRM module so help desk and CRM share core identity.

**Customer / Contact JSON schema**

```
json{
  "$id": "Contact",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "first_name": { "type": "string" },
    "last_name": { "type": "string" },
    "email": { "type": "string", "format": "email" },
    "phone": { "type": ["string", "null"] },
    "organization_id": { "type": ["string", "null"], "format": "uuid" },
    "role": { "type": ["string", "null"] },
    "crm_contact_id": { "type": ["string", "null"] },
    "created_at": { "type": "string", "format": "date-time" }
  },
  "required": ["id", "first_name", "last_name", "email"]
}
```

**Organization JSON schema**

```
json{
  "$id": "Organization",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "name": { "type": "string" },
    "external_id": { "type": ["string", "null"] },
    "billing_address": { "type": ["string", "null"] },
    "shipping_address": { "type": ["string", "null"] },
    "crm_company_id": { "type": ["string", "null"] },
    "qbo_customer_id": { "type": ["string", "null"] },
    "created_at": { "type": "string", "format": "date-time" }
  },
  "required": ["id", "name"]
}
```

## Asset

Represents hardware, software, subscriptions, or other items linked to the customer that may be relevant for support.

**Asset JSON schema**

```
json{
  "$id": "Asset",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "name": { "type": "string" },
    "type": { "type": "string" },
    "serial_number": { "type": ["string", "null"] },
    "identifier": { "type": ["string", "null"] },
    "organization_id": { "type": "string", "format": "uuid" },
    "contact_id": { "type": ["string", "null"], "format": "uuid" },
    "location": { "type": ["string", "null"] },
    "installed_at": { "type": ["string", "null"], "format": "date-time" },
    "warranty_expiration": {
      "type": ["string", "null"],
      "format": "date-time"
    },
    "status": {
      "type": "string",
      "enum": ["active", "retired", "spare"],
      "default": "active"
    },
    "metadata": {
      "type": "object",
      "additionalProperties": true
    }
  },
  "required": ["id", "name", "type", "organization_id"]
}
```

## IssueTemplate / Category

Standardize classification so automations, routing, and reports work well.

**IssueTemplate JSON schema**

```
json{
  "$id": "IssueTemplate",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "category_id": { "type": "string", "format": "uuid" },
    "sub_category_id": { "type": ["string", "null"], "format": "uuid" },
    "name": { "type": "string" },
    "default_priority": {
      "type": "string",
      "enum": ["low", "normal", "high", "urgent"]
    },
    "default_assigned_team_id": {
      "type": ["string", "null"],
      "format": "uuid"
    },
    "triage_questions": {
      "type": "array",
      "items": { "type": "string" }
    },
    "kb_article_ids": {
      "type": "array",
      "items": { "type": "string", "format": "uuid" }
    }
  },
  "required": ["id", "category_id", "name"]
}
```

## Resolution

Captures the outcome in a normalized way, separate from free‑form comments.

**Resolution JSON schema**

```
json{
  "$id": "Resolution",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "ticket_id": { "type": "string", "format": "uuid" },
    "resolution_type": {
      "type": "string",
      "enum": ["answered_question", "workaround", "permanent_fix", "duplicate", "invalid"]
    },
    "summary": { "type": "string" },
    "steps": {
      "type": "array",
      "items": { "type": "string" }
    },
    "root_cause": { "type": ["string", "null"] },
    "linked_kb_article_id": { "type": ["string", "null"], "format": "uuid" },
    "resolved_by_user_id": { "type": "string", "format": "uuid" },
    "resolved_at": { "type": "string", "format": "date-time" },
    "ai_generated": { "type": "boolean", "default": false },
    "ai_confidence": { "type": ["number", "null"], "minimum": 0, "maximum": 1 }
  },
  "required": ["id", "ticket_id", "resolution_type", "summary", "resolved_by_user_id", "resolved_at"]
}
```

## Comment / Message

Stores the conversation across channels.

**TicketMessage JSON schema**

```
json{
  "$id": "TicketMessage",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "ticket_id": { "type": "string", "format": "uuid" },
    "author_type": {
      "type": "string",
      "enum": ["customer", "agent", "system", "ai"]
    },
    "author_id": { "type": ["string", "null"], "format": "uuid" },
    "created_at": { "type": "string", "format": "date-time" },
    "channel": {
      "type": "string",
      "enum": ["email", "phone_log", "portal", "chat", "internal_note"]
    },
    "body": { "type": "string" },
    "customer_visible": { "type": "boolean", "default": true },
    "attachments": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": { "type": "string", "format": "uuid" },
          "file_name": { "type": "string" },
          "content_type": { "type": "string" },
          "size_bytes": { "type": "integer" },
          "url": { "type": "string" }
        },
        "required": ["id", "file_name", "content_type", "size_bytes", "url"]
      }
    },
    "ai_metadata": {
      "type": "object",
      "properties": {
        "model": { "type": ["string", "null"] },
        "confidence": { "type": ["number", "null"] },
        "kb_article_ids": {
          "type": "array",
          "items": { "type": "string", "format": "uuid" }
        }
      },
      "additionalProperties": true
    }
  },
  "required": ["id", "ticket_id", "author_type", "created_at", "channel", "body"]
}
```

## Knowledge base entities

At minimum, you need articles, tags, and search metadata.

**KnowledgeBaseArticle JSON schema**

```
json{
  "$id": "KnowledgeBaseArticle",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "slug": { "type": "string" },
    "title": { "type": "string" },
    "body_markdown": { "type": "string" },
    "summary": { "type": "string" },
    "category_id": { "type": ["string", "null"], "format": "uuid" },
    "tags": {
      "type": "array",
      "items": { "type": "string" }
    },
    "created_by_user_id": { "type": "string", "format": "uuid" },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" },

    "is_published": { "type": "boolean", "default": false },
    "is_external": { "type": "boolean", "default": true },

    "view_count": { "type": "integer", "default": 0 },
    "helpful_votes": { "type": "integer", "default": 0 },
    "not_helpful_votes": { "type": "integer", "default": 0 },

    "related_article_ids": {
      "type": "array",
      "items": { "type": "string", "format": "uuid" }
    },

    "embedding_vector_id": { "type": ["string", "null"] },

    "source_type": {
      "type": "string",
      "enum": ["manual", "ticket_derived", "imported"],
      "default": "manual"
    },
    "source_ticket_ids": {
      "type": "array",
      "items": { "type": "string", "format": "uuid" }
    }
  },
  "required": ["id", "slug", "title", "body_markdown", "created_by_user_id", "created_at", "updated_at"]
}
```

------

## Ticket lifecycle and workflows

Use a compact state machine with time‑to‑first‑response and resolution time metrics as first‑class outputs.

## States

- new: freshly created, untriaged.
- triage: being classified and routed (could be AI‑only for micro teams).
- in_progress: assigned and being worked.
- waiting_customer: waiting on customer reply.
- waiting_internal: waiting on internal dependency (vendor, dev, management).
- pending_release: fix ready, but not yet confirmed with customer.
- resolved: solution provided, awaiting auto‑ or manual closure.
- closed: final state, metrics locked.

## Workflow description

1. **Intake**
   - Channels: email, portal, chat, phone log, API.
   - New Ticket created with status=new, channel set, subject/description extracted.
   - AI classifies category, predicts priority, suggests IssueTemplate, and optionally drafts an initial reply.
2. **Triage**
   - Automatic rules: if category=“outage” and impact=“site_down”, set priority=urgent and assign to on‑call team.
   - AI generates a triage suggestion: probable root cause, recommended assignee/team.
   - Agent or auto‑assignment sets assigned_team_id and status=in_progress.
   - first_response_at recorded when first customer‑visible reply is sent (AI or human) for FRT.
3. **Work in progress**
   - Agent and AI exchange messages with customer via TicketMessage.
   - Link relevant assets and KB articles.
   - Internal notes via channel=internal_note and customer_visible=false.
4. **Resolution**
   - Agent or AI creates a Resolution record with resolution_type, summary, steps.
   - Ticket status moves to resolved, closed_at stays null.
   - CSAT survey can be sent on resolved state.
5. **Closure**
   - Auto‑close after N days without customer response, or manual close.
   - closed_at populated, metrics computed (resolution time, touches, reopens).
6. **Reopen**
   - If customer replies on resolved/closed ticket, you can:
     - Reopen same ticket (status=in_progress, increment reopen counter).
     - Or open a new ticket linked via parent_ticket_id (optional field).

------

## Knowledge base structure and retrieval

Use a hybrid of structured fields (categories/tags) and vector search for semantic retrieval.

## KB taxonomy

- Categories: map to high‑level product or service areas (e.g., “Email Issues”, “Billing”, “Hardware”).
- Tags: free‑form keywords, error codes, customer segments.
- Visibility:
  - is_external: visible to customers.
  - is_internal: implied when is_external=false (agent‑only diagnostics).

## Retrieval for UI

- Portal search:
  - Full‑text search over title, summary, body_markdown, tags.
  - Filters: category, tag, audience, updated_at.
- Agent console:
  - Contextual search by ticket subject + last customer message.
  - Show top N articles with confidence score and “Insert answer” button.

## Retrieval for AI (RAG)

- Maintain a separate Embedding index:
  - Documents: KB articles, accepted ticket resolutions, “playbooks”.
  - Store embedding_vector_id in KnowledgeBaseArticle; actual vectors in your vector store (e.g., pgvector, Pinecone, Qdrant).
- Chunking:
  - Chunk body_markdown into ~500–1000 token segments stored in KBChunk with fields: article_id, chunk_index, content, embedding_vector_id, tags.
- Semantic retrieval:
  - For a given user query or ticket context, embed the prompt and retrieve top‑k chunks by cosine similarity.
  - Deduplicate at article level, then feed chosen snippets into LLM context.

------

## AI chat interface architecture

Use a retrieval‑augmented generation pattern with guardrails and explicit escalation routing.

## High‑level components

- Web chat widget (JS snippet) embedded in customer portal or marketing site.
- Chat API gateway: WebSocket or HTTP streaming endpoint.
- Orchestrator service:
  - Handles session state.
  - Connects to LLM provider (e.g., OpenAI, Anthropic, local).
  - Calls vector store for KB retrieval.
  - Enforces authorization and data partitioning per business tenant.
- Ticketing service:
  - Creates/updates Ticket and TicketMessage records based on chat flows.
- Observability & analytics:
  - Logs each turn, latency, AI confidence, resolution success.

## Session data model (for chat)

**ChatSession JSON schema**

```
json{
  "$id": "ChatSession",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "contact_id": { "type": ["string", "null"], "format": "uuid" },
    "organization_id": { "type": ["string", "null"], "format": "uuid" },
    "ticket_id": { "type": ["string", "null"], "format": "uuid" },
    "channel": {
      "type": "string",
      "enum": ["web_chat", "in_app", "whatsapp", "sms"]
    },
    "started_at": { "type": "string", "format": "date-time" },
    "ended_at": { "type": ["string", "null"], "format": "date-time" },
    "status": {
      "type": "string",
      "enum": ["active", "escalated", "ended"]
    },
    "metadata": {
      "type": "object",
      "additionalProperties": true
    }
  },
  "required": ["id", "channel", "started_at", "status"]
}
```

## Request/response payloads (LLM orchestrator)

**LLM request**

```
json{
  "session_id": "uuid",
  "tenant_id": "uuid",
  "user_message": "My internet is down on the second floor.",
  "context": {
    "contact_id": "uuid",
    "organization_id": "uuid",
    "recent_tickets": ["uuid1", "uuid2"],
    "assets": [{ "id": "asset-1", "name": "Router A", "location": "2nd floor" }]
  },
  "settings": {
    "max_tokens": 512,
    "temperature": 0.2
  }
}
```

**LLM response**

```
json{
  "session_id": "uuid",
  "assistant_message": "Let's run a quick check on your router. First, confirm that the power light is on.",
  "citations": [
    { "kb_article_id": "kb-123", "chunk_id": "chunk-789", "score": 0.91 }
  ],
  "actions": [
    {
      "type": "ticket.update",
      "fields": {
        "category_id": "network",
        "priority": "high"
      }
    }
  ],
  "ai_confidence": 0.86,
  "should_escalate": false
}
```

## RAG flow

1. Receive message; update ChatSession and create Ticket if not existing.
2. Build a retrieval query using last N turns + ticket subject.
3. Embed query, retrieve relevant KB chunks and high‑value past resolutions.
4. Construct LLM prompt with:
   - System message: role, tone, business constraints.
   - Context snippets: retrieved chunks (with citation IDs).
   - Conversation history (compressed as needed).
5. Call LLM; stream response back to client.
6. Store assistant reply as TicketMessage with author_type=ai, ai_metadata including kb_article_ids and ai_confidence.
7. Apply actions (ticket updates, suggestions) if above defined confidence and rule thresholds.

------

## Escalation workflows when AI cannot resolve

You need explicit rules for when AI hands off to a human and how that appears to agents.

## Escalation triggers

- Low AI confidence:
  - ai_confidence below threshold (e.g., 0.7) for N consecutive replies.
- User intent:
  - Explicit phrases (“talk to a person”, “agent”, “call me”) detected by classifier.
- Policy:
  - Certain categories always require human (billing changes, cancellations).
- Time‑based:
  - No meaningful progress after M messages.

## Escalation behavior

- Update ChatSession.status to escalated and link or create Ticket.
- Ticket transitions:
  - If not created: create Ticket with channel=chat, status=new, priority derived from conversation.
  - If existing Ticket: set status=in_progress or waiting_internal and assign_team_id to default support team.
- Notify agent:
  - Web UI: queue tile highlights new escalated chat with last messages and AI summary.
  - Optional: email/Slack notification, depending on small shop preferences.

**Escalation event JSON**

```
json{
  "session_id": "uuid",
  "ticket_id": "uuid",
  "reason": "low_confidence",
  "ai_confidence": 0.52,
  "timestamp": "2026-02-18T17:47:00Z",
  "summary_for_agent": "Customer reports intermittent network outages on 2nd floor. AI attempted basic troubleshooting without success."
}
```

Agents see conversation history plus summary and linked KB suggestions; they reply through the same ticket UI, and responses flow back to chat widget.

------

## CRM integration for customer history

The help desk should feel like a view on the same customer data, not a separate silo.

## Identity and mapping

- Contact and Organization share IDs with CRM where possible.
- For external CRMs (e.g., QuickBooks, HubSpot) keep mapping tables:
  - Organization.qbo_customer_id, crm_company_id.
  - Contact.crm_contact_id, google_contact_id (if you use Google Contacts).
- When a new ticket arrives:
  - Resolve contact by email/phone against CRM.
  - If no match, create new lead/contact in CRM via integration service.

## Surface CRM context in help desk

When agent opens a ticket:

- Show panel with:
  - Organization data (name, lifetime value from invoices, open opportunities).
  - Contact role and notes (from CRM interactions).
  - Recent tickets and average CSAT for this organization.
- Enable navigation:
  - “View in CRM” deep link using crm_company_id or crm_contact_id.

## Data sync patterns

- One‑way vs two‑way:
  - For small shops, treat CRM as master for contact/company; help desk pushes read‑only references and ticket summaries back to CRM interactions.
- Example sync:
  - When ticket closed, post a summarized Interaction to CRM:
    - subject, brief summary, resolution_type, CSAT, link to ticket.

------

## Help desk performance metrics

Expose simple but powerful KPIs; small teams benefit most from visibility into volume, responsiveness, and quality, not deep analytics.

## Core ticket metrics

- First response time (FRT):
  - Time from ticket created_at to first_response_at.
- Average resolution time:
  - Time from created_at to closed_at or resolved_at.
- Ticket volume:
  - Total tickets per day/week by channel, category, and customer.
- Backlog:
  - Count of tickets by status and priority.

## Quality and AI metrics

- CSAT:
  - Average csat_score per period, per agent, per category.
- Reopen rate:
  - % of tickets reopened after resolution.
- AI deflection rate:
  - % of sessions where AI resolved without human intervention (no escalation, ticket auto‑closed).
- AI assist rate:
  - % of agent replies that used AI suggested drafts.
- KB helpfulness:
  - helpful_votes / (helpful_votes + not_helpful_votes) per article.

## Example metric fields on Ticket (denormalized for reporting)

You may store derived fields on TicketMetrics or materialized views instead.

```
json{
  "ticket_id": "uuid",
  "first_response_time_minutes": 32,
  "resolution_time_minutes": 240,
  "reopened_count": 1,
  "ai_messages_count": 4,
  "agent_messages_count": 3
}
```

## Representative metrics table

| Metric                    | Definition                                | Why it matters                                        |
| :------------------------ | :---------------------------------------- | :---------------------------------------------------- |
| First response time (FRT) | Time from ticket creation to first reply. | Shows how quickly customers get acknowledged.         |
| Resolution time           | Time from creation to resolution/closure. | Indicates efficiency and issue complexity.            |
| CSAT                      | Average 1–5 rating after ticket close.    | Reflects perceived support quality.                   |
| AI deflection rate        | % AI‑resolved tickets without human.      | Measures cost savings and self‑service effectiveness. |
| Reopen rate               | % tickets reopened after resolve.         | Signals solution quality and documentation gaps.      |

------

## Self‑improving knowledge base

Use resolved tickets and AI summaries to continuously enrich the KB and improve retrieval.

## From resolution to KB candidate

When a ticket is resolved:

1. Generate AI summary:
   - Inputs: ticket description, messages, Resolution record.
   - Output: problem statement, root cause, fix steps, affected asset types.
2. Decide if it should become KB content:
   - Heuristics:
     - Repeated issue (similar tickets in last N days).
     - High‑priority or major incident.
     - Low CSAT → flag for review, not immediate publication.

**KB draft from ticket JSON**

```
json{
  "source_ticket_id": "uuid",
  "title": "Wi‑Fi drops on second floor every afternoon",
  "body_markdown": "### Symptoms\n- Users lose Wi‑Fi on 2nd floor after 2pm.\n\n### Root cause\nA scheduled firmware update rebooted the access point daily at 2pm.\n\n### Resolution steps\n1. Log into router admin...\n2. Disable daily reboot task...\n3. Verify uptime for 48 hours.\n",
  "tags": ["wifi", "network", "access-point", "firmware"],
  "source_type": "ticket_derived",
  "source_ticket_ids": ["uuid"],
  "is_published": false
}
```

## Review workflow

- State machine on KnowledgeBaseArticle:
  - draft → in_review → approved → published.
- For micro teams, you can simplify:
  - Auto‑publish internal articles (is_external=false) above certain AI confidence.
  - Require manual approval for external articles.

## Retraining and feedback loops

- Use search logs:
  - Identify queries with no results or high click‑through but low helpful_votes, then generate draft articles to fill gaps.
- Use AI answers:
  - For high‑volume AI‑resolved chats, cluster similar tickets and create generalized KB content with human review.
- Adjust retrieval:
  - Weight articles with higher helpful_votes more heavily during vector retrieval or ranking.

------

## Putting it together: minimal architecture for 1–20 person shops

For small businesses, favor a single service or monolith with clear module boundaries and a thin AI orchestrator layer.

High‑level components:

- Core app (REST/GraphQL):
  - Ticketing, assets, KB, users, teams.
- Integrations:
  - Email ingestion (IMAP/SMTP), CRM sync, QuickBooks mapping (if you reuse your invoicing module).
- AI service:
  - Wraps LLM calls, KB retrieval, prompt construction, and logging.
- Data stores:
  - Relational DB (Postgres) for entities and metrics.
  - Vector store for embeddings and semantic search.
- Frontends:
  - Agent console web app.
  - Customer portal and embeddable chat widget.

This blueprint should give you enough structure to expand into a 15–25 page spec by:

- Adding Postgres DDL or ORM models per entity.
- Defining REST/GraphQL endpoints for tickets, KB, chat, and metrics.
- Drawing sequence diagrams for intake, AI chat with RAG, and escalation.
- Elaborating SLAs, permissions, and per‑tenant isolation details.