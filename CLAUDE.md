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

## Business Model Clarification

- **The framework is open source** — procedures, schemas, agent designs, and prompt templates are published publicly on GitHub. Any capable LLM can use the framework to self-configure a basic system.
- **The service business** is for customers who are not technical enough to implement it themselves, or complex enough to need hands-on help.
- **Revenue comes from implementation services**, not software licenses.
- **Publishing the knowledge builds trust** — it validates the framework and positions Mike as the domain expert.

## Resolved Architecture Decisions

- **API costs:** Customer supplies their own Anthropic API key and pays usage directly. No ongoing software subscription.
- **Business logic:** Markdown procedure files — the AI's "how-to manual." Stored in customer's workspace and readable/editable by the customer.
- **Data (customer-visible):** JSON files in Google Drive or SharePoint — customers can see and edit their data directly.
- **Data (operational):** Thin backend database (e.g., Firestore or Postgres on Cloud Run) indexes and caches the JSON data for fast queries. JSON files are the source of truth; DB is a performance layer.
- **QuickBooks-first rule:** QB is the accounting system. AI operates QB on the owner's behalf. Don't rebuild what QB provides.
- **Minimum hard-coded infrastructure** (cannot be eliminated — see specs/21):
  - OAuth handler for Google + QuickBooks authentication
  - Tool executor: validates parameters, calls APIs, retries on failure
  - Lightweight indexed database for fast operational queries
  - Background scheduler for proactive tasks (overdue invoice reminders, daily summaries)
  - Audit log: every AI action recorded with timestamp, inputs, outputs

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

## Data Safety & Owner Trust — Non-Negotiable Design Principle

Small business owners fear losing access to their data if a system goes down or a vendor disappears.

**Design rule: Critical business data is always readable without the platform running.**

The background scheduler exports key data to the customer's Google Drive automatically:

| Export | Format | Frequency |
|--------|--------|-----------|
| Customer list | PDF + CSV | Nightly |
| Vendor / supplier list | PDF + CSV | Nightly |
| Open jobs / work orders | PDF | Nightly |
| Open invoices (AR — who owes money) | PDF | Nightly |
| Inventory snapshot | PDF + CSV | Weekly |
| Employee / contractor list | PDF | Weekly |

- **PDF** — human-readable without any software, printable, shareable with accountant
- **CSV** — importable into Excel or any other system; data portability if they ever leave

**Selling point:** *"Your customer list, open jobs, and invoices are saved to your Google Drive every night. If anything goes wrong — internet down, we go out of business, anything — you open Google Drive and everything is right there."*

This also means the platform can never hold data hostage. The customer owns their data, always.

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

## First Customer — Credo Product Development Inc.

**www.credopd.com** — Engineering product development firm. Mike's company. First test bed.

**Team (12 people):**
- 3 mechanical engineers
- 2 electrical engineers
- 3 industrial designers
- 1 prototype technician
- 1 firmware/software engineer (potential technical resource for backend setup)
- 2 business development
- 1 person feeding QuickBooks + doing HR ← the role the AI replaces

**Credo's business model:** Engineering services firm — bills clients for hours + expenses on projects. BD generates proposals; engineers execute; QB person manually handles invoicing, time entry, and HR admin.

**Immediate pain points the platform solves for Credo:**
- Engineers log time → QB person manually enters into QuickBooks → AI does this instead
- BD team creates estimates/proposals manually → AI generates from project templates
- QB person manually creates client invoices → AI auto-invoices from project time logs
- HR admin overhead → AI handles scheduling, reminders, basic record-keeping

**Why Credo is a better test bed than a plumber:** More complex (12 people, multiple project types, professional services billing, BD pipeline). If it works here it works anywhere simpler.

## Credo Module List (Finalized 2026-02-21)

Credo is an engineering services firm — not a trade contractor. Modules are
selected for that context. Modules not listed are not needed for Credo.

**Build in this order:**

| Priority | Module | Why |
|----------|--------|-----|
| 1 | Project Management | Core ops — done: `procedures/pm/pm-core.md` |
| 2 | Estimating + Proposals | Highest BD impact; Workflow Library approach |
| 3 | ISO 9001 + Document Control + CAPA | Certification pursuit — build as one sprint |
| 4 | SAM.gov + ITAR + Gov Contract Tracking | Active BD — drumming up defense work |
| 5 | BD Content & Defense Marketing | LinkedIn + capability statements + SAM narrative |
| 6 | Invoicing | Comes after PM + estimating are working |
| — | QB API Integration | 18+ months out; write procedures now, wire API later |

**Not needed for Credo:** CRM (have one), Scheduling/Dispatch, Inventory,
Work Orders, Supplier/Vendor, BOM, Help Desk, Website Generation, Customer Chat.

## Explaining the Platform to Non-Technical Customers

- **What are procedure files?** "The AI's Employee Handbook — markdown documents that tell it exactly how to do its job. When your process changes, you edit a text file. No retraining, no DevOps."
- **Why not fine-tuning?** Edit a text file instead of retraining. Cheaper, traceable, and the AI can cite exactly which rule it followed.
- **Positioning:** "Linux for small-business AI operations." Open, editable, yours to keep.
- **Defense BD positioning:** "The only AI BD assistant built for a 10-person defense engineering firm — not a watered-down version of a big-prime tool."

## Architecture Decisions (Validated 2026-02-21)

Research confirmed the platform architecture is correct. External analysis
(ChatGPT research, GPT store survey) concluded:

> "Hybrid wins: Local Knowledge Base + Multi-agent Pipeline, with a Custom GPT as UI."

That is exactly what we are building.

**Estimating module design rule — Workflow Library:**
The AI never guesses hours. It selects a phase pattern from a library of
10-20 reusable templates, then proposes adjustments with explicit rationale.
No freeform pricing. See `research/competitive-landscape-2026-02.md`.

**Credo workflow patterns (to be detailed in estimating procedure file):**
Discovery, Concept, Detailed Design (ME/EE/ID), Firmware/SW, Prototype Build,
V&V, DFM/Tech Data Package, Program Management, SBIR/GovCon Proposal.

## GovCon Compliance — Current Facts (as of 2026-02-21)

These go into the SAM.gov/GovCon procedure file. They are current:
- **CMMC rollout began November 10, 2025** — active now
- **NIST SP 800-171 Rev. 3** is current (not Rev. 2)
- **UEI replaced DUNS** on SAM.gov — April 4, 2022
- **DFARS 252.204-7012** — required cybersecurity clause for any DoD work

## Open Questions / Research Tasks

- [ ] **Tier scoping:** Each spec needs a section marking which features apply at Tier 1 vs 2 vs 3
- [ ] **Hard-coded minimum:** Identify per module what absolutely must be code vs. what can be markdown-driven
- [x] **SAP/commercial gap analysis:** Complete — see `specs/gap.md`
- [ ] **Workflow Library:** Detail hour bands by role for each Credo phase pattern (needs historical data from Mike)
- [ ] **Pending research:** Perplexity + Gemini prompts not yet returned — see `research/competitive-landscape-2026-02.md`
- [ ] **ChatGPT follow-up:** Ask for workflow templates, data schema v1, QC rules (prompt drafted in research doc)

---

## Key Files to Know

| File | Purpose |
|------|---------|
| `PROJECT_CHARTER.md` | Full project vision and architecture |
| `specs/18 — AI Agent Orchestration Layer.md` | Best spec — defines agent envelope schema and prompt templates |
| `specs/01 — Contact & Customer Management (CRM).md` | Most detailed domain spec |
