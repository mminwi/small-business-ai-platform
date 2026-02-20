## 1. Core Entities and Data Model

Design around a small, explicit set of entities:

- Vendor
- VendorContact
- VendorPriceList / VendorPriceItem
- PaymentTerm
- PurchaseOrder / PurchaseOrderLine
- Receipt (PO receiving)
- VendorPerformanceSnapshot
- RFQ / RFQLine / RFQBid
- Integrations (QuickBooksVendorMapping, QuickBooksBillMapping, QuickBooksPurchaseOrderMapping)

Use multi-tenant scoping via `organization_id` on all business entities.

## 1.1 Vendor

Represents a supplier of goods or services (maps to QuickBooks Vendor).

Key relationships:

- 1:N VendorContact
- 1:N VendorPriceItem
- 1:N PurchaseOrder
- 1:N RFQBid
- 1:1 QuickBooksVendorMapping (optional)

Example JSON schema:

```
json{
  "$id": "Vendor",
  "type": "object",
  "required": ["id", "organization_id", "name", "status"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "organization_id": { "type": "string", "format": "uuid" },

    "name": { "type": "string", "maxLength": 255 },
    "legal_name": { "type": "string", "maxLength": 255 },
    "vendor_code": { "type": "string", "maxLength": 64 },
    "status": {
      "type": "string",
      "enum": ["active", "on_hold", "blacklisted", "inactive"]
    },

    "default_payment_term_id": { "type": "string", "format": "uuid" },
    "default_currency": { "type": "string", "minLength": 3, "maxLength": 3 },
    "tax_id": { "type": "string", "maxLength": 64 },
    "is_1099": { "type": "boolean" },

    "billing_address": {
      "$ref": "#/$defs/address"
    },
    "shipping_address": {
      "$ref": "#/$defs/address"
    },

    "phone": { "type": "string", "maxLength": 50 },
    "email": { "type": "string", "format": "email" },
    "website": { "type": "string", "format": "uri" },

    "lead_time_days_default": { "type": "integer", "minimum": 0 },
    "min_order_amount": { "type": "number" },
    "preferred": { "type": "boolean" },

    "performance_score": { "type": "number", "minimum": 0, "maximum": 100 },
    "on_time_delivery_rate": { "type": "number" },
    "defect_rate": { "type": "number" },

    "qb_vendor_id": { "type": "string" },

    "tags": {
      "type": "array",
      "items": { "type": "string", "maxLength": 64 }
    },
    "notes": { "type": "string", "maxLength": 4000 },

    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" },
    "archived_at": { "type": "string", "format": "date-time" }
  },
  "$defs": {
    "address": {
      "type": "object",
      "properties": {
        "line1": { "type": "string", "maxLength": 255 },
        "line2": { "type": "string", "maxLength": 255 },
        "city": { "type": "string", "maxLength": 100 },
        "state": { "type": "string", "maxLength": 100 },
        "postal_code": { "type": "string", "maxLength": 20 },
        "country": { "type": "string", "maxLength": 2 }
      }
    }
  }
}
```

## 1.2 VendorContact

```
json{
  "$id": "VendorContact",
  "type": "object",
  "required": ["id", "organization_id", "vendor_id", "first_name", "last_name"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "organization_id": { "type": "string", "format": "uuid" },
    "vendor_id": { "type": "string", "format": "uuid" },

    "first_name": { "type": "string", "maxLength": 100 },
    "last_name": { "type": "string", "maxLength": 100 },
    "role": { "type": "string", "maxLength": 100 },
    "email": { "type": "string", "format": "email" },
    "phone": { "type": "string", "maxLength": 50 },
    "is_primary": { "type": "boolean" },

    "notes": { "type": "string", "maxLength": 2000 },

    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
```

## 1.3 PaymentTerm

Matches common AP terms and maps cleanly to QuickBooks payment terms concepts.

```
json{
  "$id": "PaymentTerm",
  "type": "object",
  "required": ["id", "organization_id", "name", "type"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "organization_id": { "type": "string", "format": "uuid" },

    "name": { "type": "string", "maxLength": 100 },
    "description": { "type": "string", "maxLength": 500 },
    "type": {
      "type": "string",
      "enum": ["net", "eom", "cod", "prepaid", "milestone"]
    },
    "net_days": { "type": "integer", "minimum": 0 },
    "discount_percent": { "type": "number" },
    "discount_days": { "type": "integer", "minimum": 0 },

    "qb_term_id": { "type": "string" },

    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
```

