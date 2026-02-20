## 1. Overall architecture and module scope

This module manages the lifecycle from estimate to invoice to payment, with deep QuickBooks Online (QBO) integration for customers, items, taxes, invoices, estimates, and payments. Your system is the “source of workflow truth”, while QBO is the “source of accounting truth”.

Key responsibilities:

- Create and manage estimates, line items, labor, materials, and markups.
- Convert approved estimates to invoices.
- Track invoice status, payment status, partial payments, and write‑offs.
- Sync customers, items, taxes, estimates, invoices, and payments with QBO.
- Optionally generate draft estimates from plain‑language job descriptions using AI.

High‑level components:

- Core API / backend service (REST or GraphQL).
- Background sync workers for QBO (webhook + polling).
- Integration service for QBO OAuth2 + API calls.
- AI service for estimate generation.
- Web/mobile client for office staff and field users.

------

## 2. QuickBooks Online API architecture

## 2.1 OAuth 2.0 and scopes

QBO uses OAuth 2.0 (authorization code) with Intuit’s identity platform.

Core concepts:

- Client ID and client secret from Intuit developer portal.
- Redirect URI registered in the app settings.
- Scopes (at minimum) for accounting: `com.intuit.quickbooks.accounting`, plus `openid` and `profile` if you want user identity.
- Token endpoint: `https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer`.

Authorization request (browser):

- `GET https://appcenter.intuit.com/connect/oauth2`
- Query params: `client_id`, `redirect_uri`, `response_type=code`, `scope=com.intuit.quickbooks.accounting openid profile`, `state=<csrf>`.

Token exchange (backend):

- `POST https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer`
- `grant_type=authorization_code`, `code`, `redirect_uri`, `client_id`, `client_secret`.

You will persist:

- `access_token`, `refresh_token`, `expires_at` per QuickBooks company (realmId).
- Multi‑tenant mapping: `tenant_id` ↔ `realm_id`, plus a connection status.

## 2.2 Core QBO endpoints you will use

Most accounting entities are under the QBO Accounting API.

Base URL pattern:

- Sandbox: `https://sandbox-quickbooks.api.intuit.com/v3/company/{realmId}/{resource}`
- Production: `https://quickbooks.api.intuit.com/v3/company/{realmId}/{resource}`

Key resources (all use JSON with `Content-Type: application/json`):

- Customers: `/customer` (CRUD) for your customer master.
- Items: `/item` (services, materials, non‑inventory, inventory, discounts).
- Estimates: `/estimate` for quotes.
- Invoices: `/invoice` for sales to be paid later.
- Payments: `/payment` plus `/payment/{payment_id}/apply` to link to invoices.

Typical methods:

- Create: `POST /v3/company/{realmId}/{entity}?minorversion=XX`
- Read: `GET /v3/company/{realmId}/{entity}/{id}`
- Query: `POST /v3/company/{realmId}/query` with SQL‑like `SELECT ... FROM`.
- Update: `POST` with `sparse=true` and latest `SyncToken`.
- Delete (hard delete on trans): `POST` or `DELETE` depending on entity, plus `operation=delete`.

Authentication:

- `Authorization: Bearer {access_token}`
- `Accept: application/json`

------

## 3. Core domain data model (your system)

## 3.1 Customer and address

Your Customer should be compatible with QBO’s Customer object.

```
json{
  "type": "object",
  "title": "Customer",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "quickbooks_customer_id": { "type": ["string", "null"] },
    "display_name": { "type": "string" },
    "company_name": { "type": ["string", "null"] },
    "first_name": { "type": ["string", "null"] },
    "last_name": { "type": ["string", "null"] },
    "email": { "type": ["string", "null"], "format": "email" },
    "phone": { "type": ["string", "null"] },
    "billing_address": { "$ref": "#/definitions/Address" },
    "shipping_address": { "$ref": "#/definitions/Address" },
    "tax_exempt": { "type": "boolean", "default": false },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  },
  "required": ["id", "display_name", "billing_address"],
  "definitions": {
    "Address": {
      "type": "object",
      "properties": {
        "line1": { "type": "string" },
        "line2": { "type": ["string", "null"] },
        "city": { "type": "string" },
        "region": { "type": "string" },
        "postal_code": { "type": "string" },
        "country": { "type": "string" }
      },
      "required": ["line1", "city", "region", "postal_code", "country"]
    }
  }
}
```

## 3.2 Items: labor and materials

