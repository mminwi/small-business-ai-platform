# Research: Competitive Landscape & Architecture Validation
**Date:** 2026-02-21
**Source:** ChatGPT (GPT-4o) research prompts — see perplexity_research_prompts.md
**Status:** In progress — Perplexity and Gemini results pending

---

## What We Asked

Ran structured research prompts across ChatGPT, Perplexity, and Gemini to answer:
1. What AI tools exist for small business operations / defense contracting?
2. What's in the GPT store for PM, ISO 9001, GovCon, engineering proposals?
3. Has anyone already published open markdown procedure files for business AI?
4. What architecture wins for a defense engineering firm?

---

## Key Findings — GPT Store Landscape

### What exists (and what's broken)

| Category | What exists | Common complaints |
|----------|------------|-------------------|
| PM Assistant | Generic plan generators, milestone drafters | No persistence, no tool integration, generic output |
| ISO 9001 | "Surprisingly thin" — basically ISO tutors + template generators | Not auditable, no document control, generic documents |
| GovCon / SAM.gov | Only a handful of tools, none with live opportunity access | No capture planning, no compliance enforcement, no legal reliability |
| Engineering Proposals | Underdeveloped — draft SOWs, phase breakdowns | No cost models, cannot estimate effort, no integration |

### The gap our platform fills

Every common complaint maps directly to a design decision we've already made:

| User complaint | Our solution |
|---------------|--------------|
| No persistence — each conversation isolated | JSON files in Google Drive = permanent memory |
| Not connected to real tools | Tool executor calls real APIs |
| Generic output — feels like base model + instructions | Procedure files specific to each customer's workflow |
| Not trustworthy for regulated/high-stakes domains | Hard stops + human approval gates |
| Needs heavy editing — not operational | Procedures define exact behavior per situation |

**Conclusion: The gap is real. Nothing in the GPT store does what we're building.**

---

## Key Findings — Architecture Validation

ChatGPT's recommendation for a "Credo-grade" proposal AI:

> *"Hybrid wins: Local Knowledge Base + Multi-agent Pipeline, with a Custom GPT as the UI."*

This is exactly our architecture:
- Local knowledge base = markdown procedure files + JSON data in Google Drive
- Multi-agent pipeline = orchestrator → module coordinators → task agents
- UI = owner talks to Claude

**The architecture is validated independently.**

---

## New Concept to Adopt — The Workflow Library

For the estimating module, ChatGPT introduced a concept worth adopting:

> *10–20 reusable phase patterns. Each has: entry/exit criteria, task menu,
> typical hour bands by role, typical deliverables, typical assumptions/exclusions.*

This becomes the backbone of the estimating procedure file. The AI never guesses
hours — it selects a pattern and proposes adjustments with rationale.

**Design rule:** The AI classifies scope → selects a workflow pattern → proposes
hour adjustments with explicit rationale. No freeform pricing.

### Credo workflow patterns (skeleton — to be detailed):
1. Discovery + Requirements Clarification
2. Concept Development + Architecture
3. Detailed Design — Mechanical (CAD)
4. Detailed Design — Electrical
5. Detailed Design — Industrial Design
6. Firmware / Software Development
7. Prototype Build Support
8. Verification Planning + Test Support
9. Design for Manufacturing (DFM) / Tech Data Package
10. Program Management (overlay on any above)
11. Proposal / BD (non-billable)
12. SBIR / Government proposal support

*Hour bands by role (ME, EE, ID, SW, Tech, PM) to be populated from Credo's
historical data and ChatGPT follow-up research.*

---

## Compliance Requirements — GovCon Module

These are current as of 2026-02-21 and must be built into the GovCon procedure file:

| Item | Detail |
|------|--------|
| CMMC rollout | Phased implementation **began November 10, 2025** — active now, not future |
| NIST SP 800-171 | **Rev. 3** is the current revision (not Rev. 2) |
| SAM.gov identifier | **UEI replaced DUNS** — April 4, 2022. Any DUNS references are outdated |
| Key DFARS clause | **252.204-7012** — cybersecurity obligations + incident reporting, required for any DoD work |

---

## Architecture Components — Proposal System

ChatGPT outlined a proposal system architecture that maps well onto our modules:

| Component | What it does | Maps to our... |
|-----------|-------------|----------------|
| Intake layer | Normalizes RFPs, emails, drawings into canonical package | Estimating module intake |
| Knowledge layer | Credo internal rates, templates, past proposals; regulatory refs | Procedure files + JSON schemas |
| Retrieval + citations | Every claim cites a source | Audit log + source_map field in estimate schema |
| Orchestration (state machine) | Triage → Compliance → WBS → Estimate → Draft → QC → Approve → Publish | Estimating module phases |
| Estimation engine | Deterministic, separate from LLM — selects templates, proposes deltas | Workflow Library |
| Compliance module | DFARS clause awareness, CMMC/NIST checklists, compliance matrix | GovCon module |
| Document generation | Word/PDF output from structured payload | Output layer |
| Governance | Role-based access, audit logging, CUI partition | Audit log + hard stops |

