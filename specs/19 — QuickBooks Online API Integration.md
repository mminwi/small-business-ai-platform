Below is a compact but complete specification you can stretch into your 15–25 page internal design doc by expanding each section with diagrams, DDL, API contracts, and sequence flows.

------

## 1. QuickBooks Online API overview

QuickBooks Online (QBO) exposes a REST-based Accounting API using standard HTTP verbs (GET, POST, PATCH) with JSON payloads and company-specific realm IDs. Each request targets a base URL of the form `https://quickbooks.api.intuit.com/v3/company/{realmId}/{resource}` with a required `minorversion` query parameter for versioning. Authentication uses OAuth 2.0 bearer tokens, and all calls must be made over HTTPS.

## Core concepts

- **Realm ID**: The unique company identifier included in all API paths and webhook events.
- **Resources**: Accounting entities (Customer, Vendor, Invoice, Bill, Payment, Item, Account, Employee, etc.) exposed via REST endpoints.
- **Query endpoint**: A SQL-like query language via `/query?query=select * from Invoice where ...` for read operations.
- **Minor versions**: The `minorversion` parameter alters entity schemas and behavior for backward-compatible changes.

Example base patterns:

- `GET /v3/company/{realmId}/customer/{id}`
- `POST /v3/company/{realmId}/invoice?minorversion=73`
- `POST /v3/company/{realmId}/query?minorversion=73`

------

## 2. OAuth 2.0 flow

QBO uses OAuth 2.0 Authorization Code Grant with refresh tokens; your integration layer should hide this from tenant end-users and manage it centrally.

## 2.1 Actors

- **Custom platform**: Multi-tenant SaaS with an “Accounting Integration” microservice.
- **Intuit Authorization Server**: Handles user login/consent.
- **QBO Resource Server**: Hosts the Accounting API.

## 2.2 Sequence

1. **Connect QuickBooks** (tenant admin action)
   - Your UI calls `GET /integrations/quickbooks/connect-url` in your backend.
   - Backend builds Intuit authorize URL:
     `https://appcenter.intuit.com/connect/oauth2?client_id=...&redirect_uri=...&response_type=code&scope=com.intuit.quickbooks.accounting&state={tenant_state}`.​
2. **User login and consent**
   - Admin logs into Intuit, chooses the QBO company, grants permissions; Intuit redirects to your `redirect_uri` with `code` and `realmId` in the query string.
3. **Token exchange**
   - Your backend calls Intuit token endpoint (e.g., `https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer`) with `code`, `client_id`, `client_secret`, and `redirect_uri` to receive `access_token`, `refresh_token`, and expiry metadata.
4. **Token storage**
   - Persist encrypted `access_token`, `refresh_token`, `expires_at`, `realmId`, tenant ID, and scopes in a secure table with strict access controls.
5. **Refresh tokens**
   - Before expiry or on 401/`invalid_token`, call the same token endpoint with `grant_type=refresh_token` and stored `refresh_token` to obtain new tokens, and rotate stored values.

## 2.3 JSON schema: token store

```
json{
  "$id": "https://example.com/schemas/QuickBooksToken.json",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "tenantId": { "type": "string" },
    "realmId": { "type": "string" },
    "accessToken": { "type": "string" },
    "refreshToken": { "type": "string" },
    "accessTokenExpiresAt": { "type": "string", "format": "date-time" },
    "refreshTokenExpiresAt": { "type": "string", "format": "date-time" },
    "scopes": {
      "type": "array",
      "items": { "type": "string" }
    },
    "createdAt": { "type": "string", "format": "date-time" },
    "updatedAt": { "type": "string", "format": "date-time" }
  },
  "required": [
    "id",
    "tenantId",
    "realmId",
    "accessToken",
    "refreshToken",
    "accessTokenExpiresAt",
    "createdAt",
    "updatedAt"
  ]
}
```

------

## 3. Webhooks and rate limits

## 3.1 Webhooks

QBO webhooks notify your app when entities change, using batched JSON payloads that can include multiple companies and events. Payloads typically contain entity name, operation (Create, Update, Delete, Merge, Void), entity ID, and realm ID, plus HMAC-SHA256 signatures for integrity.

Key characteristics:

- Single POST may contain events for several realm IDs.
- Events are aggregated for a short window; you must fetch full entities via the API after receiving IDs.
- Signature header (e.g., `intuit-signature`) computed using your webhook key; your endpoint must verify HMAC before accepting payloads.

Example webhook payload (simplified):

```
json{
  "eventNotifications": [
    {
      "realmId": "1234567890",
      "dataChangeEvent": {
        "entities": [
          {
            "name": "Invoice",
            "id": "123",
            "operation": "Update",
            "lastUpdated": "2025-12-01T10:15:30Z"
          },
          {
            "name": "Customer",
            "id": "45",
            "operation": "Create",
            "lastUpdated": "2025-12-01T10:15:31Z"
          }
        ]
      }
    }
  ]
}
```

## 3.2 Rate limits

QBO enforces both concurrency and rolling window limits per app/company combination. Indicative limits (you should assume *ceilings*, not targets):

- ~10 concurrent requests per second.
- ~500 requests per minute per app, with additional constraints on batch calls (~40 batches per minute and stricter limits for batch endpoints).
- New limits on Batch endpoint: 120 requests/minute per realm ID, phased in sandbox and production.

Integration recommendations:

- Implement a shared rate limiter keyed by `{appId, realmId}` at your integration service boundary.
- Use exponential backoff and retry with jitter on 429 responses.
- Prefer batch or query endpoints when syncing large datasets, within batch limits.

------

## 4. Data model and entity mapping

Your platform will act as the **operational source of truth**, while QBO is the **accounting source of truth**, consistent with your invoicing/estimates design. Below is a concise mapping between key QBO entities and your custom platform.

## 4.1 Entity responsibilities

- **Customer**: End customers (people or organizations) tied to jobs, estimates, and invoices.
- **Vendor**: Suppliers used for POs, inventory purchases, and bills.
- **Invoice**: Accounts receivable documents generated from work orders / jobs.
- **Bill**: Accounts payable documents originating from vendor POs or direct entry.
- **Payment**: Customer payments applied to invoices, and bill payments (if you integrate that surface).
- **Item**: Products/services used in invoices and bills; may map from your SKUs, service codes, or parts.
- **Account**: Chart of accounts; primary source is QBO.
- **Employee**: Staff on payroll; optionally linked to your internal user/technician objects.

## 4.2 Mapping tables

## 4.2.1 Customer mapping

| Concept                  | Custom platform field     | QBO field                              |
| :----------------------- | :------------------------ | :------------------------------------- |
| Internal customer ID     | `customer.id`             | `Customer.Id`                          |
| External QBO ID          | `customer.qboId`          | `Customer.Id`                          |
| Display name             | `customer.displayName`    | `Customer.DisplayName`                 |
| Legal name               | `customer.legalName`      | `Customer.CompanyName`                 |
| Primary contact name     | `customer.primaryContact` | `Customer.GivenName` + `FamilyName`    |
| Email                    | `customer.email`          | `Customer.PrimaryEmailAddr.Address`    |
| Phone                    | `customer.phone`          | `Customer.PrimaryPhone.FreeFormNumber` |
| Billing address          | `customer.billingAddress` | `Customer.BillAddr.*`                  |
| Shipping/service address | `customer.serviceAddress` | `Customer.ShipAddr.*`                  |
| Taxable default flag     | `customer.defaultTaxable` | `Customer.Taxable`                     |
| Default AR terms         | `customer.paymentTermsId` | `Customer.SalesTermRef`                |

## 4.2.2 Vendor mapping

| Concept          | Custom platform field   | QBO field                            |
| :--------------- | :---------------------- | :----------------------------------- |
| Vendor ID        | `vendor.id`             | `Vendor.Id`                          |
| QBO vendor ID    | `vendor.qboId`          | `Vendor.Id`                          |
| Name             | `vendor.name`           | `Vendor.DisplayName`                 |
| Contact name     | `vendor.contactName`    | `Vendor.GivenName` + `FamilyName`    |
| Email            | `vendor.email`          | `Vendor.PrimaryEmailAddr.Address`    |
| Phone            | `vendor.phone`          | `Vendor.PrimaryPhone.FreeFormNumber` |
| Payables account | `vendor.apAccountId`    | `Vendor.APAccountRef`                |
| Payment terms    | `vendor.paymentTermsId` | `Vendor.TermRef`                     |