QBO uses a generic Item type to represent services, goods, discounts, and charges. You can keep a normalized internal model but also map to QBO Item.

```
json{
  "type": "object",
  "title": "Item",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "quickbooks_item_id": { "type": ["string", "null"] },
    "name": { "type": "string" },
    "description": { "type": ["string", "null"] },
    "type": { "type": "string", "enum": ["labor", "material", "discount", "fee", "other"] },
    "unit_of_measure": { "type": ["string", "null"] },
    "default_rate": { "type": "number" },
    "cost": { "type": ["number", "null"] },
    "is_taxable": { "type": "boolean", "default": true },
    "active": { "type": "boolean", "default": true },
    "quickbooks_income_account_ref": { "type": ["string", "null"] },
    "quickbooks_expense_account_ref": { "type": ["string", "null"] },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  },
  "required": ["id", "name", "type", "default_rate", "is_taxable"]
}
```

Labor rates can either be:

- Parameterized on the Item (e.g., “Standard Labor Hourly”).
- Or stored as a separate table `LaborRateProfile` for per‑technician or per‑customer overrides.

------

## 4. Estimate data structures and lifecycle

## 4.1 Estimate schema

QBO Estimates represent proposed sales before acceptance. Your internal Estimate should be richer (status, approvals, AI metadata).

```
json{
  "type": "object",
  "title": "Estimate",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "quickbooks_estimate_id": { "type": ["string", "null"] },
    "customer_id": { "type": "string" },
    "service_location_id": { "type": ["string", "null"] },
    "status": {
      "type": "string",
      "enum": ["draft", "sent", "viewed", "approved", "rejected", "converted", "expired"]
    },
    "title": { "type": ["string", "null"] },
    "description": { "type": ["string", "null"] },
    "valid_until": { "type": ["string", "format": "date", "nullable": true] },
    "currency": { "type": "string", "default": "USD" },
    "subtotal": { "type": "number" },
    "discount_total": { "type": "number", "default": 0 },
    "tax_total": { "type": "number", "default": 0 },
    "total": { "type": "number" },
    "tax_code_id": { "type": ["string", "null"] },
    "line_items": {
      "type": "array",
      "items": { "$ref": "#/definitions/EstimateLineItem" }
    },
    "terms": { "type": ["string", "null"] },
    "internal_notes": { "type": ["string", "null"] },
    "customer_notes": { "type": ["string", "null"] },
    "created_by_user_id": { "type": "string" },
    "approved_at": { "type": ["string", "format": "date-time", "nullable": true] },
    "approved_by": { "type": ["string", "nullable": true] },
    "ai_origin": {
      "type": ["object", "null"],
      "properties": {
        "prompt": { "type": "string" },
        "model": { "type": "string" },
        "confidence": { "type": "number" }
      }
    },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  },
  "required": ["id", "customer_id", "status", "currency", "subtotal", "total", "line_items"],
  "definitions": {
    "EstimateLineItem": {
      "type": "object",
      "properties": {
        "id": { "type": "string", "format": "uuid" },
        "position": { "type": "integer" },
        "item_id": { "type": ["string", "null"] },
        "quickbooks_item_id": { "type": ["string", "null"] },
        "type": { "type": "string", "enum": ["labor", "material", "discount", "fee", "text"] },
        "name": { "type": "string" },
        "description": { "type": ["string", "null"] },
        "quantity": { "type": "number" },
        "unit_price": { "type": "number" },
        "markup_percent": { "type": "number", "default": 0 },
        "markup_amount": { "type": "number", "default": 0 },
        "line_subtotal": { "type": "number" },
        "taxable": { "type": "boolean", "default": true },
        "group_id": { "type": ["string", "null"] }
      },
      "required": [
        "id",
        "position",
        "type",
        "name",
        "quantity",
        "unit_price",
        "line_subtotal",
        "taxable"
      ]
    }
  }
}
```

Markup handling:

- Materials often carry a markup (e.g., 20%). You can store both `markup_percent` and the monetary `markup_amount` (derived).
- For QBO, you can either:
  - Include markup in the line’s `Rate` (baked‑in).
  - Or represent markup as separate fee/discount Items.

## 4.2 Estimate workflow states

Primary transitions:

1. `draft` → `sent`
   - Trigger: user clicks “Send to customer”.
   - Actions: email link to customer, optionally create QBO Estimate in `Pending` or equivalent state.
2. `sent` → `viewed`
   - Trigger: customer opens the link; tracked via signed URL.