## 1.4 VendorPriceList / VendorPriceItem

Price list is logical grouping; items are the rows, typically per part/SKU.

```
json{
  "$id": "VendorPriceList",
  "type": "object",
  "required": ["id", "organization_id", "vendor_id", "name"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "organization_id": { "type": "string", "format": "uuid" },
    "vendor_id": { "type": "string", "format": "uuid" },

    "name": { "type": "string", "maxLength": 255 },
    "currency": { "type": "string", "minLength": 3, "maxLength": 3 },
    "effective_from": { "type": "string", "format": "date" },
    "effective_to": { "type": "string", "format": "date" },
    "is_default": { "type": "boolean" },

    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
json{
  "$id": "VendorPriceItem",
  "type": "object",
  "required": ["id", "organization_id", "vendor_id", "part_id", "unit_price"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "organization_id": { "type": "string", "format": "uuid" },

    "vendor_id": { "type": "string", "format": "uuid" },
    "price_list_id": { "type": "string", "format": "uuid" },
    "part_id": { "type": "string", "format": "uuid" },
    "vendor_part_number": { "type": "string", "maxLength": 100 },

    "uom": { "type": "string", "maxLength": 32 },
    "min_order_qty": { "type": "number" },
    "lead_time_days": { "type": "integer", "minimum": 0 },

    "unit_price": { "type": "number" },
    "currency": { "type": "string", "minLength": 3, "maxLength": 3 },
    "price_breaks": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["min_qty", "unit_price"],
        "properties": {
          "min_qty": { "type": "number" },
          "unit_price": { "type": "number" }
        }
      }
    },

    "effective_from": { "type": "string", "format": "date" },
    "effective_to": { "type": "string", "format": "date" },

    "last_quoted_at": { "type": "string", "format": "date-time" },
    "last_po_price": { "type": "number" },

    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
```

## 1.5 PurchaseOrder and PurchaseOrderLine

Align with QuickBooks PO concepts: header with vendor, ship-to, terms; lines with item, qty, rate.

```
json{
  "$id": "PurchaseOrder",
  "type": "object",
  "required": ["id", "organization_id", "vendor_id", "status"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "organization_id": { "type": "string", "format": "uuid" },

    "po_number": { "type": "string", "maxLength": 50 },
    "external_reference": { "type": "string", "maxLength": 100 },

    "vendor_id": { "type": "string", "format": "uuid" },
    "vendor_contact_id": { "type": "string", "format": "uuid" },
    "payment_term_id": { "type": "string", "format": "uuid" },

    "status": {
      "type": "string",
      "enum": [
        "draft",
        "pending_approval",
        "approved",
        "sent_to_vendor",
        "partially_received",
        "fully_received",
        "cancelled",
        "closed"
      ]
    },

    "order_date": { "type": "string", "format": "date" },
    "expected_ship_date": { "type": "string", "format": "date" },
    "expected_delivery_date": { "type": "string", "format": "date" },

    "currency": { "type": "string", "minLength": 3, "maxLength": 3 },
    "subtotal": { "type": "number" },
    "tax_total": { "type": "number" },
    "shipping_total": { "type": "number" },
    "other_total": { "type": "number" },
    "grand_total": { "type": "number" },

    "billing_address": { "$ref": "Vendor#/$defs/address" },
    "shipping_address": { "$ref": "Vendor#/$defs/address" },

    "ship_to_location_id": { "type": "string", "format": "uuid" },

    "buyer_user_id": { "type": "string", "format": "uuid" },
    "approver_user_id": { "type": "string", "format": "uuid" },

    "qb_po_id": { "type": "string" },

    "notes_internal": { "type": "string", "maxLength": 4000 },
    "notes_vendor": { "type": "string", "maxLength": 4000 },

    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" },
    "approved_at": { "type": "string", "format": "date-time" },
    "sent_at": { "type": "string", "format": "date-time" },
    "closed_at": { "type": "string", "format": "date-time" }
  }
}
json{
  "$id": "PurchaseOrderLine",
  "type": "object",
  "required": [
    "id",
    "organization_id",
    "purchase_order_id",
    "line_number",
    "quantity_ordered",
    "unit_price"
  ],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "organization_id": { "type": "string", "format": "uuid" },
    "purchase_order_id": { "type": "string", "format": "uuid" },

    "line_number": { "type": "integer", "minimum": 1 },

    "part_id": { "type": "string", "format": "uuid" },
    "description": { "type": "string", "maxLength": 1000 },
    "uom": { "type": "string", "maxLength": 32 },

    "quantity_ordered": { "type": "number" },
    "quantity_received": { "type": "number" },
    "quantity_cancelled": { "type": "number" },

    "unit_price": { "type": "number" },
    "discount_percent": { "type": "number" },
    "tax_rate": { "type": "number" },
    "line_total": { "type": "number" },

    "expected_delivery_date": { "type": "string", "format": "date" },

    "vendor_part_number": { "type": "string", "maxLength": 100 },

    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
```