## 4.2.3 Invoice mapping

| Concept           | Custom platform field    | QBO field                                |
| :---------------- | :----------------------- | :--------------------------------------- |
| Invoice ID        | `invoice.id`             | `Invoice.Id`                             |
| QBO invoice ID    | `invoice.qboId`          | `Invoice.Id`                             |
| Customer link     | `invoice.customerId`     | `Invoice.CustomerRef.value`              |
| Invoice number    | `invoice.number`         | `Invoice.DocNumber`                      |
| Issue date        | `invoice.issueDate`      | `Invoice.TxnDate`                        |
| Due date          | `invoice.dueDate`        | `Invoice.DueDate`                        |
| Terms             | `invoice.paymentTermsId` | `Invoice.SalesTermRef`                   |
| Line items        | `invoice.lines[]`        | `Invoice.Line[]`                         |
| Line item -> Item | `line.itemId`            | `Line.SalesItemLineDetail.ItemRef.value` |
| Line description  | `line.description`       | `Line.Description`                       |
| Quantity          | `line.quantity`          | `Line.SalesItemLineDetail.Qty`           |
| Unit price        | `line.unitPrice`         | `Line.SalesItemLineDetail.UnitPrice`     |
| Tax code          | `line.taxCodeId`         | `Line.SalesItemLineDetail.TaxCodeRef`    |
| Memo              | `invoice.memo`           | `Invoice.PrivateNote`                    |
| Status            | `invoice.status` (enum)  | derived from `Balance`, `TxnStatus`      |

## 4.2.4 Bill mapping

| Concept           | Custom platform field   | QBO field                                             |
| :---------------- | :---------------------- | :---------------------------------------------------- |
| Bill ID           | `bill.id`               | `Bill.Id`                                             |
| QBO bill ID       | `bill.qboId`            | `Bill.Id`                                             |
| Vendor link       | `bill.vendorId`         | `Bill.VendorRef.value`                                |
| Bill number       | `bill.referenceNumber`  | `Bill.DocNumber`                                      |
| Bill date         | `bill.billDate`         | `Bill.TxnDate`                                        |
| Due date          | `bill.dueDate`          | `Bill.DueDate`                                        |
| Line items        | `bill.lines[]`          | `Bill.Line[]`                                         |
| Expense line acct | `line.expenseAccountId` | `Line.AccountBasedExpenseLineDetail.AccountRef.value` |
| Item line         | `line.itemId`           | `Line.ItemBasedExpenseLineDetail.ItemRef.value`       |

## 4.2.5 Payment mapping

| Concept                | Custom platform field       | QBO field                    |
| :--------------------- | :-------------------------- | :--------------------------- |
| Payment ID             | `payment.id`                | `Payment.Id`                 |
| QBO payment ID         | `payment.qboId`             | `Payment.Id`                 |
| Customer               | `payment.customerId`        | `Payment.CustomerRef.value`  |
| Txn date               | `payment.date`              | `Payment.TxnDate`            |
| Amount                 | `payment.amount`            | `Payment.TotalAmt`           |
| Linked invoices        | `payment.appliedInvoices[]` | `Payment.Line[].LinkedTxn[]` |
| Method                 | `payment.method`            | `Payment.PaymentMethodRef`   |
| Reference (check, etc) | `payment.referenceNumber`   | `Payment.RefNum`             |

## 4.2.6 Item mapping

| Concept         | Custom platform field   | QBO field                                      |
| :-------------- | :---------------------- | :--------------------------------------------- |
| Item ID         | `item.id`               | `Item.Id`                                      |
| QBO item ID     | `item.qboId`            | `Item.Id`                                      |
| Name            | `item.name`             | `Item.Name`                                    |
| Type            | `item.type`             | `Item.Type` (Service, Inventory, NonInventory) |
| SKU             | `item.sku`              | `Item.Sku`                                     |
| Income account  | `item.incomeAccountId`  | `Item.IncomeAccountRef.value`                  |
| Expense account | `item.expenseAccountId` | `Item.ExpenseAccountRef.value`                 |
| Asset account   | `item.assetAccountId`   | `Item.AssetAccountRef.value`                   |
| Sales price     | `item.salesPrice`       | `Item.UnitPrice`                               |
| Purchase cost   | `item.purchaseCost`     | `Item.PurchaseCost`                            |
| Track quantity  | `item.trackQty`         | `Item.TrackQtyOnHand`                          |

