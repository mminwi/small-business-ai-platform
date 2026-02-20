# Perplexity Research Prompts — Small Business AI Software Platform

## Purpose
Run each prompt in Perplexity (Focus: All, no page limit). 
Save each response as a separate markdown file in your /specs directory.
Example: 01_crm_spec.md, 02_project_management_spec.md, etc.

---

## 01 — Contact & Customer Management (CRM)
"I am building a lightweight CRM for small service businesses (1-10 employees) like plumbers, caterers, and graphic designers. Provide a detailed technical specification covering: data structures and schema for contacts, companies, leads, opportunities, and interaction history; core workflows for lead capture and contact lifecycle; Google Workspace integration (Gmail, Calendar, Contacts API); QuickBooks Online customer sync patterns; how AI agents could automate data entry and follow-up. Include field-level data definitions, entity relationships, and JSON schema examples. Target depth: software architect level, 15-25 pages."

---

## 02 — Project Management (Scaled-Down)
"I am building a project management module for small service businesses (1-10 employees) capturing the essential 20% of MS Project or Asana that delivers 80% of the value. Provide a detailed technical specification covering: data structures for projects, tasks, milestones, dependencies, and resource assignments; scheduling logic including basic critical path and deadline tracking; project status and health indicators; Google Calendar and Sheets integration; how AI could interpret plain-language updates and convert them to structured task data; comparison of full MS Project vs what a 3-person company actually needs. Include JSON schema examples and field-level definitions. Target: 15-25 pages."

---

## 03 — Scheduling & Dispatch
"I am building a scheduling and dispatch module for small field service businesses (plumbers, electricians, HVAC) with 1-10 employees. Provide a detailed technical specification covering: data structures for jobs, appointments, technician availability, and service territories; scheduling logic with conflict detection and priority queuing; dispatch workflow from customer call to job completion; Google Calendar API integration; customer notification workflows; AI-based schedule optimization by location and skill set; mobile data access patterns for field techs. Include JSON schema, workflow state descriptions, and field definitions. Target: 15-25 pages."

---

## 04 — Invoicing & Estimates (QuickBooks Integration)
"I am building an invoicing and estimating module for small businesses with deep QuickBooks Online integration. Provide a detailed technical specification covering: QuickBooks Online API architecture including OAuth 2.0, endpoints for customers/invoices/estimates/payments/items; data structures for estimates, line items, labor rates, materials, and markup; workflow from estimate through approval to invoice and payment tracking; bidirectional QuickBooks sync patterns; data mapping challenges between a custom system and QuickBooks data model; AI-generated estimates from plain-language job descriptions; tax handling basics. Include JSON schema, API call sequences, and field mapping tables. Target: 15-25 pages."

---

## 05 — Inventory & Parts Management
"I am building an inventory and parts management module for small service businesses and light manufacturers with 1-20 employees. Provide a detailed technical specification covering: data structures for parts, SKUs, locations, quantities, reorder points, and suppliers; transaction types including receipts, issues, returns, and adjustments; reorder logic and PO generation; QuickBooks inventory valuation integration; barcode/QR scanning patterns for mobile use; AI-based reorder prediction from usage history; comparison of full MRP inventory vs what a small company needs. Include JSON schema, relationship maps, and field definitions. Target: 15-25 pages."

---

## 06 — Bill of Materials (BOM)
"I am building a Bill of Materials module for small manufacturers with 1-20 employees. Provide a detailed technical specification covering: data structures for single and multi-level BOMs including part numbers, quantities, units of measure, and substitutions; BOM revision control and change management; cost rollup logic from raw materials through assemblies; inventory integration for material availability checks; QuickBooks cost accounting integration; AI assistance for building or validating BOMs from plain-language descriptions; comparison of full ERP BOM functionality vs small manufacturer needs. Include JSON schema, hierarchy data patterns, and field definitions. Target: 15-25 pages."

---

## 07 — Work Orders & Job Tracking
"I am building a work order and job tracking module for small service businesses and light manufacturers with 1-20 employees. Provide a detailed technical specification covering: data structures for work orders including job details, assigned staff, materials used, labor hours, status, and completion notes; work order lifecycle from creation through closure; time tracking and labor cost capture; inventory integration for material consumption; invoicing integration for billing from completed work orders; mobile data entry for field/shop floor workers; AI assistance for work order creation and post-completion report generation. Include JSON schema, workflow state machines, and field definitions. Target: 15-25 pages."

