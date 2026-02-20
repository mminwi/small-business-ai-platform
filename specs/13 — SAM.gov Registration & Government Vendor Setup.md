## 1. End-to-end registration workflow in SAM.gov

## 1.1 Key systems and prerequisites

- System for Award Management (SAM.gov) – authoritative entity registration and vendor record; produces Unique Entity ID (UEI).
- Unique Entity ID (UEI) – 12-character alphanumeric identifier assigned during SAM registration; replaces DUNS.
- MySBA Certifications – SBA portal for 8(a), WOSB/EDWOSB, HUBZone, and SDVOSB certifications.

Your module should model registration as a multi-stage wizard with validation rules aligned to SAM.gov.

## 1.2 High-level registration stages

1. Pre-intake and readiness
   - Capture basic business profile.
   - Determine whether user needs:
     - “UEI only” or
     - Full SAM registration (to receive contracts or assistance).
2. Identity & entity validation
   - Validate legal name, address, and formation data against supporting documents (articles of incorporation, IRS records). Incorrect formation date/state is a common cause of EVS failure.
3. UEI creation or retrieval
   - Check if UEI exists for the entity; if not, request new UEI through SAM.gov.
4. SAM “Core Data” profile
   - Enter core business information and primary NAICS.
5. Representations & Certifications (Reps & Certs)
   - Capture FAR/DFARS-related reps and certs (size status, ownership, debarment, etc.).
6. Banking (payment) information
   - Register ACH payment details for Treasury disbursements.
7. Submission & activation
   - Track registration status until “Active.”
8. Maintenance
   - Annual SAM renewal; update profile when info changes.

## 1.3 Entity registration field-level specification

You can define an `EntityRegistration` aggregate with the following sections.

## 1.3.1 Legal and tax identity

- `legalBusinessName` (string; required)
  Legal name as shown on formation documents/IRS records.​
- `doingBusinessAs` (string; optional)
- `taxIdType` (enum: EIN, SSN, ITIN; required)
- `taxId` (string; required; pattern validation)
- `entityType` (enum: corporation, LLC, sole_proprietorship, partnership, nonprofit, other; required)
- `stateOfIncorporation` (US state ISO code; required for entities)
- `countryOfIncorporation` (ISO country; default US)
- `businessStartDate` (date; must match legal documentation).
- `isUSOwned` (boolean)

## 1.3.2 Physical and mailing addresses

- `physicalAddress`:
  - `street1`, `street2`, `city`, `state`, `postalCode`, `country` (all required except `street2`).
- `mailingAddress` (same structure; allow “same as physical”).

## 1.3.3 Points of contact

- `govBusinessPoc`:
  - `nameFirst`, `nameLast`, `title`, `phone`, `email`; required.
- `electronicBusinessPoc` (optional but recommended).
- `pastPerformancePoc` (optional).

## 1.3.4 Business classification and NAICS

- `primaryNaicsCode` (string; required). NAICS classifies the industry and is required in SAM core data.
- `secondaryNaicsCodes` (array of strings).
- `businessSizeByNaics` (map: naics → enum small/other; derived from SBA size standards).
- `sbaSmallBusinessStatus` (boolean; based on primary NAICS size standard).

## 1.3.5 Ownership and control

- `ownershipStructure` (enum: closely_held, publicly_traded, individually_owned, tribally_owned, ANC_owned, etc.).
- `owners` (array):
  - `ownerId` (UUID)
  - `nameFirst`, `nameLast`
  - `ownershipPercent` (0–100)
  - `citizenship` (ISO country)
  - `isUSCitizen` (boolean)
  - `isSociallyDisadvantaged` (boolean – used for 8(a)/SDB).
  - `isEconomicallyDisadvantaged` (boolean; used for 8(a)/EDWOSB).
  - `isWoman` (boolean; for WOSB/EDWOSB).
  - `isVeteran`, `isServiceDisabledVeteran` (boolean; for VOSB/SDVOSB).
  - `isPrimaryManager` (boolean; control tests).

## 1.3.6 Banking and payment information

Bank details are required in SAM for EFT payments.

- `primaryBankAccount`:
  - `bankName` (string; required)
  - `routingNumber` (string; required; 9-digit US ABA validation)
  - `accountNumber` (string; required; masked in UI)
  - `accountType` (enum: checking, savings)
  - `accountHolderName` (string; should match legal entity or owner)