## 4.2.7 Account mapping

| Concept        | Custom platform field    | QBO field                |
| :------------- | :----------------------- | :----------------------- |
| Account ID     | `account.id`             | `Account.Id`             |
| QBO account ID | `account.qboId`          | `Account.Id`             |
| Name           | `account.name`           | `Account.Name`           |
| Type           | `account.type`           | `Account.AccountType`    |
| Subtype        | `account.subtype`        | `Account.AccountSubType` |
| Classification | `account.classification` | `Account.Classification` |

## 4.2.8 Employee mapping

| Concept         | Custom platform field | QBO field                           |
| :-------------- | :-------------------- | :---------------------------------- |
| Employee ID     | `employee.id`         | `Employee.Id`                       |
| QBO employee ID | `employee.qboId`      | `Employee.Id`                       |
| First name      | `employee.firstName`  | `Employee.GivenName`                |
| Last name       | `employee.lastName`   | `Employee.FamilyName`               |
| Email           | `employee.email`      | `Employee.PrimaryEmailAddr.Address` |
| Active flag     | `employee.active`     | `Employee.Active`                   |

------

## 5. JSON schemas for key payloads

These are “integration edge” schemas between your platform and the QBO service; they are intentionally close to QBO but normalized for your domain.

## 5.1 Customer (integration DTO)

```
json{
  "$id": "https://example.com/schemas/CustomerIntegration.json",
  "type": "object",
  "properties": {
    "id": { "type": "string" },
    "qboId": { "type": ["string", "null"] },
    "displayName": { "type": "string" },
    "legalName": { "type": ["string", "null"] },
    "email": { "type": ["string", "null"], "format": "email" },
    "phone": { "type": ["string", "null"] },
    "billingAddress": {
      "type": ["object", "null"],
      "properties": {
        "line1": { "type": "string" },
        "line2": { "type": ["string", "null"] },
        "city": { "type": "string" },
        "region": { "type": "string" },
        "postalCode": { "type": "string" },
        "country": { "type": "string" }
      }
    },
    "shippingAddress": {
      "type": ["object", "null"],
      "properties": {
        "line1": { "type": "string" },
        "line2": { "type": ["string", "null"] },
        "city": { "type": "string" },
        "region": { "type": "string" },
        "postalCode": { "type": "string" },
        "country": { "type": "string" }
      }
    },
    "defaultTaxable": { "type": "boolean", "default": true },
    "paymentTermsId": { "type": ["string", "null"] },
    "createdAt": { "type": "string", "format": "date-time" },
    "updatedAt": { "type": "string", "format": "date-time" }
  },
  "required": ["id", "displayName", "createdAt", "updatedAt"]
}
```

## 5.2 Invoice (integration DTO)

```
json{
  "$id": "https://example.com/schemas/InvoiceIntegration.json",
  "type": "object",
  "properties": {
    "id": { "type": "string" },
    "qboId": { "type": ["string", "null"] },
    "customerId": { "type": "string" },
    "number": { "type": ["string", "null"] },
    "issueDate": { "type": "string", "format": "date" },
    "dueDate": { "type": ["string", "format": "date"] },
    "currency": { "type": "string", "default": "USD" },
    "lines": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": { "type": "string" },
          "itemId": { "type": ["string", "null"] },
          "description": { "type": "string" },
          "quantity": { "type": "number" },
          "unitPrice": { "type": "number" },
          "taxCodeId": { "type": ["string", "null"] },
          "discountPercent": { "type": ["number", "null"] },
          "serviceDate": { "type": ["string", "format": "date"] }
        },
        "required": ["id", "description", "quantity", "unitPrice"]
      }
    },
    "memo": { "type": ["string", "null"] },
    "status": {
      "type": "string",
      "enum": ["draft", "open", "paid", "voided", "partially_paid"]
    },
    "totalAmount": { "type": "number" },
    "balance": { "type": "number" },
    "lastSyncedAt": { "type": ["string", "format": "date-time"] },
    "version": { "type": "integer", "minimum": 0 }
  },
  "required": [
    "id",
    "customerId",
    "issueDate",
    "lines",
    "status",
    "totalAmount",
    "balance",
    "version"
  ]
}
```