---

## 08 — Supplier & Vendor Management
"I am building a supplier and vendor management module for small businesses with 1-20 employees. Provide a detailed technical specification covering: data structures for vendors, contacts, price lists, lead times, payment terms, and performance ratings; purchase order creation, approval, and receipt workflows; vendor performance tracking for on-time delivery and quality; QuickBooks accounts payable integration; RFQ workflow for competitive bids; AI vendor evaluation and performance flagging; comparison of full ERP procurement vs small business needs. Include JSON schema, workflow descriptions, and field definitions. Target: 15-25 pages."

---

## 09 — ISO 9001 Quality Management (Small Business)
"I am building a lightweight ISO 9001:2015-compliant quality management system for small companies with 1-20 employees needing to pass supplier audits. Provide a detailed technical specification covering: core ISO 9001:2015 requirements most critical for small company audits; data structures for quality manual, procedures, work instructions, and records; internal audit scheduling and checklist management; management review documentation; customer satisfaction tracking; supplier evaluation records; minimal audit-ready QMS structure in Google Drive or SharePoint; AI assistance for generating and maintaining QMS documentation. Include data structures, document hierarchy maps, and record-level field definitions. Target: 20-30 pages."

---

## 10 — Document Control
"I am building a document control module for small businesses needing ISO 9001 or similar compliance, with 1-20 employees. Provide a detailed technical specification covering: data structures for controlled documents including revision history, approval status, distribution lists, and review schedules; document lifecycle from creation through approval, release, and obsolescence; change control workflows with approval routing and notification; Google Drive or SharePoint integration as document repository; document numbering schemes and revision control implementation; AI assistance for document drafting, gap analysis, and change impact assessment; minimum viable document control for ISO audit readiness. Include JSON schema for document metadata, workflow states, and field definitions. Target: 15-25 pages."

---

## 11 — Corrective Action & Nonconformance Tracking (CAPA)
"I am building a CAPA and nonconformance tracking module for small businesses seeking ISO 9001 compliance with 1-20 employees. Provide a detailed technical specification covering: data structures for nonconformance reports, root cause analysis, corrective actions, and effectiveness verification; CAPA workflow from issue identification through root cause, action planning, implementation, and closure; 5-Why and fishbone data structures; quality metrics and trending; document control integration for procedure updates; AI assistance with root cause suggestions and CAPA effectiveness prediction; minimal audit-ready CAPA system design. Include JSON schema, workflow state machines, and field definitions. Target: 15-25 pages."

---

## 12 — Help Desk & Troubleshooting Log
"I am building a help desk and troubleshooting log module for small businesses with 1-20 employees, including an AI-powered customer chat interface. Provide a detailed technical specification covering: data structures for tickets, issues, resolutions, customers, assets, and knowledge base articles; ticket lifecycle from intake through triage, resolution, and closure; knowledge base structure for storing and retrieving solutions; AI chat interface architecture using an LLM with a business-specific knowledge base; escalation workflows when AI cannot resolve; CRM integration for customer history; help desk performance metrics; self-improving knowledge base where resolved tickets feed AI. Include JSON schema, workflow descriptions, and field definitions. Target: 15-25 pages."

---

## 13 — SAM.gov Registration & Government Vendor Setup
"I am building a government vendor onboarding module to help small businesses register as government contractors, particularly targeting small manufacturers and retired military starting businesses. Provide a detailed technical specification covering: step-by-step SAM.gov registration data requirements including UEI, CAGE code, NAICS codes, and banking; small business certification programs (8a, HUBZone, SDVOSB, WOSB) eligibility requirements and application data; government purchase card acceptance setup; data structures for tracking certifications, expiration dates, and renewals; contract opportunity research on SAM.gov; compliance pitfalls for small businesses; AI-guided navigation of registration process. Include data structures, workflow checklists, and field definitions for all registrations. Target: 20-30 pages."

---

## 14 — ITAR / Export Control Basics
"I am building an ITAR and export control compliance module for small manufacturers with 1-20 employees supplying to defense contractors or government agencies. Provide a detailed technical specification covering: overview of ITAR and EAR and which applies to which product types; data structures for controlled items, authorized recipients, export licenses, and compliance records; screening workflows against denied party lists; required compliance documentation and record-keeping; technology control plan basics for small companies; AI assistance for ITAR classification and compliance documentation; common violations small companies inadvertently commit. Note: guidance and documentation support only, not legal advice. Include data structures, compliance workflows, and field definitions. Target: 15-25 pages."

