# Workflow Library — Engineering Services
**Version:** 1.1
**Used by:** Estimating module (estimating-core.md)
**Extended by:** workflow-library-defense.md — see [small-business-govcon-platform](https://github.com/mminwi/small-business-govcon-platform)

---

## Purpose

This library contains reusable phase patterns for engineering services proposals.
The AI selects one or more templates based on project scope, then proposes
adjustments with explicit rationale. The AI never generates hours from nothing —
it always selects a template first.

**Design rule:** AI classifies scope → selects template(s) → proposes deltas
with written rationale → human reviews before numbers leave the building.

---

## Roles

| Code | Role |
|------|------|
| PM | Program / Project Manager |
| ME | Mechanical Engineer |
| EE | Electrical Engineer |
| ID | Industrial Designer |
| SW | Firmware / Software Engineer |
| TECH | Prototype Technician / Test Tech |

Hour bands are per-phase, not per-project unless noted.
ODC = Other Direct Costs (materials, travel, lab fees — listed separately).

---

## WF-01: Opportunity Triage + Bid/No-Bid + Clarifications

**Use when:** New RFQ/RFP received, need to assess before committing to full proposal

**Phases:** Intake review, missing info identification, customer questions, ROM estimate

| Role | Hours |
|------|-------|
| PM | 4–16 |
| ME | 2–8 |
| EE | 0–6 |
| ID | 0–2 |
| SW | 0–4 |
| TECH | 0 |

**Deliverables:**
- Clarification questions list (for customer)
- ROM estimate range + key assumptions
- Risk flags (compliance requirements, test requirements, onsite work)
- Bid/no-bid recommendation memo

**Standard assumptions:** Based on provided scope only
**Standard exclusions:** Detailed design, pricing below ROM level

---

## WF-02: Requirements + System Architecture (Multi-Discipline)

**Use when:** Customer needs requirements decomposition and/or top-level architecture defined before detailed design

**Phases:** Requirements decomp, interface definition, architecture trade study, selection

| Role | Hours |
|------|-------|
| PM | 12–40 |
| ME | 20–80 |
| EE | 10–60 |
| ID | 0–20 |
| SW | 10–60 |
| TECH | 0–8 |

**Deliverables:**
- Requirements list with traceability
- Interface control outline
- Trade study memo with rationale
- Architecture block diagram(s)

**Standard assumptions:** Customer provides mission scenario and constraints
**Standard exclusions:** Full verification testing, detailed design

---

## WF-03: Mechanical Concept + Packaging

**Use when:** Concept-level mechanical design — form factor, packaging, materials strategy

**Phases:** Concept CAD, packaging layouts, materials/finish strategy, sealing/thermal approach (concept level)

| Role | Hours |
|------|-------|
| PM | 8–24 |
| ME | 40–140 |
| EE | 0–20 |
| ID | 10–60 |
| SW | 0–10 |
| TECH | 0–8 |

**Deliverables:**
- Concept CAD + renders
- Candidate materials and finishes with rationale
- Concept packaging/sealing strategy notes
- Risk list (thermal, ingress, structural)

**Standard assumptions:** Concept level only; not for production release
**Standard exclusions:** Tolerance stack-up, detailed drawings unless added as separate scope

---

## WF-04: Detailed Mechanical Design + Drawing Package

**Use when:** Full detailed design through production-intent drawings and BOM

**Phases:** Detailed CAD, GD&T, drawing package, BOM, manufacturing notes, design review

| Role | Hours |
|------|-------|
| PM | 16–60 |
| ME | 120–400 |
| EE | 0–40 |
| ID | 0–40 |
| SW | 0–10 |
| TECH | 10–60 |

**Deliverables:**
- Production-intent CAD (STEP + native)
- 2D drawings with GD&T + BOM
- Assembly drawing + exploded view
- Design review presentation package

**Standard assumptions:** Customer reviews and approves at design review
**Standard exclusions:** Supplier-managed tolerancing; specialized deliverable formatting unless explicitly required

---

## WF-05: Electrical Design — PCB + Harness + Power

**Use when:** Electronic design for embedded or industrial product — schematics through layout and bring-up

**Phases:** Requirements, schematics, PCB layout support, harness definition, bring-up plan

| Role | Hours |
|------|-------|
| PM | 12–40 |
| ME | 10–60 |
| EE | 120–450 |
| ID | 0–10 |
| SW | 40–200 |
| TECH | 20–120 |

**Deliverables:**
- Schematics + BOM
- Layout constraints and package notes
- Harness pinout + drawing
- Bring-up and test plan (EE/SW)

**Standard assumptions:** Component availability subject to market conditions
**Standard exclusions:** EMI/EMC certification testing; firmware feature-complete unless defined as separate scope

---

## WF-06: Embedded Firmware — MVP (Prototype-Ready)

**Use when:** Firmware needed to make prototype functional for testing or demonstration

**Phases:** Architecture, drivers, communications, basic UI/telemetry, test hooks

| Role | Hours |
|------|-------|
| PM | 12–40 |
| ME | 0–20 |
| EE | 20–80 |
| ID | 0–10 |
| SW | 160–600 |
| TECH | 10–60 |

**Deliverables:**
- Firmware baseline + build instructions
- Minimal functional specification
- Bench test procedure
- Release notes

**Standard assumptions:** Target hardware available; requirements defined before coding starts
**Standard exclusions:** Security hardening; formal verification; production-grade reliability unless specified

---

## WF-07: Prototype Build Support (In-House + Vendor)

**Use when:** Physical prototype needs to be built — coordinating fabrication, assembly, and initial fit checks

**Phases:** Vendor coordination, build documentation, fit checks, assembly and test execution support

| Role | Hours |
|------|-------|
| PM | 8–40 |
| ME | 20–120 |
| EE | 10–80 |
| ID | 0–10 |
| SW | 0–60 |
| TECH | 60–300 |

**Deliverables:**
- Build traveler + assembly instructions
- Prototype issues log
- Updated CAD/drawings reflecting build changes

**Standard assumptions:** Prototype parts procurement is pass-through ODC (not in labor)
**Standard exclusions:** Schedule depends on vendor lead times — add contingency explicitly

---

## WF-08: Test Planning + Verification Execution

**Use when:** Formal test planning and execution needed — functional, environmental, or performance verification

**Phases:** Test plan, fixture design/fab, test execution, results summary, corrective actions

| Role | Hours |
|------|-------|
| PM | 12–60 |
| ME | 40–180 |
| EE | 20–160 |
| ID | 0–10 |
| SW | 10–120 |
| TECH | 80–400 |

**Deliverables:**
- Test plan + requirements traceability matrix
- Test reports + raw data package
- Issue list + disposition recommendations
- Updated requirements as needed

**Standard assumptions:** Test profiles defined by customer or agreed specification
**Standard exclusions:** Accredited lab testing (add as ODC if needed); environmental chambers may be ODC

---

## WF-09: Ruggedization for Field or Industrial Use

**Use when:** Existing or concept design needs to be hardened for a demanding field or industrial environment

**Phases:** Weak-point identification, redesign for environment, sealing strategy, thermal path, fastener strategy

| Role | Hours |
|------|-------|
| PM | 12–40 |
| ME | 60–220 |
| EE | 10–80 |
| ID | 0–20 |
| SW | 0–20 |
| TECH | 10–60 |

**Deliverables:**
- Ruggedization change list with rationale
- Updated CAD and drawings
- Risk reduction plan

**Standard assumptions:** Starting design exists; customer defines target environment
**Standard exclusions:** Formal qualification testing unless separately scoped

---

## WF-10: EMI/EMC Design-for-Compliance (Pre-Compliance Support)

**Use when:** Product needs to meet EMI/EMC requirements — design support, not formal testing

**Phases:** Bonding/grounding strategy, gasket strategy, cable/harness filtering, pre-scan support

| Role | Hours |
|------|-------|
| PM | 8–24 |
| ME | 40–160 |
| EE | 40–200 |
| ID | 0–10 |
| SW | 0–20 |
| TECH | 20–120 |

**Deliverables:**
- EMI design plan + grounding scheme
- Design rules checklist
- Pre-compliance test support summary

**Standard assumptions:** Target standard defined (FCC, CE, MIL-STD-461, or other — specify)
**Standard exclusions:** Formal compliance testing (lab fee ODC); results depend on test setup quality

---

## WF-11: DFM/DFA + Supplier Handoff

**Use when:** Design moving toward production — needs drawing cleanup, tolerance rationalization, assembly simplification, supplier Q&A

**Phases:** Drawing cleanup, tolerance review, assembly simplification, supplier package, Q&A support

| Role | Hours |
|------|-------|
| PM | 8–40 |
| ME | 60–220 |
| EE | 10–80 |
| ID | 0–20 |
| SW | 0–10 |
| TECH | 0–20 |

**Deliverables:**
- DFM/DFA report with recommended changes
- Updated drawings and BOM
- Supplier Q&A log + incorporated changes

**Standard assumptions:** Customer provides supplier selection; we support their package
**Standard exclusions:** Tool design; production launch; incoming inspection

---

## WF-12: Sustainment + Field Issue Response

**Use when:** Product is fielded and failures need root cause analysis and corrective action

**Phases:** Failure triage, root cause support, corrective action definition, engineering change + release

| Role | Hours |
|------|-------|
| PM | 8–60 |
| ME | 20–180 |
| EE | 10–160 |
| ID | 0–10 |
| SW | 10–140 |
| TECH | 10–120 |

**Deliverables:**
- Failure analysis memo
- Engineering change list + revised files
- Verification retest summary

**Standard assumptions:** Access to failed units and/or field data required
**Standard exclusions:** Warranty policy decisions; volume repair/rework execution

---

## How to Use This Library

When a new proposal comes in:

1. Read the scope text and identify which workflow templates apply
2. Select the matching templates — most proposals use 2–5 templates in sequence
3. For each selected template, note any reasons to adjust hours up or down:
   - **Adjust up:** First-of-kind work, ambiguous requirements, new customer, tight schedule
   - **Adjust down:** Company has done this type of work before, requirements well-defined, customer provides inputs
4. Write the adjustment rationale explicitly — it goes into the proposal assumptions section
5. Sum hours across all selected templates by role → feed into estimate summary

**The AI's job is selection + rationale. The pricing spreadsheet does the math.**