## 5.3 Item (integration DTO)

```
json{
  "$id": "https://example.com/schemas/ItemIntegration.json",
  "type": "object",
  "properties": {
    "id": { "type": "string" },
    "qboId": { "type": ["string", "null"] },
    "name": { "type": "string" },
    "sku": { "type": ["string", "null"] },
    "type": {
      "type": "string",
      "enum": ["service", "inventory", "non_inventory"]
    },
    "salesPrice": { "type": ["number", "null"] },
    "purchaseCost": { "type": ["number", "null"] },
    "incomeAccountId": { "type": ["string", "null"] },
    "expenseAccountId": { "type": ["string", "null"] },
    "assetAccountId": { "type": ["string", "null"] },
    "trackQty": { "type": "boolean", "default": false }
  },
  "required": ["id", "name", "type"]
}
```

------

## 6. Sync patterns and conflict resolution

## 6.1 Real-time webhook-driven sync

Use webhooks for near–real-time inbound updates from QBO to your platform.

Pattern:

- Webhook → enqueue events → dedupe by `{realmId, entity, id, operation, lastUpdated}` → worker pulls latest entity from QBO via GET or query → upsert into your integration tables and propagate to core domain if relevant.
- For high-volume events (Invoices, Payments, Customers), implement coarse-grained “changed-since” polling nightly as a safety net.

When to use:

- When users may change accounting data directly in QBO (back office staff).
- For entities where latency matters (Invoices, Payments, Customers).

## 6.2 Batch sync

Batch sync is better for:

- Initial full import of Customers, Items, Accounts, Vendors.
- Periodic reconciliation and drift detection between systems.

Patterns:

- **Time-based**: Nightly or hourly sync jobs querying `WHERE MetaData.LastUpdatedTime > :lastSync`.
- **Scope-based**: Only sync objects linked to your platform (e.g., those with a custom field or memo tag).

Use QBO’s query endpoint to fetch changes page by page. Example QBO query:
`select * from Invoice where MetaData.LastUpdatedTime > '2025-12-01T00:00:00Z' order by MetaData.LastUpdatedTime asc startposition 1 maxresults 1000`.​

## 6.3 Conflict resolution strategies

Define per-entity **master system** and conflict rules:

- **Customer**: Master in your platform (operational CRM), with inbound updates from QBO limited to financial-related fields (terms, tax flags).
  - If both systems change a field: prefer platform for contact data; prefer QBO for AR/credit-related fields.
- **Vendor**: Master in your platform if you build full vendor module; otherwise QBO.
- **Invoice**: Master in your platform for operational lifecycle; QBO is the authoritative ledger.
  - Once posted to QBO, disallow destructive edits in your system that would break accounting (e.g., deleting an invoice that has payments).
- **Bill**: Master in your platform if you implement PO→Bill; else QBO.
- **Payment**: If you integrate payment processing, your platform is master; otherwise QBO.
- **Item**: Typically mastered in your platform (SKU catalog) for inventory and quoting, synchronized to QBO as Items.
- **Account, Employee**: Master in QBO.

Implement optimistic concurrency:

- Store `qboSyncToken` (QBO `SyncToken`) and `qboLastUpdatedAt` per entity.
- For outbound updates, include `SyncToken` in payload; if QBO returns a conflict error (edit sequence mismatch), fetch latest, merge, and retry or surface conflict to user.

Example conflict algorithm for Invoice:

1. Compare `qboLastUpdatedAt` with last known timestamp in your platform.
2. If QBO newer and your invoice updated since last sync → mark as conflict, create a “Sync Issue” record, and require human resolution.
3. If only platform changed and QBO identical → push update with latest `SyncToken`.

------

## 7. Error handling and data validation

## 7.1 Error types