---

## 15 — Government Contract Tracking
"I am building a government contract tracking module for small businesses with active or pursuing government contracts, 1-20 employees. Provide a detailed technical specification covering: data structures for contracts, task orders, CLINs, periods of performance, funding, and deliverables; contract lifecycle from opportunity through proposal, award, execution, and closeout; deliverable tracking and reporting requirement management; government billing integration (SF1034, Wide Area Workflow); subcontractor management for prime/sub relationships; contract modification and option tracking; AI assistance for contract data extraction from award documents and deliverable scheduling. Include JSON schema, workflow descriptions, and field definitions. Target: 15-25 pages."

---

## 16 — Basic Website & Landing Page Generation
"I am building a website generation module for small service businesses with 1-10 employees who have no web presence. Provide a detailed technical specification covering: minimum viable website structure for a service business including pages, content sections, and conversion elements; data structures for business information, services, testimonials, and contact forms; Google Business Profile API integration for local SEO; contact form to CRM lead pipeline; hosting options compatible with Google Workspace; AI-generated website copy from a business description; local SEO basics for service businesses. Include content structure templates, data field definitions, and integration architecture. Target: 10-20 pages."

---

## 17 — Customer Chat / AI Help Desk Interface
"I am building an AI-powered customer-facing chat interface for small service businesses with 1-10 employees, allowing customers to ask questions, get quotes, and report issues without a human available. Provide a detailed technical specification covering: architecture for an AI chat system using an LLM API with a business-specific knowledge base; data structures for conversation history, customer identification, intent classification, and escalation triggers; knowledge base ingestion pipeline for business-specific information; handoff workflows from AI to human agent; CRM integration for logging conversations; guardrails to keep AI on-topic and prevent unauthorized commitments; chat performance analytics and common question tracking. Include architecture descriptions, JSON schema, and workflow descriptions. Target: 15-25 pages."

---

## 18 — AI Agent Orchestration Layer
"I am building a multi-agent AI orchestration system where Claude (Anthropic LLM) serves as the primary intelligence across a small business software platform. The system has three tiers: top-level orchestrator, mid-level module coordinators, and individual task agents. Provide a detailed technical specification covering: agent orchestration patterns (supervisor-worker, pipeline, event-driven); data structures for task queues, context passing, inter-agent communication, and result aggregation; using markdown files and JSON as the primary data interchange between agents; prompt engineering patterns for giving Claude agents clear bounded roles; error handling and fallback patterns; structuring markdown-based specifications so the system improves as the LLM improves; practical Claude API implementation including tool use and context management. Include architecture descriptions, JSON schema for agent communication, and prompt template patterns. Target: 20-30 pages."

---

## 19 — QuickBooks Online API Integration
"I am building a deep integration layer between a custom software platform and QuickBooks Online. Provide a detailed technical specification covering: QuickBooks Online REST API architecture, OAuth 2.0 flow, webhook events, and rate limits; complete data model mapping between QuickBooks entities (Customer, Vendor, Invoice, Bill, Payment, Item, Account, Employee) and a custom platform; real-time webhook vs batch sync patterns and conflict resolution; error handling for failed API calls and data validation; sandbox testing approach; which data should be mastered in QuickBooks vs the custom platform; AI natural language to QuickBooks API query translation. Include JSON schema for key API payloads, data mapping tables, and integration architecture. Target: 15-25 pages."

---

## 20 — Google Workspace Integration
"I am building a deep integration layer between a custom small business software platform and Google Workspace (Gmail, Calendar, Drive, Sheets, Docs, Contacts). Provide a detailed technical specification covering: Google Workspace API architecture including OAuth 2.0, service accounts, and available APIs per product; Gmail integration for CRM email logging and AI-assisted drafting; Google Calendar integration for scheduling and project milestones; Google Drive integration for document control and folder structure management; Google Sheets integration for reporting and dashboards; Google Contacts CRM sync; structuring Google Drive as a document management system; how AI agents could interact with Google Workspace on behalf of users. Include API call sequences, data mapping examples, and integration architecture. Target: 15-25 pages."

---

*Save each Perplexity response as /specs/01_crm_spec.md, /specs/02_project_management_spec.md, etc.*
*These specs become the foundation for Claude Code to architect and build each module.*