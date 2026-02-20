# CLAUDE.md — Small Business AI Platform

This file is read automatically by Claude Code at the start of every session.

---

## Project Overview

**"The Vending Machine"** — Turnkey AI-powered business software for small companies (1–20 employees).
Delivered as a one-time purchase, installed into the customer's existing Google Workspace or Microsoft 365.
Claude (Anthropic API) is the AI backbone. All business logic lives in markdown files. Data structures are JSON.

**Author:** Mike Maier — Director of Mechanical Engineering, Credo Product Development
**GitHub:** https://github.com/mminwi/small-business-ai-platform

## Core Mission — The AI Back-Office Person

**The platform replaces the back-office employee a small business cannot afford to hire.**

A 5-person plumbing company shouldn't need a $45,000/year bookkeeper to operate QuickBooks, chase invoices, manage scheduling, and handle paperwork. The AI does that job instead.

The owner runs the trade. The AI runs the office.

QuickBooks is still the accounting system — but the AI is the operator of QuickBooks. The customer should rarely if ever need to open QB directly. The AI:
- Converts completed jobs into QB invoices automatically
- Pushes estimates to QB for customer approval
- Creates new QB customer records when CRM wins a deal
- Monitors AR and drafts payment follow-up emails
- Reconciles job costs vs. actuals
- Pulls hours from work orders into QB Time / payroll
- Captures vendor bills and pushes to QB AP
- Generates plain-English weekly/monthly summaries for the owner

**Design rule:** If a back-office person would normally do it by opening QuickBooks or a spreadsheet, the AI should do it instead — automatically or with one confirmation step from the owner.

---

## Git — Save Your Work

**Remind Mike to commit and push whenever a meaningful chunk of work is done.**

```bash
git add .
git commit -m "describe what changed"
git push
```

Examples of good commit messages:
- `"Add CRM JSON schema"`
- `"Update orchestrator prompt template"`
- `"Resolve API cost model in project charter"`

GitHub repo: https://github.com/mminwi/small-business-ai-platform
Credentials: stored in Windows Credential Manager (username: mminwi, token-based)

---

## Project Structure

```
/small-business-ai-platform/
├── CLAUDE.md                       ← This file
├── PROJECT_CHARTER.md              ← Vision, business model, architecture
├── perplexity_research_prompts.md  ← Research prompts used to generate specs
├── /specs/                         ← 20 module specifications (Perplexity research)
├── /schemas/                       ← JSON data schemas (to be built)
├── /procedures/                    ← Markdown procedure files (to be built)
├── /prompts/                       ← Claude agent prompts (to be built)
├── /integrations/                  ← API integration specs (to be built)
└── /delivery/                      ← Customer delivery packages (to be built)
```

---

## Architecture Principles

1. **No hard-coded business logic** — all rules live in markdown files Claude interprets
2. **Markdown for logic, JSON for data** — no proprietary formats
3. **Three-tier agent system:** Orchestrator → Module Coordinators → Task Agents
4. **Platform:** Google Workspace primary, Microsoft 365 secondary
5. **Accounting:** QuickBooks Online via API (customer-supplied)
6. **Minimum viable per tier** — scale features to what each customer tier actually needs

## Resolved Architecture Decisions

- **API costs:** Customer supplies their own Anthropic API key and pays usage directly. No ongoing software subscription.
- **Runtime:** AI agents run from markdown prompt files and JSON data files installed in the customer's workspace. Minimize hard-coded logic — still determining what absolutely must be hard-coded (treat as an open design question per module).
- **Data storage:** JSON files in the customer's workspace (Google Drive or SharePoint folder structure)
- **Business logic storage:** Markdown files in the customer's workspace, read by Claude at runtime
- **QuickBooks-first rule:** QuickBooks Online is the customer's accounting system. Anything QB already does well should be left to QB and supplemented only where needed — do NOT rebuild what QB provides. Our platform handles operational data QB never sees.