3. `sent/viewed` → `approved`
   - Trigger: customer accepts via e‑signature / “Approve” button.
   - Actions: lock price, capture timestamp, create or update QBO Estimate as “accepted” (implementation uses standard Estimate with status; acceptance is more a business convention than a field).
4. `approved` → `converted`
   - Trigger: internal user clicks “Convert to Invoice”.
   - Actions: create QBO Invoice referencing the Estimate lines; set `quickbooks_invoice_id` on the Invoice.
5. Any open state → `rejected` or `expired`
   - Trigger: customer explicitly rejects, or `valid_until` passes.

------

## 5. Invoice and payment data structures

## 5.1 Invoice schema

QBO Invoices represent amounts owed, with similar fields to Estimates.

```
json{
  "type": "object",
  "title": "Invoice",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "quickbooks_invoice_id": { "type": ["string", "null"] },
    "estimate_id": { "type": ["string", "null"] },
    "customer_id": { "type": "string" },
    "status": {
      "type": "string",
      "enum": ["draft", "open", "partial", "paid", "void", "written_off"]
    },
    "invoice_number": { "type": ["string", "null"] },
    "issue_date": { "type": "string", "format": "date" },
    "due_date": { "type": ["string", "format": "date", "nullable": true] },
    "currency": { "type": "string", "default": "USD" },
    "subtotal": { "type": "number" },
    "discount_total": { "type": "number", "default": 0 },
    "tax_total": { "type": "number", "default": 0 },
    "total": { "type": "number" },
    "amount_paid": { "type": "number", "default": 0 },
    "balance_due": { "type": "number" },
    "tax_code_id": { "type": ["string", "null"] },
    "line_items": {
      "type": "array",
      "items": { "$ref": "#/definitions/InvoiceLineItem" }
    },
    "terms": { "type": ["string", "null"] },
    "customer_notes": { "type": ["string", "null"] },
    "internal_notes": { "type": ["string", "null"] },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  },
  "required": [
    "id",
    "customer_id",
    "status",
    "issue_date",
    "currency",
    "subtotal",
    "total",
    "balance_due",
    "line_items"
  ],
  "definitions": {
    "InvoiceLineItem": {
      "type": "object",
      "properties": {
        "id": { "type": "string", "format": "uuid" },
        "position": { "type": "integer" },
        "estimate_line_item_id": { "type": ["string", "null"] },
        "item_id": { "type": ["string", "null"] },
        "quickbooks_item_id": { "type": ["string", "null"] },
        "type": { "type": "string", "enum": ["labor", "material", "discount", "fee", "text"] },
        "name": { "type": "string" },
        "description": { "type": ["string", "null"] },
        "quantity": { "type": "number" },
        "unit_price": { "type": "number" },
        "line_subtotal": { "type": "number" },
        "taxable": { "type": "boolean", "default": true }
      },
      "required": [
        "id",
        "position",
        "type",
        "name",
        "quantity",
        "unit_price",
        "line_subtotal",
        "taxable"
      ]
    }
  }
}
```

## 5.2 Payment schema and application

QBO Payments represent money received, and can be applied to invoices.

```
json{
  "type": "object",
  "title": "Payment",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "quickbooks_payment_id": { "type": ["string", "null"] },
    "customer_id": { "type": "string" },
    "amount": { "type": "number" },
    "currency": { "type": "string", "default": "USD" },
    "payment_date": { "type": "string", "format": "date" },
    "payment_method": { "type": "string" },
    "reference_number": { "type": ["string", "null"] },
    "applied_invoices": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "invoice_id": { "type": "string" },
          "quickbooks_invoice_id": { "type": ["string", "null"] },
          "applied_amount": { "type": "number" }
        },
        "required": ["invoice_id", "applied_amount"]
      }
    },
    "unapplied_amount": { "type": "number", "default": 0 },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  },
  "required": [
    "id",
    "customer_id",
    "amount",
    "payment_date",
    "payment_method",
    "applied_invoices",
    "unapplied_amount"
  ]
}
```

You’ll use `/payment` and apply payments to specific invoice IDs or lines (depending on the QBO configuration).

------

## 6. Workflow: estimate → invoice → payment

## 6.1 High‑level steps

1. Create estimate (your system, optional QBO draft).
2. Send estimate to customer (email/SMS with link).
3. Capture approval (digital acceptance).
4. Convert to invoice (create QBO Invoice).
5. Send invoice (email via QBO or your system).
6. Receive payment (QBO Payments API, or bank feed in QBO).
7. Sync payment and update invoice status.

