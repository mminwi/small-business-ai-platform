# Compliance Documentation Module

**Technical Specification – v1.0**

------

# 1. Regulatory Overview: Controlled Goods & Technology (U.S.)

Small manufacturers supplying defense or government customers typically fall under a combination of export control, trade compliance, and federal contracting rules.

------

## 1.1 Core U.S. Regulatory Framework

### 1.1.1 ITAR – International Traffic in Arms Regulations

**Authority:**
 U.S. Department of State
 Directorate of Defense Trade Controls (DDTC)

**Scope:**

- Governs defense articles, defense services, and technical data
- Applies to items on the USML (U.S. Munitions List)
- Covers export, re-export, temporary import, and foreign person access

**Applies When:**

- Product is specifically designed, modified, or configured for military use
- Item is listed on the USML
- Technical data is shared with foreign persons

------

### 1.1.2 EAR – Export Administration Regulations

**Authority:**
 U.S. Department of Commerce
 Bureau of Industry and Security (BIS)

**Scope:**

- Governs dual-use and commercial items
- Controlled under ECCNs (Export Control Classification Numbers)
- Items not listed are EAR99

**Applies When:**

- Product has military, aerospace, electronics, encryption, or advanced technical application
- Exported outside U.S.
- Shared with foreign persons (deemed export)

------

### 1.1.3 OFAC Sanctions

**Authority:**
 U.S. Department of the Treasury
 Office of Foreign Assets Control (OFAC)

**Scope:**

- Country-based sanctions
- Specially Designated Nationals (SDN)
- Prohibited transactions

------

### 1.1.4 Additional Relevant Rules

- CFIUS (foreign investment)
- FCPA (anti-bribery)
- DFARS (DoD contracting clauses)
- NIST 800-171 / CMMC (cyber compliance for defense contractors)
- Buy American / TAA

------

## 1.2 How Small Manufacturers Determine Which Regulations Apply

### Decision Tree Logic (System Implementable)

**Step 1: Is product defense-specific?**

- Was it designed for military?
- Is it controlled under USML category?

If yes → ITAR

**Step 2: If not ITAR, does it have dual-use technical performance?**

- Encryption?
- Aerospace?
- Controlled tolerances?
- Advanced electronics?

If yes → EAR → ECCN classification

**Step 3: If not classified**
 → EAR99

**Step 4: Is there foreign person access?**
 → Deemed export analysis required

------

### Module Requirement:

The system must allow:

- Self-guided classification questionnaire
- Storage of formal classification memo
- Version-controlled classification history
- Documentation of reasoning

------

# 2. Data Structures

All data must be versioned and auditable.

Use relational core with document storage.

------

# 2.1 Controlled Product Classification Schema

### Table: `products`

| Field                 | Type                                     | Description |
| --------------------- | ---------------------------------------- | ----------- |
| product_id            | UUID                                     | Primary key |
| sku                   | String                                   |             |
| internal_part_number  | String                                   |             |
| product_name          | String                                   |             |
| description           | Text                                     |             |
| designed_for_military | Boolean                                  |             |
| contains_encryption   | Boolean                                  |             |
| technical_specs       | JSON                                     |             |
| classification_status | Enum (Unclassified, Pending, Classified) |             |
| active_version_id     | FK                                       |             |

------

### Table: `product_classifications`

| Field                    | Type                    | Description |
| ------------------------ | ----------------------- | ----------- |
| classification_id        | UUID                    |             |
| product_id               | FK                      |             |
| regulation_type          | Enum (ITAR, EAR, EAR99) |             |
| USML_category            | String (nullable)       |             |
| ECCN                     | String (nullable)       |             |
| classification_basis     | Text                    |             |
| classified_by            | User FK                 |             |
| review_date              | Date                    |             |
| next_review_due          | Date                    |             |
| documentation_attachment | File reference          |             |
| effective_date           | Date                    |             |
| superseded_by            | FK                      |             |

------

# 2.2 Customer Authorization Records

### Table: `customers`

| Field               | Type                     |
| ------------------- | ------------------------ |
| customer_id         | UUID                     |
| legal_name          | String                   |
| country             | ISO code                 |
| address             | Text                     |
| ultimate_parent     | String                   |
| government_entity   | Boolean                  |
| foreign_person_flag | Boolean                  |
| risk_level          | Enum (Low, Medium, High) |

------

### Table: `customer_authorizations`

| Field                   | Type                           |
| ----------------------- | ------------------------------ |
| authorization_id        | UUID                           |
| customer_id             | FK                             |
| export_license_required | Boolean                        |
| license_number          | String                         |
| license_type            | String                         |
| approved_products       | JSON                           |
| expiration_date         | Date                           |
| authorization_document  | File                           |
| issued_by               | String                         |
| status                  | Enum (Valid, Expired, Revoked) |

------

# 2.3 Compliance Documentation Records

### Table: `compliance_documents`

| Field                | Type                                                         |
| -------------------- | ------------------------------------------------------------ |
| document_id          | UUID                                                         |
| related_entity_type  | Enum (Product, Customer, Transaction, Supplier)              |
| related_entity_id    | UUID                                                         |
| document_type        | Enum (Classification Memo, Screening Result, License, TCP, Training Record) |
| version              | Integer                                                      |
| created_by           | User                                                         |
| created_at           | Timestamp                                                    |
| retention_category   | Enum                                                         |
| retention_expiration | Date                                                         |
| storage_location     | URI                                                          |
| hash_checksum        | SHA256                                                       |

------

# 3. Screening Workflows

Screening must occur:

- Before onboarding customer
- Before shipment
- Before technical data release

------

## 3.1 Restricted Party Screening Data Sources

System must support screening against:

- BIS Entity List
- Denied Persons List
- OFAC SDN List
- Debarred Parties (ITAR)

------

## 3.2 Workflow

### Pre-Transaction Workflow

1. User initiates transaction.
2. System checks:
   - Customer country risk
   - Restricted party list
   - Sanctions programs
3. API call to screening service.
4. Record result snapshot.
5. If match:
   - Flag transaction
   - Require compliance officer review
   - Prevent shipment release

------

### Table: `screening_results`

| Field             | Type                      |
| ----------------- | ------------------------- |
| screening_id      | UUID                      |
| entity_id         | FK                        |
| entity_type       | Enum (Customer, Supplier) |
| screening_date    | Timestamp                 |
| screening_service | String                    |
| match_found       | Boolean                   |
| match_details     | JSON                      |
| resolved          | Boolean                   |
| reviewed_by       | User                      |
| resolution_notes  | Text                      |

------

# 4. Documentation Retention Policies

## 4.1 ITAR

- 5 years from expiration of license or transaction

## 4.2 EAR

- 5 years from export or re-export

## 4.3 OFAC

- 5 years from transaction date

------

### System Requirement:

Each record must:

- Store retention trigger date
- Auto-calculate destruction eligibility
- Prevent deletion before expiration
- Provide legal hold override

------

### Table: `retention_policies`

| Field           | Type    |
| --------------- | ------- |
| policy_id       | UUID    |
| regulation      | Enum    |
| retention_years | Integer |
| trigger_event   | Enum    |
| description     | Text    |

------

# 5. Technology Control Plan (TCP)

A TCP prevents unauthorized access to controlled technical data.

------

## 5.1 TCP Components

### Required Sections:

1. Scope of controlled technologies
2. Physical security measures
3. IT security measures
4. Access controls
5. Visitor procedures
6. Foreign person management
7. Training requirements
8. Incident response plan

------

### Table: `technology_control_plans`

| Field                      | Type    |
| -------------------------- | ------- |
| tcp_id                     | UUID    |
| scope_description          | Text    |
| controlled_products        | JSON    |
| facility_security_measures | Text    |
| digital_security_measures  | Text    |
| access_control_roles       | JSON    |
| responsible_officer        | User    |
| annual_review_date         | Date    |
| training_required          | Boolean |
| version                    | Integer |

------

### Table: `tcp_access_registry`

| Field                   | Type    |
| ----------------------- | ------- |
| access_id               | UUID    |
| employee_id             | FK      |
| product_id              | FK      |
| access_granted          | Boolean |
| nationality             | String  |
| export_review_completed | Boolean |
| approval_date           | Date    |

------

# 6. AI-Assisted Compliance Support

AI should assist but never make legal determinations.

------

## 6.1 Product Classification Assistance

AI Inputs:

- Technical description
- Material composition
- Performance specs
- End use

AI Outputs:

- Likely regulation category
- Candidate USML categories
- Candidate ECCNs
- Clarifying questions

Must store:

- Prompt
- Model version
- Response
- Human override decision

------

## 6.2 Automated Document Drafting

AI can:

- Generate classification memos
- Draft TCP
- Produce screening logs
- Generate export justification letters

------

### Table: `ai_interactions`

| Field           | Type    |
| --------------- | ------- |
| ai_id           | UUID    |
| related_product | FK      |
| prompt          | Text    |
| model_version   | String  |
| response        | Text    |
| accepted        | Boolean |
| human_reviewer  | User    |
| review_notes    | Text    |

------

# 7. Common Administrative Mistakes

### 1. Assuming EAR99 without analysis

### 2. Failing to screen domestic customers

### 3. Not screening suppliers

### 4. Not documenting classification basis

### 5. Allowing foreign interns access to CAD files

### 6. No written TCP

### 7. Deleting export emails before 5 years

### 8. Failing to log deemed exports

### 9. Assuming small size means exemption

### 10. Relying on customer classification without verification

------

# 8. System Architecture Considerations

- Role-based access control (RBAC)
- Immutable audit logs
- Versioned documents
- Secure file storage
- Encryption at rest
- Two-factor authentication
- Export-controlled data tagging
- GeoIP access monitoring

------

# 9. Audit & Reporting

System must generate:

- Export activity report
- License utilization report
- Screening log report
- Product classification summary
- TCP compliance report
- Retention expiration dashboard

------

# 10. Security Model

### Data Sensitivity Levels:

- Public
- Internal
- Controlled
- ITAR-restricted

------

# 11. API Requirements

### Required Endpoints:

```
POST /screen/customer
GET /product/{id}/classification
POST /ai/classify
POST /tcp/access
GET /compliance/report
```

------

# 12. Deployment Considerations for Small Manufacturers

- SaaS preferred
- Minimal configuration
- Built-in regulatory guidance
- Automated list updates
- Cloud FedRAMP-compatible optional tier
- Scalable from 1 user to 50 users

------

# 13. Governance Model

Roles:

- Compliance Officer
- Administrator
- Engineer
- Sales
- Operations
- Auditor (read-only)

------

# 14. Implementation Phasing

Phase 1:

- Product classification tracking
- Screening integration
- Document retention

Phase 2:

- TCP management
- AI classification support
- Reporting dashboards

Phase 3:

- Advanced analytics
- Risk scoring engine
- Supplier compliance tracking

------

# 15. Design Philosophy for Small Shops

This system must:

- Avoid legal jargon overload
- Provide guided decision flows
- Be audit-ready
- Maintain defensible documentation
- Reduce reliance on external consultants

------

# Final Notes

Small manufacturers often operate informally. This module formalizes:

- What they make
- Who they sell to
- Why it is compliant
- How long they must keep proof

The system does not determine legality. It ensures documentation exists to defend decisions.