### Proposal generation modes (interaction design for estimating module):
1. **Triage** — bid/no-bid flags, missing info, security level (CUI?), schedule realism
2. **Build Plan** — select workflow patterns, propose WBS + deliverables + assumptions
3. **Estimate** — push tasks to estimate engine, pull back hours by role + cost summary
4. **Draft** — fill proposal template from payload
5. **Review Pack** — exec summary, compliance matrix, risk register, internal red-team checklist

---

## Proposal QC Checklist (to build into estimating module)

ChatGPT identified common proposal-killers — these become automated checks before export:

- [ ] Missing sections vs. RFP requirements
- [ ] Conflicting dates (proposal date vs. schedule vs. deliverables)
- [ ] Undefined acronyms
- [ ] Assumptions that contradict requirements
- [ ] Deliverables not matched to tasks in WBS
- [ ] Travel and ODCs missing where implied by scope
- [ ] Security/compliance statements over-claiming

**Design rule:** No proposal exports without passing QC checklist. Flag items
require named human reviewer sign-off.

---

## ChatGPT Follow-Up — Completed 2026-02-21

All four items received and saved. Key artifacts created:

**Stack recommendation (Phase 0 → scale path):**
- Phase 0: Flask/FastAPI + Postgres + pgvector + Excel workbook + python-docx
- Phase 1: Add Celery/Redis job queue, stage gates, curated clause library, audit logging
- Phase 2: SSO + role-based access, CUI partition, dedicated vector store if needed
- Confirms: start simple, the architecture scales cleanly

**Artifacts saved:**
- `procedures/estimating/workflow-library.md` — 14+2 workflow templates with hour bands by role
- `schemas/opportunity.json` — canonical proposal package schema with source_ref pattern

**QC rules — saved below, to be embedded in estimating procedure file:**

### Proposal QC Checklist (from ChatGPT research)

**Scope integrity:**
- Every deliverable has at least one task (no orphan deliverables)
- Every task maps to at least one deliverable or requirement
- If prototyping/testing/travel is mentioned anywhere, it appears in WBS + estimate
- Out-of-scope items explicitly listed as exclusions

**Estimating realism:**
- Mechanical product with CAD → ME hours cannot be near zero
- Firmware deliverable → SW hours must be present
- PM hours ≥ ~5-8% of total if project has 2+ phases or 3+ disciplines
- TECH hours present when builds or tests are claimed
- Schedule text consistent with total hours and implied staffing

**Compliance / security:**
- If CUI = unknown → proposal must NOT imply CUI handling capability
- No "compliant with DFARS/CMMC" unless internal posture confirmed
- Flowdown placeholder present: "subject to prime flowdowns as received"

**Prime-friendly formatting:**
- All required sections present (even if N/A): Approach, Schedule, Deliverables,
  Assumptions/Exclusions, Pricing Summary, Terms
- Acronyms expanded on first use
- Single source of truth for: due date, place of performance, period of performance

**Contradiction checks:**
- Dates consistent across all sections
- Deliverable formats consistent (STEP vs. Parasolid vs. drawings)
- Quantities consistent throughout
- IP/data rights language doesn't contradict prime template

**Unanswered questions:**
- Clarification list included when requirements are ambiguous
- Every "shall/required" in RFQ has a response location (compliance matrix)

**Packaging:**
- Attachment set complete: resumes, past performance, reps/certs, capability statement
- File naming matches prime instructions
- Version stamp + revision log included

## Pending Research

Still waiting for results from:
- [ ] Perplexity Prompt 1: Open-source AI procedure files / GitHub repos
- [ ] Perplexity Prompt 2: Defense contractor AI tools landscape
- [ ] Gemini Prompt 5: Tools for engineering firm pursuing ISO + defense
- [ ] Gemini Prompt 6: Best practices for AI system prompt / procedure file structure

---

## Decisions Made This Session

1. **LinkedIn/BD content is a legitimate module** — add "BD Content & Defense Marketing"
   as a lightweight procedure file alongside the SAM.gov/GovCon cluster.

2. **Credo module list finalized** (see CLAUDE.md for updated build priority).

3. **Workflow Library concept adopted** for estimating module — procedure file will
   use phase patterns with hour bands, not freeform AI estimation.

4. **ISO 9001 + Document Control + CAPA treated as one build sprint** — deeply
   interconnected, audit requires all three.