## 6.2 API call sequence examples

## 6.2.1 Creating an estimate and QBO Estimate

Your backend:

- `POST /api/estimates`
- Body: your Estimate schema; system calculates totals.

If auto‑push to QBO is enabled:

- Build QBO Estimate payload:

```
json{
  "CustomerRef": { "value": "123" },
  "TxnDate": "2026-02-18",
  "Line": [
    {
      "DetailType": "SalesItemLineDetail",
      "Amount": 300,
      "Description": "Labor - Install water heater",
      "SalesItemLineDetail": {
        "ItemRef": { "value": "45", "name": "Labor Hourly" },
        "Qty": 3,
        "UnitPrice": 100,
        "TaxCodeRef": { "value": "TAX" }
      }
    }
  ],
  "TxnTaxDetail": {
    "TxnTaxCodeRef": { "value": "7" }
  }
}
```

- Call `POST /v3/company/{realmId}/estimate?minorversion=XX`.
- Store returned QBO `Id` and `SyncToken` on your Estimate.

## 6.2.2 Converting approved estimate to invoice

Steps:

1. Transition Estimate to `approved`.
2. Create your Invoice object, copying lines and linking `estimate_id`.
3. Map to QBO Invoice:

```
json{
  "CustomerRef": { "value": "123" },
  "TxnDate": "2026-02-18",
  "Line": [
    {
      "DetailType": "SalesItemLineDetail",
      "Amount": 300,
      "Description": "Labor - Install water heater",
      "SalesItemLineDetail": {
        "ItemRef": { "value": "45" },
        "Qty": 3,
        "UnitPrice": 100,
        "TaxCodeRef": { "value": "TAX" }
      }
    }
  ],
  "TxnTaxDetail": {
    "TxnTaxCodeRef": { "value": "7" }
  }
}
```

- Call `POST /v3/company/{realmId}/invoice`.
- Save QBO `Invoice.Id` and `SyncToken`.

If you want to track link back to Estimate, you can store QBO Estimate Id in your Invoice or use custom fields.

## 6.2.3 Payment tracking

If you use QuickBooks Payments:

- Online payment link on QBO Invoice; when customer pays, QBO creates a Payment and applies it.
- You poll `/payment` or subscribe to webhooks (Payments events).
- For each Payment, map QBO Payment lines to your `Payment.applied_invoices`, update `amount_paid` and `balance_due` on Invoice, and set status to `partial` or `paid`.

If you record payments in your app:

- You create Payment in your system first.
- Then call `POST /payment` with `CustomerRef` and `Line` referencing QBO Invoice Ids, or use `/payment/{payment_id}/apply` depending on the pattern.

------

## 7. Bidirectional QuickBooks sync patterns

## 7.1 Direction and primary ownership

Recommended model:

- Customers: either side can create; pick a canonical owner per tenant (often QBO).
- Items: QBO‑owned (accounting, inventory, tax) with read‑only in your app, plus allowed local metadata.
- Estimates: your app primarily; push to QBO for accounting visibility.
- Invoices: your app if you’re driving workflow, or QBO if they create there; you must support both.
- Payments: QBO‑owned in most setups.

Define:

- `source_system` field and `last_updated_source` for conflict resolution.
- `quickbooks_sync_status`: `never`, `pending`, `synced`, `error`.

## 7.2 Sync mechanisms

- **Webhook‑driven**: QBO webhooks (change notifications) to your `/webhooks/qbo`.
- **Polling**: periodic `SELECT` queries on `LastUpdatedTime` to catch missed events.
- **Manual “Sync now”**: user‑triggered re‑sync of a single entity.

Patterns:

- **Upsert by external key**: map QBO IDs ↔ your IDs via a mapping table.
- **Idempotency**: use QBO `Id` plus `SyncToken` to avoid duplicate writes and handle concurrency.

## 7.3 Example sync flows

Customers (QBO → you):

1. Webhook indicates Customer changed.
2. You call `GET /customer/{Id}`.
3. Map fields into your Customer, matching by `quickbooks_customer_id`.
4. If not found, create new; track origin as `quickbooks`.

Estimates (you → QBO):

1. On Estimate status change to `sent` or `approved`, enqueue “push to QBO”.
2. Worker constructs QBO payload; if `quickbooks_estimate_id` exists, send update; otherwise create.
3. Save QBO Id and `SyncToken`.

