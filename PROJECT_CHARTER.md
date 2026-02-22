# Project Charter: Small Business AI Software Platform
## "The Vending Machine" — Turnkey AI-Powered Business Systems for Small Companies

**Version:** 1.0  
**Date:** February 2026  
**Author:** Mike Maier
**Status:** Draft — Pending Claude Code Development

---

## 1. Executive Summary

This project delivers a turnkey, AI-powered business software platform targeted at small companies (1–20 employees) who need enterprise-grade business systems but cannot justify the cost, complexity, or overhead of traditional ERP or MRP software.

The platform is delivered as a **one-time purchase** ($500–$4,000 depending on tier), installed directly into the customer's existing Google Workspace or Microsoft 365 account. Claude (Anthropic LLM) serves as the AI backbone across all modules — acting as the virtual back-office assistant, data entry operator, scheduler, and customer service agent.

The system is built entirely on **markdown files and JSON data structures** to remain maximally flexible as AI capabilities improve. No hard-coded business logic. The platform improves automatically as the underlying LLM improves.

---

## 2. Problem Statement

Small service businesses — plumbers, caterers, graphic designers, small manufacturers, military veteran entrepreneurs — face a specific gap:

- They are too small for enterprise ERP ($4,000+/year, months to implement)
- They are too complex for basic spreadsheets and paper systems
- They do not have IT staff or programming knowledge
- They do not know what systems they need or how to implement them
- They cannot afford to hire the additional staff that would otherwise handle back-office functions

The result: these businesses operate inefficiently, miss opportunities, fail compliance audits, and spend owner time on administrative tasks instead of their core trade.

---

## 3. Solution Overview

A **vending machine for business software** — the customer selects their industry/business type, pays once, and receives a fully configured, AI-powered business system installed in their existing cloud account.

**Core principles:**
- Works within tools they already have (Google Workspace or Microsoft 365, QuickBooks)
- One-time fee, no ongoing subscription beyond their existing accounts
- Claude handles the intelligence layer — data entry, scheduling optimization, customer chat, compliance guidance
- Systems are built on proven, well-documented frameworks (ISO 9001, MS Project equivalents, standard MRP) but scaled and simplified to what a small company actually needs
- Everything is markdown and JSON — no hard-coded logic — so the platform improves as AI improves
- Owner does not need to understand the underlying system; they just use it

---

## 4. Business Model

### Tier 1 — Standard Small Business Package: $500 (one-time)
**Target:** Plumbers, caterers, graphic designers, service businesses 1–10 employees  
**Includes:** CRM, scheduling, project management, basic invoicing/QuickBooks integration, inventory basics, help desk log, AI chat assistant  
**Delivery:** Installed in Google Workspace account; ~2 hours setup  
**Support:** Documentation + AI self-service  

### Tier 2 — Manufacturer/Compliance Package: $1,500 (one-time)
**Target:** Small manufacturers, suppliers to larger companies needing ISO compliance, companies needing quality audits (e.g., supplying GE, aerospace, medical)  
**Includes:** All Tier 1 + full ISO 9001 QMS, document control, CAPA, BOM, work orders, supplier management, vendor management  
**Delivery:** Installed in Google Workspace or Microsoft 365; ~4–6 hours setup, some hands-on assistance  
**Support:** Initial onboarding session included  

### Tier 3 — Government/Military Contractor Package: $2,000–$4,000 (one-time)
**Target:** Small businesses pursuing government contracts, retired military starting businesses, inventors seeking government funding  
**Includes:** All Tier 2 + SAM.gov registration guidance, small business certifications (8a, HUBZone, SDVOSB), CAGE/UEI setup, ITAR/export control basics, government contract tracking  
**Delivery:** Hands-on setup assistance from Mike or team member; 8–16 hours  
**Support:** Included onboarding + documentation  

### Revenue Model
- One-time purchase per customer
- Future revenue: annual refresh/update packages as platform improves (~$200/year optional)
- Referral program for installers/consultants

---

## 5. Technical Architecture

### 5.1 Infrastructure Stack

| Layer                | Technology                                    |
| -------------------- | --------------------------------------------- |
| Primary Cloud        | Google Workspace (preferred) or Microsoft 365 |
| Accounting           | QuickBooks Online (customer-supplied)         |
| AI Engine            | Claude API (Anthropic)                        |
| Data Format          | Markdown (.md) + JSON (.json)                 |
| Document Storage     | Google Drive or SharePoint                    |
| Spreadsheets/Reports | Google Sheets or Excel                        |
| Forms/Intake         | Google Forms or Microsoft Forms               |
| Customer Chat        | Custom AI interface via Claude API            |
| Code/Scripts         | Python or JavaScript (minimal, AI-generated)  |

