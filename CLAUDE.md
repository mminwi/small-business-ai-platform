# CLAUDE.md — Small Business AI Platform

This file is read automatically by Claude Code at the start of every session.

---

## Project Overview

**"The Vending Machine"** — Turnkey AI-powered business software for small companies (1–20 employees).
Delivered as a one-time purchase, installed into the customer's existing Google Workspace or Microsoft 365.
Claude (Anthropic API) is the AI backbone. All business logic lives in markdown files. Data structures are JSON.

**Author:** Mike Maier — Director of Mechanical Engineering, Credo Product Development
**GitHub:** https://github.com/mminwi/small-business-ai-platform

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

---

## Pricing Tiers

| Tier | Price | Target | Key Modules |
|------|-------|--------|-------------|
| 1 | $500 | Service businesses (plumbers, caterers) | CRM, Scheduling, PM, Invoicing, Inventory, Help Desk, AI Chat |
| 2 | $1,500 | Small manufacturers, ISO compliance | All Tier 1 + ISO 9001, CAPA, BOM, Work Orders, Supplier Mgmt |
| 3 | $2,000–$4,000 | Government/military contractors | All Tier 2 + SAM.gov, ITAR, Gov Contract Tracking |

---

## Open Questions (Resolve Before Building)

- [ ] **API cost model:** Who pays for ongoing Claude API usage? Customer's own key, or subscription?
- [ ] **Hosting/runtime:** What actually runs the code? Google Apps Script, Cloud Run, hosted server?
- [ ] **Tier scoping:** Each spec needs a section marking which features apply at Tier 1 vs 2 vs 3

---

## Key Files to Know

| File | Purpose |
|------|---------|
| `PROJECT_CHARTER.md` | Full project vision and architecture |
| `specs/18 — AI Agent Orchestration Layer.md` | Best spec — defines agent envelope schema and prompt templates |
| `specs/01 — Contact & Customer Management (CRM).md` | Most detailed domain spec |
