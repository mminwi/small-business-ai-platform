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

## Perplexity Prompt 1 — Completed 2026-02-21

**Question:** Do open-source AI procedure files / GitHub repos exist for SMB operations?

**Answer:** No mature SMB-focused playbook exists. Confirmed gap.

**What does exist (reference only):**
- `strands-agents/agent-sop` — Markdown SOPs with RFC 2119 language (MUST/SHOULD/MAY). Closest pattern to what we're building. Generic workflows, not domain-specific.
- `turing-machines/mentals-ai` — Markdown agent configs; more about wiring than business logic.
- `dontriskit/awesome-ai-system-prompts` — Curated system prompts in structured markdown. Useful design reference.
- `thibaultyou/prompt-library` — `prompt.md` + `metadata.yml` per prompt; local-first, Git-tracked. Interesting structure pattern.
- GitHub Copilot `*.instructions.md` pattern — Persistent markdown operating instructions for AI agents with validation gates. This is exactly our pattern.

**Key finding:** Nobody has published "Estimating SOP.md" or "Invoicing Agent SOP.md" ready to use. We are building the first real library of this type for SMB operations.

**Decision — adopt RFC 2119 language in procedure files:**
Use MUST / MUST NOT / SHOULD / MAY in procedure files going forward.
Makes instructions precise and auditable — important for GovCon and ISO contexts.
Backfill into pm-core.md on next cleanup pass.

Example:
- "The AI MUST log the time entry." (required, no exceptions)
- "The AI SHOULD notify the project lead within 24 hours." (recommended)
- "The AI MAY generate a budget summary." (optional)

## Perplexity Prompt 2 — Completed 2026-02-21

**Question:** What AI tools exist for defense contractor BD, SAM.gov, ITAR, and building a defense vendor presence?

**The gap, stated explicitly by the research:**
> "There is a noticeable lack of an integrated agent that covers: SAM.gov + other
> defense portals monitoring, ITAR-aware content guidance, relationship mapping to
> primes and PEOs, and lightweight pipeline/contract tracking tuned to 5–50 person
> defense shops."

That is Credo's exact profile. That is what we're building.

### What exists and where it falls short

| Tool | What it does | Gap |
|------|-------------|-----|
| **Samsearch** | AI layer on SAM.gov — aggregates opportunities, summarizes RFPs, capability statement drafts, win-probability scoring | Generic; no defense-specific nuance (ITAR, clearance, prime/sub strategy); doesn't integrate with engineering workflows |
| **VisibleThread** | NLP analysis of solicitations — compliance extraction, risk flags, readability | Strong at text analysis; weak at small-shop BD workflows; no ITAR awareness |
| **GovCon ERPs (various)** | AI-driven opportunity matching, past performance reuse, compliance matrices | Too heavy for small firms; require full-time contracts staff; expensive |
| **Concentric AI / PreVeil** | ITAR data classification, sensitive document discovery, access control | CISO tools, not BD tools — help you not mishandle data but don't help BD |
| **Generic AI agents** | OpenAI/Salesforce repurposed for lead gen, email follow-up, CRM updates | No FAR/DFARS knowledge; no CUI/ITAR handling; must bolt on all guardrails manually |

### Consistent gaps reported across all tools (2024-2026)

1. **"Too heavy, not SMB-native"** — tools designed for large primes; 1-3 person BD teams find them overpowered and expensive
2. **Limited defense/ITAR nuance** — tools parse text and match NAICS but don't encode security clearance requirements, exportability of subsystems, ITAR data handling, or prime/sub positioning strategy
3. **Weak integration with small shop reality** — small contractors juggle BD alongside engineering; they want an AI "BD analyst" inside their existing environment, not another portal
4. **Capability statements still feel generic** — even AI-generated ones need heavy human editing to reflect actual niche capabilities and compliance posture
5. **No end-to-end defense vendor presence assistant** — the specific gap we fill

### Closest competitor: Samsearch