### 5.2 Agent Architecture — Three-Tier System

All intelligence in the system runs through Claude. The system is organized in three tiers:

**Tier 1 — Top-Level Orchestrator**
- Receives high-level business requests (voice or text)
- Routes to appropriate module coordinator
- Manages context across modules
- Handles cross-module queries (e.g., "What jobs are scheduled this week and what parts do I need?")

**Tier 2 — Module Coordinators**
- One coordinator per major module (CRM, Project Management, Quality, etc.)
- Understands the full scope of their domain
- Breaks requests into specific tasks for task agents
- Maintains module-level context and state

**Tier 3 — Task Agents**
- Single-purpose agents for specific operations
- Examples: "create work order," "log customer call," "generate CAPA report," "check inventory level"
- Reads and writes to markdown/JSON data files
- Returns structured results to coordinator

**Data Exchange Format:** All inter-agent communication uses JSON. All specifications, procedures, and business logic live in markdown files. This ensures the system improves automatically as Claude's ability to interpret markdown improves.

### 5.3 Design Principles

1. **No hard-coded business logic** — all rules and procedures live in markdown files that Claude interprets
2. **Markdown-first** — every system specification, procedure, and workflow is documented in markdown
3. **JSON for data** — all structured data uses JSON schemas; no proprietary database formats
4. **Minimum viable implementation** — start with full framework documentation, scale back to what the customer actually needs; can scale up as company grows
5. **AI-improves-automatically** — as Claude gets smarter, the system gets smarter without code changes
6. **Platform-agnostic** — designed for Google Workspace but adaptable to Microsoft 365

---

## 6. Module Inventory

The platform consists of 20 modules organized in 5 categories. Each module has:
- A Perplexity-researched technical specification (in /specs/)
- A markdown procedure file (in /procedures/)
- A JSON schema file (in /schemas/)
- Claude prompts for the module coordinator and task agents (in /prompts/)

### Category A — Business Operations Core
| #    | Module                                         | Tier |
| ---- | ---------------------------------------------- | ---- |
| 01   | Contact & Customer Management (CRM)            | 1+   |
| 02   | Project Management (Scaled-Down)               | 1+   |
| 03   | Scheduling & Dispatch                          | 1+   |
| 04   | Invoicing & Estimates (QuickBooks Integration) | 1+   |

### Category B — MRP / Operations
| #    | Module                       | Tier |
| ---- | ---------------------------- | ---- |
| 05   | Inventory & Parts Management | 1+   |
| 06   | Bill of Materials (BOM)      | 2+   |
| 07   | Work Orders & Job Tracking   | 1+   |
| 08   | Supplier & Vendor Management | 2+   |

### Category C — Quality & Compliance
| #    | Module                                       | Tier |
| ---- | -------------------------------------------- | ---- |
| 09   | ISO 9001 Quality Management (Small Business) | 2+   |
| 10   | Document Control                             | 2+   |
| 11   | Corrective Action & Nonconformance (CAPA)    | 2+   |
| 12   | Help Desk & Troubleshooting Log              | 1+   |

### Category D — Government & Military Vendor
| #    | Module                                         | Tier |
| ---- | ---------------------------------------------- | ---- |
| 13   | SAM.gov Registration & Government Vendor Setup | 3    |
| 14   | ITAR / Export Control Basics                   | 3    |
| 15   | Government Contract Tracking                   | 3    |

### Category E — Customer Facing & AI Infrastructure
| #    | Module                                 | Tier |
| ---- | -------------------------------------- | ---- |
| 16   | Basic Website & Landing Page           | 1+   |
| 17   | Customer Chat / AI Help Desk Interface | 1+   |
| 18   | AI Agent Orchestration Layer           | All  |
| 19   | QuickBooks Online API Integration      | 1+   |
| 20   | Google Workspace Integration           | 1+   |

---

## 7. Development Approach

### Phase 1 — Research & Specification (Current Phase)
1. Run all 20 Perplexity research prompts (see `perplexity_research_prompts.md`)
2. Save each response as `/specs/XX_modulename_spec.md`
3. Review and annotate specs — identify what applies to small business scale vs. enterprise
4. Build JSON schemas for each module based on spec findings

### Phase 2 — Architecture Design
1. Feed project charter + all specs into Claude Code
2. Have Claude Code generate the agent architecture framework
3. Define inter-agent communication contracts (JSON schemas)
4. Build the orchestrator prompt template
5. Build coordinator prompt templates for each module

