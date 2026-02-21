# Procedure: Estimating + Proposals — GovCon Extension
**Version:** 1.0
**Extends:** estimating-core.md (read that file first — this file adds to it, does not replace it)
**Applies to:** Government solicitations — SBIR, STTR, BAA, RFP, RFQ with DFARS clauses,
prime subcontract flowdowns
**Requires:** workflow-library.md, schemas/opportunity.json, schemas/ratesets.json
**Last updated:** 2026-02-21

---

## Purpose

This file extends the commercial estimating procedure for government and defense work.
Load it when `govcon.applicable` is true in the opportunity record, or when the
customer is a government agency, DoD prime, or federally-funded research program.

Everything in `estimating-core.md` still applies. This file adds GovCon-specific
intake steps, compliance checks, proposal structures, and hard stops.

**If you are not certain whether work is GovCon, assume it is and run this checklist.**

---

## GovCon Opportunity Types

Know which type you are working with — each has different structure and rules.

| Type | Description | Notes |
|------|-------------|-------|
| SBIR Phase I | Small Business Innovation Research — feasibility | Strict page/word limits; fixed budget ceiling |
| SBIR Phase II | Full R&D following Phase I award | Larger budget; commercialization required |
| STTR | Like SBIR but requires a research institution partner | Confirm partner agreement before bidding |
| BAA | Broad Agency Announcement — open solicitation | Less structured than RFP; innovation-driven |
| RFP | Request for Proposal — competitive procurement | Must follow Section L exactly; Section M drives scoring |
| RFQ | Request for Quote — usually simpler/lower dollar | May be sole-source or competitive |
| Sub (flowdown) | the company as subcontractor under a prime | Prime sends Statement of Work + flowdown clauses |

Identify the type at intake. It determines everything downstream.

---

## Intake — Additional Steps for GovCon

After creating the opportunity record per `estimating-core.md`, run these steps:

### 1. Read the solicitation, not just the summary
For RFPs: read Section L (instructions to offerors) and Section M (evaluation criteria)
before doing anything else. Section M tells you how you will be scored. Build the
proposal to score well on Section M, not just to answer the technical question.

For SBIR: read the full topic description, including subtopics, Phase I objectives,
and any linked background documents. The topic manager's intent is in the details.

For BAA: read the full announcement. Note the focus areas, evaluation factors,
and any stated preferences. BAAs often reward novelty over completeness.

### 2. Confirm SAM.gov active registration
Before committing any proposal effort, verify:
- the company's UEI is active in SAM.gov (UEI replaced DUNS on April 4, 2022)
- CAGE code is active
- Registration expiration date — if expiring within 90 days, flag to renew now
- Size standard matches NAICS code on the solicitation

**Do not proceed if SAM.gov registration is expired or expiring during the
period of performance.** This is a disqualifying issue.

### 3. Run the compliance flag scan (see below)
Before any estimate or proposal work begins.

### 4. Identify prime vs. sub role
- **Prime:** the company submits directly to the government. the company owns the relationship
  and the deliverables.
- **Subcontractor:** the company performs work under a prime's contract. You need the
  prime's Statement of Work and their flowdown clauses before starting. Do not
  accept pricing obligations before reviewing the flowdowns.

---

## Compliance Flag Scan

Run this on every GovCon opportunity at intake. Flag each item — do not proceed
past this step until the user has acknowledged the flags.

**CUI (Controlled Unclassified Information):**
- Does the solicitation reference CUI, FOUO, or export-controlled technical data?
- If yes or unknown: flag. CUI cannot be handled on standard commercial systems.
  Do not draft proposals using CUI content without confirming the handling environment.

**ITAR / EAR:**
- Does the technology involve defense articles, military systems, or dual-use items?
- If yes or unknown: flag. No export-controlled technology details in a proposal
  without an export control review. This applies even to unclassified proposals.
- Note in `compliance.itar` and `compliance.ear` fields.