## 1.6 Receipt (PO Receiving)

Each receipt event can cover multiple PO lines; track over/short and quality.

```
json{
  "$id": "Receipt",
  "type": "object",
  "required": ["id", "organization_id", "purchase_order_id", "received_at"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "organization_id": { "type": "string", "format": "uuid" },

    "purchase_order_id": { "type": "string", "format": "uuid" },
    "receiver_user_id": { "type": "string", "format": "uuid" },

    "received_at": { "type": "string", "format": "date-time" },
    "reference_number": { "type": "string", "maxLength": 100 },
    "packing_slip_number": { "type": "string", "maxLength": 100 },
    "carrier": { "type": "string", "maxLength": 100 },
    "tracking_number": { "type": "string", "maxLength": 100 },

    "status": {
      "type": "string",
      "enum": ["open", "completed", "cancelled"]
    },

    "notes": { "type": "string", "maxLength": 4000 },

    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
json{
  "$id": "ReceiptLine",
  "type": "object",
  "required": ["id", "organization_id", "receipt_id", "po_line_id", "quantity_received"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "organization_id": { "type": "string", "format": "uuid" },

    "receipt_id": { "type": "string", "format": "uuid" },
    "po_line_id": { "type": "string", "format": "uuid" },

    "quantity_received": { "type": "number" },
    "quantity_accepted": { "type": "number" },
    "quantity_rejected": { "type": "number" },

    "quality_status": {
      "type": "string",
      "enum": ["accepted", "accepted_with_issues", "rejected"]
    },
    "defect_code": { "type": "string", "maxLength": 100 },
    "notes": { "type": "string", "maxLength": 2000 },

    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
```

## 1.7 VendorPerformanceSnapshot

Pre-computed metrics for each vendor per period (e.g., monthly).

```
json{
  "$id": "VendorPerformanceSnapshot",
  "type": "object",
  "required": ["id", "organization_id", "vendor_id", "period_start", "period_end"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "organization_id": { "type": "string", "format": "uuid" },

    "vendor_id": { "type": "string", "format": "uuid" },
    "period_start": { "type": "string", "format": "date" },
    "period_end": { "type": "string", "format": "date" },

    "total_pos": { "type": "integer", "minimum": 0 },
    "total_lines": { "type": "integer", "minimum": 0 },
    "total_units_ordered": { "type": "number" },
    "total_units_received": { "type": "number" },

    "on_time_deliveries": { "type": "integer" },
    "late_deliveries": { "type": "integer" },
    "early_deliveries": { "type": "integer" },

    "on_time_delivery_rate": { "type": "number" },
    "avg_days_late": { "type": "number" },
    "lead_time_variance_days": { "type": "number" },

    "defective_units": { "type": "number" },
    "defect_rate": { "type": "number" },

    "composite_score": { "type": "number", "minimum": 0, "maximum": 100 },
    "risk_flag": {
      "type": "string",
      "enum": ["none", "watch", "high"]
    },

    "ai_anomaly_score": { "type": "number" },
    "ai_notes": { "type": "string", "maxLength": 4000 },

    "created_at": { "type": "string", "format": "date-time" }
  }
}
```

## 1.8 RFQ, RFQLine, RFQBid

Supports competitive bids from multiple vendors.