### Phase 3 — Module Development (per module)
1. Build markdown procedure files based on specs
2. Generate JSON schemas for data structures
3. Build and test Claude prompts for task agents
4. Test with sample data
5. Iterate and refine

### Phase 4 — Integration
1. QuickBooks API integration layer
2. Google Workspace API integration layer
3. End-to-end testing per business type (plumber, manufacturer, government contractor)

### Phase 5 — Packaging & Delivery
1. Build customer onboarding workflow
2. Create installation scripts/procedures
3. Build customer-facing website
4. Develop pricing and sales materials

---

## 8. Tools & Accounts Available

| Tool                          | Purpose                                                      |
| ----------------------------- | ------------------------------------------------------------ |
| Claude (claude.ai + API)      | Primary AI engine; chat, code generation, agent development  |
| Claude Code (CLI)             | Project file management, code generation, architecture development |
| Perplexity                    | Domain research; generating technical specifications per module |
| Google Workspace / Google One | Primary delivery platform; also used for project files       |
| Microsoft 365                 | Secondary delivery platform; also available for development  |
| QuickBooks Online             | Accounting integration (customer-supplied)                   |
| Gemini                        | Supplemental AI research                                     |
| Grok                          | Supplemental AI research                                     |
| ChatGPT                       | Supplemental AI assistance                                   |

---

## 9. Directory Structure (Claude Code Project)
```
/small-business-ai-platform/
├── PROJECT_CHARTER.md          ← This document
├── perplexity_research_prompts.md  ← All 20 research prompts
├── /specs/                     ← Perplexity research outputs (one per module)
│   ├── 01_crm_spec.md
│   ├── 02_project_management_spec.md
│   └── ... (all 20 modules)
├── /schemas/                   ← JSON data schemas per module
│   ├── crm_schema.json
│   ├── project_schema.json
│   └── ...
├── /procedures/                ← Markdown procedure files per module
│   ├── crm_procedures.md
│   └── ...
├── /prompts/                   ← Claude agent prompts
│   ├── orchestrator_prompt.md
│   ├── crm_coordinator_prompt.md
│   └── ...
├── /integrations/              ← API integration specs
│   ├── quickbooks_integration.md
│   └── google_workspace_integration.md
└── /delivery/                  ← Customer delivery templates
    ├── tier1_plumber_package/
    ├── tier2_manufacturer_package/
    └── tier3_government_package/
```

---

## 10. Next Steps — Immediate Actions

1. **Save this charter** as `PROJECT_CHARTER.md` in your project folder
2. **Save the Perplexity prompts file** as `perplexity_research_prompts.md` in the same folder
3. **Run Perplexity research** — work through all 20 prompts, save responses to `/specs/`
4. **Set up Claude Code** — see `CLAUDE_CODE_SETUP.md` for step-by-step instructions
5. **Feed charter + specs into Claude Code** — use the onboarding prompt below

---

## 11. Claude Code Onboarding Prompt

Once you have your project folder set up with this charter and at least a few spec files, use this prompt to kick off Claude Code:
```
I am building a small business AI software platform called "The Vending Machine." 
The project charter is in PROJECT_CHARTER.md. Technical specifications for each 
module are in the /specs/ directory.

Please review the project charter and available specs, then:
1. Confirm you understand the overall architecture and business model
2. Identify any gaps or inconsistencies in the current documentation
3. Propose a JSON schema for the AI agent orchestration layer (3-tier architecture)
4. Create a directory structure for the project if it doesn't already exist
5. Suggest which module we should build first based on dependencies

All business logic should live in markdown files. All data structures should be JSON.
Minimize hard-coded logic. The system should improve automatically as Claude's 
capabilities improve over time.
```

---

## 12. Key Design Decisions & Rationale

| Decision                                  | Rationale                                                    |
| ----------------------------------------- | ------------------------------------------------------------ |
| Markdown + JSON only, no hard-coded logic | System improves as LLM improves; no code obsolescence        |
| Google Workspace as primary platform      | Most common in small business; familiar; free tier available |
| QuickBooks for accounting, not custom     | Audit complexity too high; API integration is sufficient     |
| One-time fee vs subscription              | Removes barrier for cash-strapped small businesses           |
| Pre-built by industry, not custom         | 80/20 rule — most businesses in a vertical need the same things |
| Three-tier agent architecture             | Scalable; each layer has clear responsibility; Claude handles all tiers |
| Perplexity research first, then build     | Ensures Claude Code has domain knowledge before architecting |
| Start with full framework, scale back     | Easier to remove features than add; ensures completeness     |

---

*End of Project Charter v1.0*  
*Next document: CLAUDE_CODE_SETUP.md*