**DFARS 252.204-7012:**
- Is this any DoD work, including subcontracts?
- If yes: note the cybersecurity clause. the company must have a System Security Plan
  and adequate security on any system storing covered defense information.
- This is an awareness flag, not a blocker — but it must be documented.

**CMMC:**
- What CMMC level does the solicitation require?
- CMMC phased rollout began November 10, 2025. Level 2 requires a third-party
  assessment (C3PAO). Do not claim CMMC Level 2 compliance without that assessment.
- Note in `compliance.cmmc_level_target`.

**NIST SP 800-171:**
- If required, confirm which revision — current version is Rev. 3, not Rev. 2.
- Flag if the solicitation specifies a revision.

**Clearance:**
- Does the work require personnel clearances? If yes, note level and confirm
  the company has cleared personnel available. Do not commit to classified work without
  cleared personnel confirmed.

**Onsite:**
- Does work require the company personnel at a government facility?
- If yes: note location, badging lead time, and whether a security escort is needed.
- Add `WF-16 (Onsite Integration Support)` to the estimate.

---

## Bid/No-Bid — GovCon Additions

In addition to the commercial triage factors in `estimating-core.md`, assess:

**Competitive position:**
- Is the company a known entity to this program office or agency?
- Has the company done prior work (Phase I → Phase II transition, prior contract)?
- Are there likely incumbents or preferred vendors? Is this wired?

**Past performance:**
- Does the solicitation require past performance references?
- Does the company have relevant, recent, rateable past performance to cite?
- SBIR: prior SBIR awards significantly improve win probability — note them.

**Set-aside:**
- What is the set-aside status? (Small Business, SDVOSB, HUBZone, etc.)
- Does the company qualify? Confirm against current SAM.gov registration.

**Teaming:**
- Does the scope require capabilities the company does not have in-house?
- Is a teaming arrangement needed? If yes, does a partner exist and is a
  teaming agreement required before submission?
- STTR: research institution partner is mandatory — confirm before bidding.

**Budget ceiling:**
- SBIR Phase I and II have published budget ceilings. Note them.
- For RFPs: is there a funding constraint stated or implied? Flag if
  the company's likely cost exceeds it.

---

## SBIR/STTR Proposal Structure

SBIR proposals follow a rigid structure. Sections and page/word limits are
defined in the solicitation. **Limits are absolute — government portals
reject or penalize over-limit submissions.** Count before you submit.

Typical Phase I structure (verify against specific solicitation):

1. **Executive Summary** — usually 1 page; overview of innovation and potential
2. **Identification and Significance of the Problem** — what problem, why it matters,
   why existing solutions fall short
3. **Technical Approach** — how the company will solve it; Phase I work plan with milestones
4. **Innovation** — what is novel; why this is not incremental improvement
5. **Phase I Technical Objectives** — specific, measurable objectives for Phase I
6. **Phase II and Commercialization Strategy** — how Phase I leads to Phase II;
   who will buy the product and why
7. **Key Personnel** — PI qualifications and relevant experience; support staff
8. **Facilities and Equipment** — relevant resources available
9. **Budget + Justification** — labor by person and role, ODCs, subcontracts;
   narrative justification for each line item

**AI behavior for SBIR drafting:**
- Draft each section separately and present for review
- Track current word/page count as you go — flag immediately if approaching limit
- Flag any claim of compliance, certification, or capability that requires evidence
  (see Overclaim Hard Stop below)
- Do not fabricate or embellish past performance, publications, or prior awards

---

## RFP Proposal Structure

RFPs define their own structure in Section L. **Follow Section L exactly.**
Non-compliant proposals are often disqualified before technical review.

Standard volumes in competitive RFPs:

| Volume | Typical Content |
|--------|----------------|
| Technical | Approach, methodology, understanding of requirements |
| Management | Team organization, PM approach, key personnel, schedule |
| Past Performance | Relevant prior contracts, references, performance ratings |
| Cost/Price | Budget breakdown, rate justification, ODC backup |