```
json{
  "$id": "RFQ",
  "type": "object",
  "required": ["id", "organization_id", "title", "status"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "organization_id": { "type": "string", "format": "uuid" },

    "title": { "type": "string", "maxLength": 255 },
    "rfq_number": { "type": "string", "maxLength": 50 },
    "status": {
      "type": "string",
      "enum": ["draft", "sent", "partially_quoted", "fully_quoted", "awarded", "cancelled"]
    },

    "issue_date": { "type": "string", "format": "date" },
    "due_date": { "type": "string", "format": "date" },

    "buyer_user_id": { "type": "string", "format": "uuid" },

    "notes_internal": { "type": "string", "maxLength": 4000 },
    "notes_vendor": { "type": "string", "maxLength": 4000 },

    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
json{
  "$id": "RFQLine",
  "type": "object",
  "required": ["id", "organization_id", "rfq_id", "line_number", "quantity"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "organization_id": { "type": "string", "format": "uuid" },

    "rfq_id": { "type": "string", "format": "uuid" },
    "line_number": { "type": "integer" },

    "part_id": { "type": "string", "format": "uuid" },
    "description": { "type": "string", "maxLength": 1000 },
    "uom": { "type": "string", "maxLength": 32 },
    "quantity": { "type": "number" },

    "target_price": { "type": "number" },

    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
json{
  "$id": "RFQBid",
  "type": "object",
  "required": ["id", "organization_id", "rfq_id", "vendor_id", "status"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "organization_id": { "type": "string", "format": "uuid" },

    "rfq_id": { "type": "string", "format": "uuid" },
    "vendor_id": { "type": "string", "format": "uuid" },

    "status": {
      "type": "string",
      "enum": ["invited", "declined", "submitted", "withdrawn", "awarded", "lost"]
    },
    "submitted_at": { "type": "string", "format": "date-time" },

    "total_price": { "type": "number" },
    "currency": { "type": "string", "minLength": 3, "maxLength": 3 },
    "lead_time_days": { "type": "integer" },
    "payment_term_id": { "type": "string", "format": "uuid" },

    "lines": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["rfq_line_id", "unit_price"],
        "properties": {
          "rfq_line_id": { "type": "string", "format": "uuid" },
          "vendor_part_number": { "type": "string", "maxLength": 100 },
          "unit_price": { "type": "number" },
          "min_order_qty": { "type": "number" },
          "lead_time_days": { "type": "integer" }
        }
      }
    },

    "ai_score": { "type": "number" },
    "ai_rank": { "type": "integer" },
    "ai_notes": { "type": "string", "maxLength": 4000 },

    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
```

------

## 2. Purchase Order Workflow

## 2.1 States

PO lifecycle state machine:

- `draft`: Created but not submitted.
- `pending_approval`: Submitted for approval; immutable except by approver.
- `approved`: Approved and ready to send to vendor.
- `sent_to_vendor`: Email or portal delivery logged; awaiting receipt.
- `partially_received`: At least one line partially received.
- `fully_received`: All lines fully received.
- `cancelled`: Explicitly cancelled.
- `closed`: Fully received and no further financial action.

Transitions (simplified):

1. Draft → Pending approval
2. Pending approval → Approved (or back to Draft)
3. Approved → Sent to vendor (with audit of sent method)
4. Sent → Partially/fully received based on receipts
5. Any non-closed → Cancelled (guard: no open receipts)
6. Fully received → Closed (optionally auto on final receipt)

## 2.2 PO Creation Flow

Typical flow for a small shop:

1. User creates PO:
   - Select vendor, ship-to location, payment terms, currency.
   - Add lines by searching parts, pulling default vendor price and lead time.
2. System auto-calculates:
   - Expected delivery date from `order_date + lead_time_days`.
   - Totals (line, tax, freight).
3. User saves as `draft` or submits for approval if threshold exceeded (e.g., total > configured limit).
4. If approval needed:
   - Notify approver.
   - Approver can edit limited fields (terms, notes, remove lines) or reject back to draft.
5. Once `approved`:
   - PO number assigned (if not earlier).
   - Optionally auto-pushed to QuickBooks as a PurchaseOrder (if you mirror POs in QBO).

## 2.3 Approval Workflow