- `secondaryBankAccounts` (array; warn that additional accounts may trigger extra review).
- `remittanceEmail` (for remittance advices; optional).

## 1.3.7 SAM-specific identifiers and flags

- `uei` (string; 12-char; required once assigned).
- `cageCode` (string; optional; relevant for DoD).
- `samRegistrationStatus` (enum: draft, submitted, active, inactive, work_in_progress, rejected).
- `samActivationDate` (date).
- `samExpirationDate` (date; 1-year cycle).
- `lastSamRenewalDate` (date).
- `evsVerificationStatus` (enum: pending, passed, failed; for entity validation).

## 1.3.8 Reps & certs metadata (minimal)

Your module likely will not store all FAR clauses, but should track:

- `isDebarredOrSuspended` (boolean).
- `domesticPreferences` (e.g., Buy American, Trade Agreements) – optional flags.
- `protestHistory` (boolean; optional).
- Internal versioning of attestations (timestamped snapshot for audit).

------

## 2. Small business designation programs

Your module should model certifications as separate but linked to the core entity.

## 2.1 Programs to support (federal-level)

- 8(a) Business Development Program.
- Small Disadvantaged Business (SDB) (mostly self-representation, but trackable).
- Women-Owned Small Business (WOSB).
- Economically Disadvantaged Women-Owned Small Business (EDWOSB).
- HUBZone Small Business.
- Veteran-Owned Small Business (VOSB) – VA oriented; for completeness.
- Service-Disabled Veteran-Owned Small Business (SDVOSB).
- Other state/local/minority programs (optional extension).

## 2.2 Shared certification data model

Define `Certification` entity:

- `certificationId` (UUID)
- `entityId` (FK to `EntityRegistration`)
- `programType` (enum: SBA_8A, SBA_WOSB, SBA_EDWOSB, SBA_HUBZONE, SBA_SDVOSB, VA_VOSB, etc.)
- `issuingAgency` (enum: SBA, VA, third_party, other).
- `certificationStatus` (enum: draft, submitted, active, lapsed, revoked, denied)
- `applicationDate` (date)
- `approvalDate` (date)
- `expirationDate` (date; 8(a) max 9 years; WOSB/EDWOSB 3-year cycles with recent one-year extension for some cohorts).
- `nextAnnualAttestationDue` (date, where applicable – WOSB/EDWOSB, HUBZone).
- `supportingDocs` (list of document metadata: fileName, type, uploadedAt, stored URL or object key)
- `externalReference` (e.g., MySBA application ID).
- `reviewCycle` (enum: annual, triannual, 9-year, other)
- `programNotes` (string; free-form).

## 2.3 Program-specific eligibility and data requirements

## 2.3.1 SBA 8(a) Business Development

Key eligibility (high-level): small; 51%+ owned and controlled by socially and economically disadvantaged U.S. citizens; net worth and income below thresholds; in business for typically 2 years.

Application data fields:

- `yearsInBusiness` (int; derived).
- `sociallyDisadvantagedOwners` (refers to `owners` flags).
- `economicallyDisadvantagedOwners` (same).
- `personalNetWorthDocs` (docs metadata).
- `taxReturns` (3 years; docs).
- `businessFinancialStatements` (multi-year; docs).
- `potentialForSuccessEvidence` (contracts, invoices; docs).

## 2.3.2 WOSB / EDWOSB

Key eligibility: qualify as small; 51% owned and controlled by women U.S. citizens; EDWOSB adds economic disadvantage criteria.

Data requirements:

- `isSamActive` flag (needs active SAM with UEI/EIN).
- `womenOwnerIds` (array of owner IDs).
- `controlEvidenceDocs` (governance documents showing control).
- For EDWOSB:
  - `personalNetWorth` (per woman owner).
  - `averageAGI` (3-year adjusted gross income).
  - `personalAssetsTotal`.
- `mySbaApplicationId` and attestation schedule.

## 2.3.3 HUBZone

Eligibility: small; 51% owned by qualifying individuals or entities; principal office in a HUBZone; at least 35% of employees living in HUBZones.

Data requirements:

- `principalOfficeAddress` (must be HUBZone mapped).
- `hubzoneEmployeeCount` / `totalEmployeeCount` and residence verification (HUBZone over past 180 days).
- `hubzoneMapVerificationDoc` (screenshot/report).
- `residencyTracking` (employee address subset; you may store aggregated counts only for privacy).
- `hubzoneCertificationTerm`: track re-verification and residency checks after awards.

## 2.3.4 SDVOSB / VOSB

Eligibility: 51% owned by veteran/service-disabled veteran; control and management by that owner; verified service-connected disability; small under size standards.

Data requirements:

- `veteranOwnerIds`, `sdvOwnerIds`.
- `disabilityVerificationDocs` (VA or DoD).
- `vetCertApplicationId` (SBA certification ID).
- `vaCveLegacyId` (for migrated VA certifications).

------

## 3. Government purchase card payments (GPC)

Federal agencies use government purchase cards as the preferred method for micro-purchases.

## 3.1 Key thresholds & rules

- GPC is preferred for micro-purchases; micro-purchase threshold (MPT) increased from 10,000 to 15,000 effective October 1, 2025.
- Agencies may use GPC above MPT under certain conditions or as payment method under existing contracts.

Your module does not process payments itself but should ensure vendors can accept common card rails and flag micro-purchase suitability.

## 3.2 Data structure for GPC acceptance

Define `PaymentCapabilities`:

- `acceptsGovernmentPurchaseCard` (boolean).
- `acceptedCardBrands` (array: Visa, Mastercard, etc.).
- `processor` (enum: Stripe, Authorize.Net, Square, internal, other).
- `pciComplianceAttested` (boolean).
- `minimumOrderAmountForCard` (decimal).
- `microPurchaseFriendly` (boolean; indicates ability to handle small, rapid orders).
- `billingTerms` (string; e.g., “bill at shipment; no prepay”).

Optionally, map MPT logic in your guidance:

- `microPurchaseMax` (decimal; default 15000 for standard context; allow overrides for construction/services variants).
- `simplifiedAcquisitionThreshold` (decimal; reference 350,000 post-2025 adjustment).

Your AI guidance can use these to suggest pricing and ordering that facilitate card-based micro-purchases.

------

## 4. Data structures for status, certifications, expirations, renewals

Design a set of core tables/entities:

## 4.1 Entity-level status

`EntityRegistration` (from section 1.3) plus:

- `registrationTimeline` (array of `RegistrationEvent`):
  - `eventType` (enum: UEI_ASSIGNED, SAM_SUBMITTED, SAM_ACTIVE, SAM_REJECTED, EVS_FAILED, RENEWAL_DUE, RENEWAL_SUBMITTED).
  - `timestamp` (datetime).
  - `details` (JSON blob).

## 4.2 Certification tracking

`Certification` entity (section 2.2) plus:

- `statusHistory`:
  - `status` (enum).
  - `changedAt`.
  - `changedBy` (user/system).
  - `notes`.

## 4.3 Renewal and compliance scheduler

Create a generalized `ComplianceTask`:

- `taskId` (UUID)
- `entityId`
- `relatedCertificationId` (optional)
- `taskType` (enum:
  - SAM_ANNUAL_RENEWAL,
  - 8A_ANNUAL_REVIEW,
  - HUBZONE_RESIDENCY_RECHECK,
  - WOSB_TRIENNIAL_RENEWAL,
  - SDVOSB_RECERTIFICATION,
  - DOCUMENT_REFRESH (e.g., financials),
  - SAM_BANKING_VERIFY
    )
- `dueDate` (date)
- `createdDate` (date)
- `completedDate` (date; nullable)
- `status` (enum: pending, in_progress, completed, overdue)
- `priority` (enum: low, medium, high)
- `reminderSchedule` (e.g., cron-like or “30/7/1 days before due”)
- `assigneeUserId`

The workflow engine should generate tasks at:

- SAM registration anniversary – annual renewal.
- Certification-specific cycles: 8(a) up to 9 years with periodic reviews; WOSB/EDWOSB three-year renewal plus any temporary extensions; HUBZone continuous compliance and recertification; SDVOSB recertification cycles.

------

## 5. Researching and finding contract opportunities

## 5.1 Primary systems to model