- **Transport errors**: Network failures, TLS issues, DNS; retry with exponential backoff.
- **HTTP errors**:
  - 400–499:
    - 400: Validation or malformed request; log payload, mark integration error, and return structured error to callers.
    - 401/403: Token expired or revoked; trigger refresh or reconnect flow.
    - 404: Entity not found; treat as “desynced” and clear `qboId`.
    - 429: Rate limit exceeded; backoff and retry according to headers.
  - 500–599: QBO outage; retry with backoff and circuit breaker.

## 7.2 Validation at integration boundary

- **Pre-flight validation** against your schemas (e.g., using JSON Schema validators) before sending to QBO.
- Normalize and enforce:
  - Required fields (CustomerRef on Invoice, VendorRef on Bill, AccountRefs on lines).
  - String length limits (e.g., names truncated to 100 characters).
  - Allowed enums (account types, item types).
- On validation failure:
  - Reject request to your integration API with machine-readable error codes (e.g., `QBO_VALIDATION_FAILED`).
  - Capture in an integration error table for operator dashboard.

Example error DTO:

```
json{
  "code": "QBO_VALIDATION_FAILED",
  "message": "Invoice has at least one line without an Item or Account reference",
  "details": [
    {
      "field": "lines[2].itemId",
      "issue": "required"
    }
  ]
}
```

------

## 8. Sandbox and testing strategy

QBO provides sandbox companies for each developer account, which you should use for automated tests and manual QA.

## 8.1 Environments

- **Local dev**: Use a shared sandbox realm with test data; connect via dev app keys.
- **CI**: Run headless integration tests against sandbox using seeded data and dummy tenants.
- **Staging**: Connect to dedicated sandbox companies mirroring realistic chart of accounts and item structures.

## 8.2 Test data and scenarios

Include fixtures for:

- Customers: Individual vs business, multiple addresses, tax-exempt.
- Vendors: With different terms and currencies.
- Items: Service, Inventory, NonInventory, with income/expense/asset accounts.
- Invoices/Bills: With discounts, tax, partial payments, multi-line.

Automate tests for:

- Connect/disconnect and token refresh.
- CRUD for Customers, Vendors, Items.
- Invoice/Bill create, update, void.
- Payment create and application to invoices.
- Webhook flows (simulate POST with sample payloads and signatures).

------

## 9. Data mastering: QBO vs platform

## 9.1 Recommended mastering matrix

| Entity   | Master system                                  | Notes                                                        |
| :------- | :--------------------------------------------- | :----------------------------------------------------------- |
| Customer | Custom platform                                | Use CRM as **master**; push to QBO for accounting; allow AR-related fields to sync back. |
| Vendor   | Custom platform (if vendor module) or QBO      | If you build full vendor RFQ/PO, you become master; else default to QBO. |
| Invoice  | Custom platform                                | Generated from work orders/estimates; QBO stores final posted versions. |
| Bill     | Custom platform (if PO flow) or QBO            | Similar pattern to invoices on AP side.                      |
| Payment  | Custom platform (if payment processing) or QBO | Your platform is master when capturing card/ACH payments.    |
| Item     | Custom platform                                | Master catalog for parts/services, synced as Items to QBO.   |
| Account  | QBO                                            | Only synced read-only into your platform for configuration and mapping. |
| Employee | QBO                                            | Treated as read-only or linked to internal Users.            |

Mastering rules should be implemented in a **sync policy module** with per-entity configuration, so you can change behavior per tenant (e.g., some tenants want QBO as customer master).

------

## 10. Integration architecture

## 10.1 Logical components

- **Integration API gateway**:
  - Endpoints like `/integrations/quickbooks/connect`, `/integrations/quickbooks/customers/sync`, `/integrations/quickbooks/webhook`.
  - Handles auth to your platform and routes to appropriate services.
- **QBO Integration Service**:
  - Knows Intuit OAuth, rate limits, schemas, error mapping.
  - Exposes internal interfaces like `syncCustomer`, `pushInvoice`, `fetchUpdatedPayments`.
- **Mapping layer**:
  - Pure functions converting between domain models and QBO JSON payloads using mapping tables and config (e.g., income account per SKU).
- **Sync Orchestrator**:
  - Schedules batch jobs, handles webhook event queues, and resolves conflicts.
- **Integration Store**:
  - Tables for token storage, entity mappings (`CustomerMapping`, `VendorMapping`, etc.), sync logs, and error logs.