## What QuickBooks Handles (Don't Rebuild)

Customers already have QB. Integrate with it — don't duplicate it.

| QB Feature | Our Role |
|-----------|----------|
| Invoicing & estimates | Push/pull via API only |
| Payroll (QB Payroll / Gusto) | Point customers to it; document integration |
| Time tracking (QuickBooks Time) | Point customers to it; pull hours into job costing |
| Purchase orders | QB handles; we may surface PO status in work orders |
| Financial reporting & dashboards | QB handles; we supplement with operational data |
| Customer records (basic) | QB is secondary; CRM is our master |
| Recurring billing | QB handles |
| Expense tracking | QB handles |

## What We Build (QB Doesn't Cover This)

| Our Module | Why QB Doesn't Cover It |
|-----------|------------------------|
| CRM (leads, pipeline, interaction history) | QB has basic customer records, not sales pipeline |
| Scheduling & Dispatch | QB has no job scheduling concept |
| Work Orders & Job Tracking | QB sees the invoice, not job execution |
| Project Management | QB job costing is basic, not project tracking |
| Inventory / BOM / MRP (manufacturer level) | QB inventory too simple for manufacturers |
| ISO 9001 / CAPA / Document Control | QB has nothing here |
| Gov / ITAR / SAM.gov | QB has nothing here |
| Asset & Equipment Management | QB has no equipment tracking |
| Online booking (inbound) | QB doesn't do customer-facing booking |
| AI orchestration layer | The core differentiator |
| Operational dashboards | Jobs, scheduling, quality status — not in QB |
| Thin HR / employee + certification records | For ISO/ITAR compliance only; payroll stays in QB |

## Out of Scope (Standalone Tools Handle It)

- **Payroll** → QuickBooks Payroll or Gusto
- **Email marketing / campaigns** → Mailchimp, HubSpot, etc.
- **E-commerce / online store** → Shopify, WooCommerce
- **Full HR suite** → BambooHR, Gusto, Rippling

---

## Pricing Tiers

| Tier | Price | Target | Key Modules |
|------|-------|--------|-------------|
| 1 | $500 | Service businesses (plumbers, caterers) | CRM, Scheduling, PM, Invoicing, Inventory, Help Desk, AI Chat |
| 2 | $1,500 | Small manufacturers, ISO compliance | All Tier 1 + ISO 9001, CAPA, BOM, Work Orders, Supplier Mgmt |
| 3 | $2,000–$4,000 | Government/military contractors | All Tier 2 + SAM.gov, ITAR, Gov Contract Tracking |

---

## Build Priority Order

1. **Project Tracking** (Module 02) — first module to build end-to-end
2. **Estimating** (part of Module 04 — Invoicing & Estimates)
3. **Invoicing** (Module 04 — QuickBooks integration)
4. Then expand from there based on what the first customers need

## Open Questions / Research Tasks

- [ ] **Tier scoping:** Each spec needs a section marking which features apply at Tier 1 vs 2 vs 3
- [ ] **Hard-coded minimum:** Identify per module what absolutely must be code vs. what can be markdown-driven
- [x] **SAP/commercial gap analysis:** Complete — see `specs/gap.md`
- [ ] **Asset & Equipment Management:** Add as new module (gap identified; QB doesn't cover it)
- [ ] **Operational dashboards:** Add as new module — AI-generated summaries of jobs, scheduling, quality (financial dashboards stay in QB)
- [ ] **Thin HR / employee records:** Determine scope — certifications, training records for ISO/ITAR only; keep minimal

---

## Key Files to Know

| File | Purpose |
|------|---------|
| `PROJECT_CHARTER.md` | Full project vision and architecture |
| `specs/18 — AI Agent Orchestration Layer.md` | Best spec — defines agent envelope schema and prompt templates |
| `specs/01 — Contact & Customer Management (CRM).md` | Most detailed domain spec |
