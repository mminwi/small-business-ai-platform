# Small Business AI Platform

An open-source AI back-office system for small businesses — built on markdown
procedure files and the Claude API (Anthropic). No proprietary software, no
subscription lock-in. You own the files. You own the data.

---

## The Problem

A 5-person plumbing company shouldn't need a $45,000/year back-office employee
to chase invoices, manage scheduling, handle paperwork, and operate QuickBooks.
But without that person, all of that falls on the owner — who is supposed to be
running the trade.

This project is that back-office employee, built in AI.

---

## How It Works

The system is a library of markdown **procedure files** — plain text documents
that tell an AI agent exactly how to do specific business jobs:

- Track projects and budgets
- Build estimates and proposals
- Generate and track invoices
- Monitor quality records
- Support business development

You load these files into a Claude agent (via the Anthropic API) and point it at
your business data. The AI reads the procedures, follows the rules, and handles
the back-office work. When your process changes, you edit a text file. No
retraining. No DevOps.

QuickBooks is still your accounting system — the AI operates it on your behalf.

---

## What's in the Box

| Module | File | What It Does |
|--------|------|--------------|
| Project Management | `procedures/pm/pm-core.md` | Track jobs, hours, budgets, milestones. Proactive alerts when projects go off track. |
| Estimating — Core | `procedures/estimating/estimating-core.md` | Build proposals from reusable workflow templates. No freeform hour guessing. |
| Workflow Library | `procedures/estimating/workflow-library.md` | Library of reusable phase patterns with hour bands by role. |
| Invoicing | `procedures/invoicing/invoicing-core.md` | Six billing models: percent-complete, milestone, deposit, T&M, fixed-price, materials-upfront. |
| Quality (ISO 9001-aligned) | `procedures/quality/quality-core.md` | NCRs, CAPAs, document control, audit readiness. No certification required to use. |
| Business Development | `procedures/bd/bd-core.md` | Capability statements, proposal content library, pipeline tracking. |

**Schemas** (JSON data structures the AI reads and writes):
`opportunity.json`, `invoice.json`, `ratesets.json`, `quality-record.json`, `bd-content.json`

---

## Design Principles

1. **Markdown for logic, JSON for data.** No proprietary formats. Any text editor can read and edit these files.
2. **The AI follows the procedure.** All business rules live in the markdown files — not in code. Change the text, change the behavior.
3. **The owner approves before anything goes to a client.** Invoices, proposals, follow-up emails — the AI drafts, you approve.
4. **Your data is always readable without the platform running.** Key records export to your Google Drive nightly as PDFs and CSVs. If anything breaks, your data is right there.
5. **QuickBooks-first.** Don't rebuild what QuickBooks already does. Integrate with it.

---

## Who This Is For

**Tier 1 — Service businesses** (plumbers, electricians, HVAC, catering, cleaning, landscaping)
> CRM, scheduling, project tracking, invoicing, inventory, AI chat assistant

**Tier 2 — Small manufacturers and ISO-pursuing firms**
> Everything in Tier 1 + ISO 9001, CAPA, document control, supplier management, BOM

The framework is generic — configure it for your business by filling in your rates,
your team, your workflows.

---

## Current Status

This is an early-stage, work-in-progress framework. The procedure library is
functional and covers the core back-office modules for a service business or
small engineering firm. Wiring it up to live APIs (QuickBooks, Google Workspace)
is a next phase.

What exists today:
- Complete procedure file library for core modules
- JSON schemas for all major data structures
- Architecture validated against commercial alternatives

What doesn't exist yet:
- Runnable agent code
- QuickBooks API integration
- Google Workspace integration
- A UI

If you are a developer, consultant, or technical business owner who wants to try
this or build on it — that's exactly who this is for right now.

---

## How to Try It

You need an [Anthropic API key](https://console.anthropic.com). Claude Sonnet
is the recommended model.

Basic approach:
1. Clone this repo
2. Pick the procedure files relevant to your business
3. Load them into a Claude agent as system prompt context
4. Point the agent at your project/client data (JSON files in Google Drive or
   similar)
5. Start asking it to do back-office tasks

A proper setup guide is on the roadmap. In the meantime, the procedure files
are readable — they describe exactly what the AI should do and what data it needs.

---

## Feedback

This is a public experiment. If you try it, find a gap, think a procedure is
wrong, or have a use case that isn't covered:

**[Open a GitHub Issue](https://github.com/mminwi/small-business-ai-platform/issues)**

Useful feedback:
- "This doesn't cover [business type] because..."
- "The invoicing procedure breaks for [billing scenario]..."
- "I tried loading this into [tool] and ran into..."
- "A plumber would never [describe assumption]..."

---

## Government Contracting

This repo covers commercial and service businesses. If your business pursues
government contracts — SAM.gov, SBIR, RFPs, ITAR, CMMC — that's a separate,
more complex system. Reach out directly if you want to talk through it:

**Mike Maier** — [github.com/mminwi](https://github.com/mminwi)

---

## License

MIT. Use it, modify it, build on it. See [LICENSE](LICENSE).

---

## About

Built by [Mike Maier](https://www.credopd.com) — Director of Engineering at
Credo Product Development, a 12-person engineering firm in the US. Credo is the
first test bed for this framework.

The framework is open source. If your business is too complex to set this up
yourself, implementation services are available — [open an issue](https://github.com/mminwi/small-business-ai-platform/issues)
or reach out directly.