## 10.2 Example flows

**Outbound Invoice creation**:

1. Work order closes → platform generates invoice in internal schema.
2. Platform calls `POST /integrations/quickbooks/invoices` with InvoiceIntegration DTO.
3. QBO Integration Service validates, maps to QBO invoice payload, and POSTs to QBO.
4. On success, it stores `qboId`, `SyncToken`, and `qboLastUpdatedAt`, then updates invoice status.

**Inbound Customer update** via webhook:

1. QBO webhook indicates `Customer` updated for realm X.
2. Webhook handler enqueues `{realmId, entity, id, lastUpdated}`.
3. Worker fetches full Customer from QBO via GET `/customer/{id}`.
4. Mapping layer converts to platform Customer DTO; conflict resolution logic applies; changes persisted.

------

## 11. AI natural language → QBO query/API translation

You already plan a multi-agent orchestration layer; treat QBO access as a **tool** that the orchestrator can call with structured intents.

## 11.1 Intent schema

Define an intent schema for QBO operations, e.g.:

```
json{
  "$id": "https://example.com/schemas/QboIntent.json",
  "type": "object",
  "properties": {
    "operation": {
      "type": "string",
      "enum": [
        "LIST_INVOICES",
        "GET_INVOICE",
        "LIST_CUSTOMERS",
        "GET_CUSTOMER",
        "LIST_PAYMENTS",
        "LIST_BILLS",
        "CREATE_INVOICE",
        "CREATE_BILL"
      ]
    },
    "filters": {
      "type": "object",
      "properties": {
        "customerName": { "type": ["string", "null"] },
        "status": { "type": ["string", "null"] },
        "dateFrom": { "type": ["string", "format": "date"] },
        "dateTo": { "type": ["string", "format": "date"] },
        "minAmount": { "type": ["number", "null"] },
        "maxAmount": { "type": ["number", "null"] }
      }
    },
    "pagination": {
      "type": "object",
      "properties": {
        "page": { "type": "integer", "minimum": 1 },
        "pageSize": { "type": "integer", "minimum": 1, "maximum": 1000 }
      }
    }
  },
  "required": ["operation"]
}
```

## 11.2 Prompting patterns

For **read queries**, LLM converts natural language into `QboIntent`, then your service turns that into QBO query strings.

Examples:

- User: “Show me all unpaid invoices from last month over 1000 dollars.”

  - LLM output:

    ```
    json{
      "operation": "LIST_INVOICES",
      "filters": {
        "status": "Open",
        "dateFrom": "2026-01-01",
        "dateTo": "2026-01-31",
        "minAmount": 1000
      }
    }
    ```

  - Your service builds QBO query:

    - `select * from Invoice where Balance > '1000' and TxnDate >= '2026-01-01' and TxnDate <= '2026-01-31' and Balance > '0'`.

- User: “How much did ACME Corp pay us this quarter?”

  - Intent: `LIST_PAYMENTS` with `customerName = "ACME Corp"` and date range.
  - Generate QBO query for Payments filtered by `CustomerRef` and date, then aggregate in your service.

For **write operations**, restrict AI to generating your integration DTOs, not raw QBO payloads, then run them through your strict validators and approval flows before sending to QBO.

## 11.3 Guardrails

- Maintain an allowlist of operations exposed to AI; keep destructive operations (void, delete) behind explicit human approval.
- Validate AI-generated filters to prevent overly broad queries (e.g., returning all invoices ever).
- Log all AI→QBO tool calls with intent, actual QBO request, response, and user context for audit.

------

## 12. What to expand into full pages

To turn this into a 15–25 page spec, you can:

- Add **sequence diagrams** for: connect flow, invoice push, webhook handling, batch sync.
- Document **Postgres schemas** for mapping and token tables (e.g., `qbo_tokens`, `qbo_customer_mappings`, `qbo_sync_issues`).
- Provide **concrete QBO JSON payloads** (request/response) for each entity type using examples from the OpenAPI/Postman collections.
- Include **rate-limiter pseudo-code** and retry policies, with numeric thresholds.
- Add **AI prompt templates** for QBO read/write intents and examples of tool call responses integrated into your orchestrator spec.