Worth 30 minutes of evaluation before writing the GovCon procedure file. It's the most direct overlap with what we're building on the BD/SAM.gov side. Understanding what it does and doesn't do will sharpen the procedure file design.

### What this means for the GovCon procedure file

The SAM.gov + ITAR + GovCon procedure file must encode what no commercial tool currently does:
- Defense-specific opportunity filtering (platform names, program offices, clearance requirements)
- ITAR-aware BD content guidance (what you can/cannot say publicly, teaming constraints)
- Prime/sub positioning strategy (which primes to target, how to approach them)
- Integration with estimating and project data (something Samsearch cannot do)
- Lightweight pipeline tracking inside the owner's existing workflow

### Marketing/pitch language this research validates

*"The only AI BD assistant built for a 10-person defense engineering firm — not a watered-down version of a big-prime tool."*

## Gemini — Completed 2026-02-21

**Question:** Best practices for AI system prompt / procedure file structure + landscape

**Gap confirmed again:**
> "No widely adopted open repository of back-office AI operating procedures for small businesses."
> "Your concept sits at the intersection — and is currently underserved."

**Positioning language worth keeping:**
> "Linux for small-business AI operations."

### System Prompt Patterns (validated against our approach)

**Pattern C — SOP-Driven Agent** ← this is what our procedure files are
```
WHEN event X occurs:
1. Retrieve documents
2. Validate inputs
3. Apply rule set Y
4. Produce output Z
```

**Pattern D — State-Machine / Workflow Agent** ← relevant for estimating pipeline
```
STATE: Intake → Triage → Estimating → Drafting → QC → Submitted → Won/Lost
Transitions triggered by events or data
```

Both patterns are already in our procedure files. This validates the structure.

### Anatomy of a Mature Business Agent Prompt

What experienced builders put inside system prompts — maps directly to our procedure file sections:

| Section | What it contains | Our equivalent |
|---------|-----------------|----------------|
| Identity & scope | Role definition, authority limits, tone | "Purpose" section |
| Operating rules | Policies, regulatory constraints, decision thresholds | "Decision rules" section |
| Knowledge sources | Internal docs, databases, procedures | Loaded procedure files + JSON schemas |
| Tool usage rules | When to search, escalate, ask | "Integration points" section |
| Output requirements | Formats, templates, traceability | "Hard stops" + output specs |

### MCP — Model Context Protocol

Emerging standard for connecting agents to tools and data. Worth watching.
If we use MCP-compatible tool connectors, procedure files can reference tools
by standard names rather than custom implementations. Note for future architecture.

### Research Complete

All prompts returned. Research phase is done.

## Gemini Prompt 5 — Completed 2026-02-21

**Question:** Tools for a 12-person engineering firm pursuing ISO 9001 + defense contracting

### Open-Source Tools Worth Knowing

| Tool | What it does | Useful for us? |
|------|-------------|----------------|
| FlinkISO | Open-source QMS — document control, NCR, audit management | Know it exists; our procedure files cover same ground without extra tool |
| AppFlowy | Self-hosted Notion alternative for SOPs/knowledge base | No — Credo is Google Workspace; Drive handles this |
| VerifyWise | Open-source compliance/governance platform | Worth watching for ISO layer |
| **SAM.gov API** | Pull opportunities programmatically by NAICS + keywords | **YES — build this. Claude can write the Python script.** |
| CrewAI | Multi-agent framework for proposal "crews" | Pattern is useful; we use Claude directly instead |
| LlamaIndex | RAG over past proposals and engineering specs | Future state — MVP doesn't need it |
| OpenProject | Heavy Gantt + earned value, DoD-friendly | No — our PM module covers this |
| **Ollama + local LLMs** | Run LLM entirely offline on local hardware | **YES — solution for CUI/classified work. No data leaves the building.** |
| LangGraph | Strict multi-step workflow orchestration | Useful if we need hard pipeline enforcement |

### Two Immediately Actionable Items