- SAM.gov – central listing for federal contract opportunities over 25,000.
- GSA Schedule ecosystem:
  - GSA eBuy – RFQ platform for GSA Schedule (MAS) and GWAC contract holders.
  - GSA Advantage – online marketplace for approved products/services.
- Analytics systems:
  - FPDS/USAspending – for historical award data and market analysis.
- Subcontracting:
  - SBA SubNet; OSDBU portals for prime/sub opportunities.

## 5.2 Data model: opportunity intake

`Opportunity`:

- `opportunityId` (UUID; internal)
- `externalId` (e.g., SAM notice ID, eBuy RFQ number).
- `sourceSystem` (enum: SAM, GSA_EBUY, GSA_ADVANTAGE, FPDS, USASPENDING, SUBNET, OTHER).
- `title` (string)
- `issuingAgency` (string)
- `subAgency` (string; optional)
- `naicsCode` (string; may map to entity’s NAICS).
- `pscCode` (string; product/service code; optional)
- `setAsideType` (enum: SMALL_BUSINESS, 8A, HUBZONE, WOSB, EDWOSB, SDVOSB, VOSB, NONE).
- `solicitationType` (enum: RFQ, RFP, IFB, BPA_CALL, TASK_ORDER, GPC_MICROPURCHASE, OTHER).
- `estimatedValueMin`, `estimatedValueMax` (decimal; if available).
- `responseDueDate` (datetime)
- `postingDate`, `lastUpdatedDate`
- `status` (enum: open, closed, cancelled, awarded)
- `isMicroPurchase` (boolean; e.g., below MPT threshold).
- `contractVehicleRequired` (e.g., MAS, GWAC IDIQ; relevant to eBuy eligibility).
- `url` (string)
- `summary` (short text; AI-extracted).
- `keywords` (array of strings; AI-extracted).

`OpportunityMatch` links an entity to an opportunity:

- `entityId`
- `opportunityId`
- `matchScore` (0–1)
- `reason` (matched NAICS, set-aside fit, past performance similarity).
- `pursuitStatus` (enum: not_reviewed, short_listed, pursuing, not_pursuing, submitted, won, lost).
- `captureOwnerId`

The module should support rules such as:

- Filter SAM and eBuy data by entity’s NAICS codes and certifications.
- Flag opportunities that specifically require 8(a), HUBZone, WOSB, or SDVOSB set-asides when entity holds that certification.

------

## 6. Common administrative mistakes & preventive controls

Common issues during SAM and certification processes and how your module can prevent them:

1. Inconsistent legal data
   - Mistake: Business start date, state of formation, or legal name not matching documents → EVS failure or rejection.
   - Control: Cross-field validation; require upload of formation docs and IRS letters before submission, AI-assisted comparison.
2. Incorrect or missing banking information
   - Mistake: Routing/account number errors; multiple accounts without justification cause delays.
   - Control: Format and checksum validation; alert when adding secondary accounts; capture justification field.
3. Wrong or incomplete NAICS codes
   - Mistake: Selecting incorrect primary NAICS or missing relevant secondary codes, harming market visibility and size status.
   - Control: NAICS suggestion engine based on product/service descriptions; warnings if primary NAICS seems misaligned.
4. Letting SAM registration lapse
   - Mistake: Missing annual renewal, causing inability to receive new awards or payments.
   - Control: `ComplianceTask` reminders, dashboards, escalations.
5. Self-representing certifications incorrectly
   - Mistake: Claiming 8(a), HUBZone, WOSB, or SDVOSB status without actual SBA certification, especially post-2024 SDVOSB changes.
   - Control: Distinguish “claimed” vs “certified”; require external certification ID for program-specific set-asides.
6. Not maintaining HUBZone residency or principal office
   - Mistake: Allowing workforce % in HUBZone to fall below 35%; moving principal office outside HUBZone, causing ineligibility.
   - Control: Track headcount and residency ratio; alerts when risk threshold approached.
7. Missing SBA attestation/recertification dates
   - Mistake: Failing to complete periodic WOSB/EDWOSB and other program attestations, even when extensions available.
   - Control: Pre-configured renewal schedules per program, with tasks and status page.
8. Not aligning SAM profile with certification data
   - Mistake: NAICS, addresses, or ownership in MySBA and SAM inconsistent, causing review delays or denials.
   - Control: Consistency checks and “diff” views between SAM and certification profiles.