**Compliance matrix:** For every requirement in Section L, map where in the
proposal it is addressed. Reviewers use this to score. Build it as you draft,
not after.

Record compliance matrix in `proposal_output.sections.compliance_matrix`.

---

## Workflow Template Selection — GovCon Notes

The workflow library applies to GovCon work. Additionally:

**Always consider adding:**
- `WF-13 (Data Rights + Deliverables Packaging)` — government deliverables
  have naming conventions, CDRLs, and transmittal requirements
- `WF-14 (Program Management Overlay)` — multi-phase defense work almost always
  needs formal PM overhead; include it explicitly, do not bury it
- `WF-15 (Cybersecurity Documentation Support)` — if DFARS 252.204-7012 or
  CMMC applies, document support hours are real and should be scoped
- `WF-16 (Onsite Integration Support)` — if any onsite work is required

**SBIR proposals have their own proposal-writing labor.**
Estimating a competitive SBIR proposal itself takes real hours.
Include PM + ME/EE time for the proposal effort as a separate line item
in the budget justification, not hidden in technical labor.

---

## QC Before Sending — GovCon Additions

In addition to the commercial QC checklist in `estimating-core.md`, run:

- [ ] SAM.gov registration is active and not expiring before end of PoP
- [ ] NAICS code on solicitation matches the company's registered size standard
- [ ] Every Section L requirement has a response location (compliance matrix complete)
- [ ] Page and word limits verified — count the actual document, not an estimate
- [ ] No CUI or ITAR-controlled content in the submission unless the handling
      environment has been confirmed
- [ ] No clearance-level information in an unclassified submission
- [ ] All "shall", "will", "complies with", "certified", and "is compliant with"
      statements have been reviewed — see Overclaim Hard Stop below
- [ ] Past performance references are recent (within 3 years preferred),
      relevant, and the reference contact has been notified they may be called
- [ ] Budget math matches budget justification narrative line by line
- [ ] Submission method confirmed (portal, email, hand delivery) and portal
      account tested before due date

**The AI runs this checklist and flags every item it cannot confirm.**
Human reviewers clear it. Same two-approval rule as commercial.

---

## Integration Points

All integration points from `estimating-core.md` apply, plus:

| System | How |
|--------|-----|
| SAM.gov | Manual check — AI flags, user confirms registration status |
| Government submission portals (Grants.gov, DSIP, Army SBIR) | Manual submission — AI preps package, human submits |
| `estimating-govcon.md` (this file) | Loaded automatically when `govcon.applicable = true` |
| `procedures/iso/` (future) | CMMC and NIST 800-171 procedures will link here |

---

## Hard Stops — GovCon (in addition to core Hard Stops)

1. **No submission without confirmed active SAM.gov registration.**
   Expired registration = automatic disqualification. Check before starting,
   check again before submitting.

2. **No CUI in a proposal unless the handling system is authorized.**
   If the solicitation provides CUI and you are unsure of the handling
   environment — stop. Ask the user. Do not draft using that content.

3. **No ITAR-controlled technology described without export control review.**
   This applies even to unclassified proposals and even to domestic primes.

4. **No overclaiming compliance.** Do not write "the company complies with
   NIST SP 800-171" or "the company is CMMC Level 2 certified" unless the user
   has confirmed it with documentation. Write what is accurate:
   "the company has implemented controls aligned with NIST SP 800-171 Rev. 3
   and is pursuing CMMC Level 2 assessment." Flag every compliance claim
   for reviewer confirmation before it goes in the proposal.

5. **No past due submission.** Government due dates and times are absolute.
   If the due date has passed, do not submit — flag it and ask the user how
   to proceed. A late submission is not recoverable.

6. **No teaming commitments without a teaming agreement.** If a partner is
   needed and no agreement exists, flag it as a blocker. Primes will not
   accept a team that cannot produce documentation.

7. **No cost/price volume without Excel backup.** Government cost proposals
   require detailed rate and hour backup. The Excel workbook must exist and
   match the proposal narrative before submission.