**1. SAM.gov API opportunity polling**
A scheduled Python script that queries SAM.gov API for:
- Credo's NAICS codes
- Keywords: mechanical engineering, prototyping, product development, embedded systems
- Filters: set-aside type, agency, dollar threshold, due date
Outputs a daily/weekly digest of new opportunities to the owner.
This is concrete and buildable now. Goes into the GovCon procedure file.

**2. Ollama for CUI-sensitive work**
When a project is flagged CUI or potential classified:
- Switch AI inference to a local Ollama instance (Llama 3 or similar)
- No data sent to Anthropic API
- All processing stays on Credo's hardware
This is the security posture answer for sensitive defense work.
Note in GovCon procedure file as a required mode switch.

### Proposal Crew Pattern (from CrewAI concept)

Even without CrewAI framework, the pattern is sound for our estimating procedure:
- **Analyst role:** Reads RFP, extracts Section L/M requirements, compliance flags, schedule
- **Librarian role:** Searches past proposals, past performance, capability statement library
- **Writer role:** Drafts technical volume using Analyst's requirements + Librarian's content

These map to three stages in our estimating procedure file:
Triage (Analyst) → Build Plan / Workflow Selection (Librarian) → Draft (Writer)

### Note on CLAUDE.md

Gemini independently recommended:
> "Create a file called CLAUDE.md. Claude Code reads this to understand your firm's
> specific engineering standards and ISO 9001 requirements automatically."

We're already doing this. Validation.

## Gemini Prompt 6 — Completed 2026-02-21

**Question:** Best practices for AI system prompts / procedure file structure for business process automation

### Confirmed Architecture — Three-Component Hierarchy

| Component | Purpose | Our Implementation |
|-----------|---------|-------------------|
| System Prompt | The "How" — rules, persona, strict logic | Orchestrator prompt loaded every session |
| RAG Documents | The "What" — organizational knowledge, past work | JSON data + past proposals in Google Drive |
| Operating Procedures (SOPs) | The "Steps" — sequential logic for tasks | Our markdown procedure files |

These map exactly to our architecture. No gaps.

### Why NOT Fine-Tuning (important for documentation)

Three reasons fine-tuning is wrong for business process automation:
1. **Staleness** — when business rules change, you'd have to retrain. With our approach, edit a text file.
2. **Cost** — RAG is cheaper and traceable. The AI can cite exactly which rule it followed.
3. **Rigidity** — fine-tuning degrades general reasoning needed for complex tasks.

**This is a key selling point of the platform:** customers never need to retrain a model.
When Credo updates their quoting logic or ISO procedures, they edit a markdown file.

### Procedure File Format Validated

Gemini's example structure matches what we're already writing:
```
# PROCEDURE: [Name] [v2.4]
## 1. Goal
## 2. Explicit Rules (ALWAYS / NEVER)
## 3. Step-by-Step Execution
```

**Decision:** Add version numbers to procedure file headers going forward.
Format: `Version: 1.0` in header. Increment on meaningful changes.
pm-core.md already has this — keep it.

### Useful Marketing Language

> "Modular SOP files — essentially Markdown documents that serve as the AI's Employee Handbook."

This is how we explain what procedure files are to non-technical customers.

### Research Phase — Complete

All research done. All findings saved. Architecture validated from four independent sources.

## Pending Research

All research complete:
- [x] Perplexity Prompt 1: Open-source AI procedure files / GitHub repos
- [x] Perplexity Prompt 2: Defense contractor AI tools landscape
- [x] Gemini Prompt 5: Tools for ISO + defense engineering firm
- [x] Gemini Prompt 6: System prompt architecture best practices

---

## Decisions Made This Session

1. **LinkedIn/BD content is a legitimate module** — add "BD Content & Defense Marketing"
   as a lightweight procedure file alongside the SAM.gov/GovCon cluster.

2. **Credo module list finalized** (see CLAUDE.md for updated build priority).

3. **Workflow Library concept adopted** for estimating module — procedure file will
   use phase patterns with hour bands, not freeform AI estimation.

4. **ISO 9001 + Document Control + CAPA treated as one build sprint** — deeply
   interconnected, audit requires all three.
