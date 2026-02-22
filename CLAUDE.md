# CLAUDE.md — Small Business AI Platform

This file is read automatically by Claude Code at the start of every session.

---

## STANDING RULE — Generic Templates Only

**All files in `/procedures/` and `/schemas/` are generic templates.**
They must contain zero customer-specific content — no company names, no
customer-specific compliance postures, no hardcoded rates or team sizes.

When writing or editing any file in `/procedures/` or `/schemas/`:
- Use "the company" — never a customer name
- Use placeholders for any value a customer would configure (rates, names, addresses)
- If customer-specific logic is needed, note it as a configuration point, not hardcode it

---

## Project Overview

**"The Vending Machine"** — Turnkey AI-powered back-office system for small businesses (1–20 employees).
Delivered into the customer's existing Google Workspace or Microsoft 365.
Claude (Anthropic API) is the AI backbone. All business logic lives in markdown files. Data structures are JSON.

**GitHub:** https://github.com/mminwi/small-business-ai-platform

---

## Git

```bash
git add .
git commit -m "describe what changed"
git push
```

Credentials: stored in Windows Credential Manager (username: mminwi, token-based).

---

## Project Structure

```
/small-business-ai-platform/
├── CLAUDE.md                       ← This file
├── PROJECT_CHARTER.md              ← Vision, business model, architecture
├── /specs/                         ← Module specifications
├── /schemas/                       ← JSON data schemas
├── /procedures/                    ← Markdown procedure files
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

## Key Files

| File | Purpose |
|------|---------|
| `PROJECT_CHARTER.md` | Full project vision and architecture |
| `specs/18 — AI Agent Orchestration Layer.md` | Agent envelope schema and prompt templates |
| `specs/01 — Contact & Customer Management (CRM).md` | Most detailed domain spec |