Keep approval simple for 1–20-person shops:

- Config options:
  - No approval (auto-approve).
  - Single-level approval above amount threshold.
  - Owner-only approval for specified vendors (e.g., new vendors).

Data points:

- `PurchaseOrder.approver_user_id`
- `PurchaseOrder.approved_at`
- `PurchaseOrder.status` transitions recorded in an AuditLog entity.

Rules examples:

- If `grand_total <= 500` → auto-approve for trusted vendors.
- If vendor `status = blacklisted` → block approval.
- If buyer == approver → allow if role is owner/admin, else require different approver.

## 2.4 Receipt Workflow

1. Receiver selects PO or scans barcode on packing slip.
2. System shows PO lines with ordered vs previously received quantities.
3. For each line:
   - Enter `quantity_received`.
   - Optional: `quantity_accepted`, `quantity_rejected`, quality status, defect code.
4. Saving creates `Receipt` and `ReceiptLine` records:
   - Update `PurchaseOrderLine.quantity_received`.
   - If variance (over/under), flag for buyer review.
5. PO status update:
   - If some lines still open: `partially_received`.
   - If all lines fully received: `fully_received` (then `closed` as appropriate).
6. Quality data feeds `VendorPerformanceSnapshot` metrics (defect rate, on-time delivery).

------

## 3. Vendor Performance Tracking

## 3.1 Metrics

Focus on 5–7 simple KPIs that small teams can understand.

Per vendor, compute:

- On-time delivery rate:
  - on-time deliveries/total deliverieson-time deliveries/total deliveries for the period.
- Average days late:
  - Mean of `actual_receipt_date - expected_delivery_date` for late deliveries.
- Lead time accuracy:
  - Compare quoted lead time vs actual.
- Defect rate:
  - `defective_units / units_received`.
- Order accuracy:
  - Ratio of shipments without quantity or item discrepancies.
- Composite score:
  - Weighted blend (e.g., 40% on-time, 30% quality, 30% accuracy).

## 3.2 Data Sources

- PO header:
  - Expected delivery date (from lead time).
- Receipt header:
  - Actual received date, carrier, tracking.
- Receipt lines:
  - Accepted vs rejected quantities, quality status, defect codes.

Use scheduled jobs (e.g., nightly) to roll up from PO/Receipt events into `VendorPerformanceSnapshot`.

## 3.3 Performance Rating Fields

On Vendor:

- `on_time_delivery_rate`: Latest rolling 6–12 month metric.
- `defect_rate`.
- `performance_score`: Current composite.
- `preferred` flag:
  - Either manually set or auto-set when composite stays above threshold for X periods.

On `VendorPerformanceSnapshot`:

- `composite_score`: Numeric rating per period.
- `risk_flag`:
  - `"watch"` when composite drops below threshold (e.g., 70).
  - `"high"` when below 50 or on-time < 90%.
- `ai_anomaly_score`:
  - 0–1 score indicating unusual deterioration or spikes.

------

## 4. QuickBooks AP Integration

Your system is the workflow/source-of-truth for POs and receipts; QuickBooks remains the accounting system-of-record for vendors, bills, and payments.

## 4.1 Entities to Sync

- Vendors:
  - Map to QuickBooks Vendor list via `Vendor.qb_vendor_id`.
- Purchase orders (optional):
  - If you want visibility in QBO, sync as PurchaseOrder (with `qb_po_id`).
- Bills:
  - Create QuickBooks Bills from approved vendor invoices, referencing vendor and optionally linked PO and receipts.

## 4.2 Vendor Sync

Direction: typically from QBO → your app initially, then bidirectional (your app can create vendors, QBO remains master of vendor AP accounts).

Mapping fields:

- QuickBooks Vendor:
  - `DisplayName` → `Vendor.name`
  - `CompanyName` → `Vendor.legal_name`
  - `PrimaryEmailAddr.Address` → `Vendor.email`
  - `PrimaryPhone.FreeFormNumber` → `Vendor.phone`
  - `BillAddr` / `ShipAddr` → addresses
  - `TermRef` → `Vendor.default_payment_term_id` via mapping
  - `Id` → `Vendor.qb_vendor_id`.

Workflow:

1. On QBO connect:
   - Pull vendor list; create/update local Vendor records.