Invoices and Payments:

- Very similar pattern, but you treat QBO as authoritative for `balance_due` (recalculate your Invoice from QBO fields when Payments arrive).

------

## 8. Data mapping challenges and tables

## 8.1 Customer field mapping

| Your field               | QBO field                                    | Notes                     |
| :----------------------- | :------------------------------------------- | :------------------------ |
| `id`                     | `<app internal>`                             | Not in QBO                |
| `quickbooks_customer_id` | `Customer.Id`                                | String QBO Id             |
| `display_name`           | `DisplayName`                                | Required in QBO Customer. |
| `company_name`           | `CompanyName`                                | Optional.                 |
| `first_name`             | `GivenName`                                  | Optional.                 |
| `last_name`              | `FamilyName`                                 | Optional.                 |
| `email`                  | `PrimaryEmailAddr.Address`                   | Email field.              |
| `phone`                  | `PrimaryPhone.FreeFormNumber`                | Phone.                    |
| `billing_address.*`      | `BillAddr.*`                                 | Address mapping.          |
| `shipping_address.*`     | `ShipAddr.*`                                 | Address mapping.          |
| `tax_exempt`             | `Taxable` / `SalesTermRef` / tax_exempt flag | Varies by setup.          |

## 8.2 Item field mapping

| Your field                      | QBO field                            | Notes                                     |
| :------------------------------ | :----------------------------------- | :---------------------------------------- |
| `id`                            | `<app internal>`                     |                                           |
| `quickbooks_item_id`            | `Item.Id`                            |                                           |
| `name`                          | `Name`                               | Required.                                 |
| `description`                   | `Description`                        |                                           |
| `type = labor`                  | `Type = Service`                     |                                           |
| `type = material`               | `Type = NonInventory` or `Inventory` | Depends on accounting.                    |
| `default_rate`                  | `UnitPrice`                          |                                           |
| `cost`                          | `PurchaseCost`                       | For inventory or expense tracking.        |
| `is_taxable`                    | `Taxable` or tax code                | Combined with `TaxCodeRef` in line items. |
| `quickbooks_income_account_ref` | `IncomeAccountRef`                   | Required in QBO for income posting.       |

## 8.3 Estimate and invoice line mapping

| Your field             | QBO field                                                | Notes                                              |
| :--------------------- | :------------------------------------------------------- | :------------------------------------------------- |
| `name`                 | `Line.SalesItemLineDetail.ItemRef.name` or `Description` | QBO generally uses Item name.                      |
| `quantity`             | `Line.SalesItemLineDetail.Qty`                           |                                                    |
| `unit_price`           | `Line.SalesItemLineDetail.UnitPrice`                     |                                                    |
| `line_subtotal`        | `Line.Amount`                                            | QBO calculates from Qty × UnitPrice; you may send. |
| `taxable`              | `Line.SalesItemLineDetail.TaxCodeRef`                    | Use tax code (e.g., `TAX` vs `NON`).               |
| `tax_code_id` (header) | `TxnTaxDetail.TxnTaxCodeRef`                             | Document‑level tax code.                           |

Known gotcha: QBO Online generally uses a single tax code per transaction, not per line, in many localizations; line‑level tax is limited and often approximated via codes.

## 8.4 Tax handling basics

- QBO Automated Sales Tax calculates tax based on customer address and product taxability.
- You should:
  - Flag taxable vs non‑taxable items (`is_taxable`).
  - Set the customer’s taxability (e.g., exempt) and their address.
  - Provide `TxnTaxDetail.TxnTaxCodeRef` when you need a specific tax code.
- Avoid computing tax yourself when using QBO as accounting source; let QBO compute and then sync back the actual tax total.

------

## 9. AI‑generated estimates from plain language

## 9.1 Input and output contracts

Request schema:

```
json{
  "type": "object",
  "title": "AIEstimateRequest",
  "properties": {
    "customer_id": { "type": "string" },
    "job_description": { "type": "string" },
    "service_location_id": { "type": ["string", "null"] },
    "preferred_date": { "type": ["string", "format": "date", "nullable": true] },
    "budget_hint": { "type": ["number", "nullable": true] },
    "constraints": { "type": ["string", "null"] }
  },
  "required": ["customer_id", "job_description"]
}
```

Response schema:

```
json{
  "type": "object",
  "title": "AIEstimateDraft",
  "properties": {
    "estimate": { "$ref": "#/definitions/Estimate" },
    "explanations": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "line_item_id": { "type": "string" },
          "rationale": { "type": "string" }
        },
        "required": ["line_item_id", "rationale"]
      }
    },
    "warnings": {
      "type": "array",
      "items": { "type": "string" }
    }
  },
  "required": ["estimate"],
  "definitions": {
    "Estimate": {
      "$ref": "#/components/schemas/Estimate"
    }
  }
}
```

Pipeline:

1. Pre‑processing:
   - Retrieve customer and location for context.
   - Retrieve relevant Items (labor and materials) from your DB/QBO.
2. Prompt LLM with:
   - Job description.
   - Item catalog subset.
   - Pricing guidelines (labor rate, typical durations, markup rules).
3. LLM outputs structured JSON:
   - Each line with `item_id` or text, `quantity`, `unit_price` suggestion, `type`, and `taxable`.
4. Your backend validates:
   - Enforces min/max ranges.
   - Rounds time (e.g., 0.5 hour increments).
   - Applies standard markup.
5. Save as Estimate in `draft` state with `ai_origin` metadata.

## 9.2 Example AI‑generated estimate snippet

Example LLM output for a water heater swap:

```
json{
  "estimate": {
    "customer_id": "c123",
    "status": "draft",
    "currency": "USD",
    "line_items": [
      {
        "id": "li1",
        "position": 1,
        "type": "labor",
        "item_id": "item-labor-standard",
        "name": "Labor - Remove old water heater and install new unit",
        "description": "Includes disconnect, removal, install, and testing.",
        "quantity": 3.5,
        "unit_price": 110,
        "markup_percent": 0,
        "markup_amount": 0,
        "line_subtotal": 385,
        "taxable": true
      },
      {
        "id": "li2",
        "position": 2,
        "type": "material",
        "item_id": "item-water-heater-50gal",
        "name": "50 gallon gas water heater",
        "description": "Standard efficiency, 6-year warranty.",
        "quantity": 1,
        "unit_price": 950,
        "markup_percent": 20,
        "markup_amount": 190,
        "line_subtotal": 1140,
        "taxable": true
      }
    ]
  }
}
```

Your system then calculates subtotal 15251525, applies tax via QBO or internal rules, and surfaces this as an editable draft.

------

## 10. API surface for your module

## 10.1 Example REST endpoints

Your service API (internal/external):

- `POST /api/integrations/quickbooks/connect` – starts OAuth flow.
- `POST /api/integrations/quickbooks/webhook` – receives QBO webhooks.
- `GET /api/customers`, `POST /api/customers`, etc.
- `GET /api/items`, `POST /api/items`.
- `POST /api/estimates`
- `GET /api/estimates/{id}`
- `POST /api/estimates/{id}/send`
- `POST /api/estimates/{id}/approve`
- `POST /api/estimates/{id}/convert-to-invoice`
- `GET /api/invoices`, `GET /api/invoices/{id}`
- `POST /api/invoices/{id}/send`
- `GET /api/invoices/{id}/payments`
- `POST /api/payments` (if recording payments).
- `POST /api/ai/estimates` – AI‑generated draft estimates.

## 10.2 Example sequence: customer approves estimate

1. Customer opens link: `GET /public/estimates/{token}` (read‑only).
2. Customer clicks “Approve”:
   - `POST /public/estimates/{token}/approve`
3. Backend:
   - Moves Estimate to `approved`.
   - Optionally converts to Invoice immediately or queues this.
   - If QBO integration enabled:
     - Ensures Customer exists in QBO.
     - Creates or updates QBO Estimate (for record) and/or QBO Invoice.

------

## 11. Error handling, idempotency, and concurrency

- Use idempotency keys for outbound QBO writes; keep a log of request/response.
- Always pass the latest `SyncToken` when updating QBO entities, and handle “stale token” by refetching entity and reconciling.
- Mark sync errors on entities, e.g., `quickbooks_sync_status = "error"` with message.
- For payments, handle partial applications (e.g., Payment applied to multiple invoices) and update all affected Invoice balances.

------

## 12. Security and compliance

- Store QBO tokens encrypted at rest; restrict access by service role.
- Rotate client secrets when needed.
- Implement RBAC in your app:
  - Owners/admins can connect QuickBooks and manage mapping.
  - Office staff can send estimates/invoices.
  - Technicians can view but not adjust pricing.