------

## 7. AI-guided registration and maintenance

AI can act as a guided assistant layered over these data structures and workflows.

## 7.1 AI roles

1. **Onboarding triage**
   - Ask a short Q&A to determine:
     - What the firm sells, its size, years in business, ownership demographics, locations.
   - Suggest which registrations and certifications are relevant:
     - E.g., veteran-owned IT services business with HUBZone office → highlight SDVOSB and HUBZone.
2. **Field-level guidance**
   - Context-aware tooltips on each field:
     - “Business start date: use the date on your state formation document, not when you began operations.”
   - Dynamic checklists with progress bars per stage (UEI, SAM, each certification).
3. **Document ingestion and validation**
   - Parse uploaded formation docs, IRS letters, tax returns, and operating agreements:
     - Extract legal name, EIN, formation date, owners, and compare to user-entered data.
   - Flag inconsistencies and suggest corrections.
4. **Eligibility prediction**
   - Use structured data to estimate likelihood of qualifying for 8(a), WOSB/EDWOSB, HUBZone, SDVOSB:
     - E.g., check ownership %, control, residency %, financial thresholds.
   - Explain gaps in plain language (“You currently employ 20 people, but only 4 live in HUBZones; you need at least 7 for HUBZone.”).
5. **Opportunity matching and capture workflow**
   - Automatically fetch and score SAM, eBuy, and subcontracting opportunities against:
     - NAICS, PSC, certifications, past performance, agency preferences.
   - Generate AI-curated shortlists and capture checklists per opportunity.
6. **Compliance monitoring**
   - Watch `Certification`, `ComplianceTask`, and `EntityRegistration` timelines:
     - Identify upcoming renewals and warn of risk (e.g., 8(a) year 4 vs 5, WOSB triannual review).
   - Suggest needed documents and steps in sequence.
7. **Proposal/RFQ assistance (beyond initial module but related)**
   - Analyze RFPs/RFQs, extract requirements, and map to internal capabilities; similar to emerging AI bidding assistants.
   - Generate outline responses, compliance matrices, and Q&A prompts.

## 7.2 Workflow checklists for implementation

## 7.2.1 SAM registration checklist (per entity)

1. Gather documents
   - Formation documents, IRS EIN letter, ownership docs, banking info, addresses.
2. Create/validate UEI
   - Query for existing entity, else create UEI.
3. Complete core data
   - Legal, tax, addresses, contacts, NAICS.
4. Enter reps & certs (basic flags).
5. Enter EFT banking information.
6. AI validation pass
   - Compare fields to documents; clean errors.
7. Submit SAM registration.
8. Monitor EVS and activation; respond to any rejection with guided fixes.

## 7.2.2 Certification workflow checklist

For each program (e.g., SDVOSB, HUBZone, WOSB, 8(a)):

1. AI eligibility pre-check:
   - Ask targeted questions and inspect `owners`, `addresses`, `employeeResidency`, `financials`.
2. Build application package:
   - Provide program-specific document list (e.g., HUBZone residency proof; EDWOSB net worth docs).
3. Populate MySBA application data from SAM profile where possible.
4. Run AI-driven consistency check between SAM and certification data.
5. Submit and track status; surface SBA/VA requests for more info.
6. Once approved, update `Certification` record and related `ComplianceTask`s.

------

## 8. Example data model (entity relationships)

You can express this as a relational or document model; core relationships:

- `EntityRegistration` 1–N `Owner`
- `EntityRegistration` 1–N `Certification`
- `EntityRegistration` 1–N `ComplianceTask`
- `EntityRegistration` 1–N `PaymentAccount`
- `EntityRegistration` 1–N `OpportunityMatch`
- `Opportunity` 1–N `OpportunityMatch`

At a high level:

```
textEntityRegistration
  ├─ Owners
  ├─ PaymentAccounts
  ├─ Certifications
  │    └─ StatusHistory
  ├─ ComplianceTasks
  └─ RegistrationTimeline

Opportunity
  └─ OpportunityMatches (links to EntityRegistration)
```

This structure supports:

- Multi-tenant SaaS where each firm has one or more entities.
- AI orchestration over clean, structured data.
- Clear renewal and compliance scheduling.