2. On local vendor create/changes:
   - Optionally push to QBO:
     - POST/PUT to `/v3/company/{realmId}/vendor`.
     - Store returned `Id` as `qb_vendor_id`.

## 4.3 Purchase Orders Integration (Optional)

If mirroring POs in QBO:

- On `PurchaseOrder` approved:
  - Map to QBO PurchaseOrder with:
    - `VendorRef.value = qb_vendor_id`.
    - Line items with quantity, rate, item references or expense accounts.
  - Endpoint: `POST /v3/company/{realmId}/purchaseorder`.
  - Store `PurchaseOrder.qb_po_id`.

Benefits:

- AP tools that hook to QBO can see open POs.
- Potential for 2-way or 3-way matching in tools like Bill.com or ProcureDesk.

## 4.4 Bills / Accounts Payable

Your module should not replicate full AP payment workflow, but should:

- Capture vendor invoices against POs and receipts.
- Create Bills in QBO for payment.

Data model:

```
json{
  "$id": "VendorInvoice",
  "type": "object",
  "required": ["id", "organization_id", "vendor_id", "invoice_number"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "organization_id": { "type": "string", "format": "uuid" },

    "vendor_id": { "type": "string", "format": "uuid" },
    "purchase_order_id": { "type": "string", "format": "uuid" },

    "invoice_number": { "type": "string", "maxLength": 100 },
    "invoice_date": { "type": "string", "format": "date" },
    "due_date": { "type": "string", "format": "date" },
    "currency": { "type": "string", "minLength": 3, "maxLength": 3 },

    "subtotal": { "type": "number" },
    "tax_total": { "type": "number" },
    "shipping_total": { "type": "number" },
    "grand_total": { "type": "number" },

    "status": {
      "type": "string",
      "enum": ["draft", "ready_to_sync", "synced_to_qb", "paid", "cancelled"]
    },
    "qb_bill_id": { "type": "string" },

    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
```

Bill sync:

- Use QBO Bill entity:
  - `vendorRef` references Vendor.
  - `apAccountRef` for AP account.
  - Line items map from PO/Invoice lines.
- Endpoint: `POST /v3/company/{realmId}/bill`.

Flow:

1. User enters vendor invoice tied to PO.
2. System validates quantities (3-way match: PO, receipt, invoice).
3. On approval, create Bill in QuickBooks.
4. Store returned Bill `Id` as `qb_bill_id`.
5. Payment and AP aging remain in QBO.

------

## 5. RFQ Workflow for Competitive Bids

## 5.1 RFQ Lifecycle

States:

- `draft`:
  - Buyer defines scope and lines.
- `sent`:
  - RFQ emailed or shared to vendors; invitations recorded.
- `partially_quoted`:
  - At least one vendor has submitted partial pricing.
- `fully_quoted`:
  - All requested vendors responded or declined.
- `awarded`:
  - One or more vendors selected; create POs from winning bids.
- `cancelled`:
  - RFQ not pursued.

## 5.2 RFQ Steps

1. Buyer defines RFQ:
   - Title, description, due date, and lines (parts/quantities, target prices).
2. Buyer selects vendors to invite:
   - Link vendors to this RFQ; each gets `RFQBid` in `invited` status.
3. System sends RFQ emails:
   - Unique reply links per vendor, or PDF attachment for simple workflows.
4. Vendors respond:
   - Internally: you can expose a simple portal or manual entry by buyer.
   - Each vendor populates `RFQBid.lines` with unit prices, lead times, vendor PNs.
5. AI evaluation (optional, described later):
   - Score and rank bids across price, lead time, quality history.
6. Buyer awards:
   - Choose winning vendor per RFQ or per line.
   - Auto-generate one or more POs from winning bids.
   - Set winning `RFQBid.status = "awarded"`, others `"lost"`.

------

## 6. AI Vendor Evaluation and Flagging

You can add AI in two layers: numeric anomaly detection and natural-language summarization.

## 6.1 AI Inputs

For a given vendor and period:

- Numeric feature vector:
  - On-time delivery rate, avg days late, defect rate, # POs, spend, lead time variance, trend deltas vs prior periods.
- Categorical/metadata:
  - Vendor category, criticality, preferred flag.
- Text:
  - Freeform quality notes from Receipts and VendorInvoices.
  - Dispute/return notes.

## 6.2 AI Outputs

At vendor-period level:

- `ai_anomaly_score` (0–1).
- `ai_risk_label` (mapped to `risk_flag`).
- `ai_notes`:
  - Short bullet summary of key issues or positive trends.

At RFQBid level:

- `ai_score`:
  - Weighted ranking of bid vs others incorporating:
    - Price, lead time, payment terms, vendor historical reliability.
- `ai_rank`:
  - 1..N ordering.
- `ai_notes` summarizing tradeoffs.

## 6.3 Example Evaluation Logic

You can implement a simple rules + ML hybrid:

- Rules:
  - If on-time < 90% OR defect rate > 5% → bump risk.
  - If two consecutive periods show >10% drop in composite → mark `"watch"`.
- ML:
  - Train anomaly detection (e.g., isolation forest) on all vendors’ historical metrics.
  - Use LLM to summarize metric changes and quality notes into `ai_notes`.

Example `ai_notes` content:

- “On-time delivery dropped from 96% to 88% over last two months; defect rate increased from 0.5% to 3%, mainly cosmetic defects on housing parts.”

## 6.4 UX Patterns

- Vendor detail page:
  - Performance chart + AI summary sentence and a simple colored risk badge.
- RFQ award UI:
  - Per bid: show total cost, lead time, vendor score, AI note like “Best balance of price and reliability; slightly longer lead time than Vendor B.”

------

## 7. Full ERP Procurement vs Small Business Needs

For a 1–20-person shop, you want the essential 20% of procurement features.

## 7.1 Scope Comparison

| Area          | Full ERP procurement (SAP/Oracle style)                      | Small business module (your target)                          |
| :------------ | :----------------------------------------------------------- | :----------------------------------------------------------- |
| Vendor master | Multiple legal entities, bank accounts, tax jurisdictions, complex approvals | Simple vendor record, one or two addresses, default terms, basic compliance fields |
| Price lists   | Multi-tier contracts, rebates, promotional pricing, regional rules | Per-vendor price items, optional breaks, effective dates     |
| POs           | Multi-currency, multiple approval tiers, blanket and release orders, budget integration | Single-level POs, optional single-step approval, basic currency, per-PO limits |
| Receiving     | Three-way match, warehouse operations, ASN integration       | Simple receipts against POs, quantities and basic quality status |
| AP            | Complex payment runs, cash forecasting, discount capture optimization | Push Bills to QuickBooks, rely on QBO for payments and aging. |
| RFQ           | eSourcing portals, reverse auctions, multi-round bidding     | One-shot RFQs, email-based responses, simple bid comparison  |
| Performance   | Detailed scorecards, SLAs, supplier risk databases           | A few key KPIs (on-time, quality, price stability) with simple scores. |
| Integrations  | EDI with suppliers, enterprise AP automation, spend analytics | QBO vendor/bill sync, optional lightweight AP automation tools. |

## 7.2 Design Principles for Small Shops

- Optimize for **simplicity** over configurability.
- Keep approval logic minimal and understandable by non-specialists.
- Use QuickBooks as the financial back-end; avoid duplicating AP features.
- Make performance metrics visible but not overwhelming:
  - simple percentages, green/yellow/red indicators.
- Make AI assistive, not controlling:
  - suggestions and flags rather than auto-blocks.

------

## 8. Field Definitions Summary (Key Entities)

You can translate the JSON schemas into DB tables (e.g., Postgres) with:

- All IDs as UUIDs.
- `organization_id` for tenancy.
- `created_at`/`updated_at` with default timestamps.
- Foreign keys:
  - VendorContact.vendor_id → Vendor.id
  - VendorPriceItem.vendor_id → Vendor.id
  - PurchaseOrder.vendor_id → Vendor.id
  - PurchaseOrderLine.purchase_order_id → PurchaseOrder.id
  - Receipt.purchase_order_id → PurchaseOrder.id
  - ReceiptLine.po_line_id → PurchaseOrderLine.id
  - VendorPerformanceSnapshot.vendor_id → Vendor.id
  - RFQLine.rfq_id → RFQ.id
  - RFQBid.vendor_id → Vendor.id