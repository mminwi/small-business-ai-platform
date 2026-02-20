## 1. Core data model: entities and relationships

## 1.1 Main entities

- Part
- SKU (sellable item; may map 1:1 to part or bundle)
- Location (warehouse, truck, bin, technician van)
- StockLedger / InventoryBalance
- Supplier
- PurchaseOrder / PurchaseOrderLine
- InventoryTransaction (receipts, issues, returns, adjustments, transfers)
- CustomerJob / WorkOrder (for issues, if you track job costing)
- BarcodeIdentity

## 1.1.1 Logical relationships (high level)

- Part 1–N SKU (or 1–1 if you keep them equivalent).
- Part N–N Supplier via SupplierPart (supplier catalog entries).
- Location 1–N InventoryBalance (one row per part per location).
- Part 1–N InventoryTransaction; Location 1–N InventoryTransaction.
- PurchaseOrder 1–N PurchaseOrderLine; each line references Part or SKU.
- BarcodeIdentity maps a scanned code → Part, SKU, or Location.

You can model this as a classic star:

- Fact tables: InventoryTransaction, PurchaseOrderLine.
- Dimension tables: Part, Supplier, Location, CustomerJob, CalendarDate, etc.

------

## 2. JSON schemas and field definitions

Below are baseline JSON schemas (simplified; you can convert to OpenAPI/SQL).

## 2.1 Part

```
json{
  "$id": "Part",
  "type": "object",
  "required": ["id", "partNumber", "description", "uom", "status"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "partNumber": { "type": "string" },
    "description": { "type": "string" },
    "uom": { "type": "string" },
    "category": { "type": "string" },
    "type": { "type": "string", "enum": ["raw", "component", "finished", "consumable"] },
    "status": { "type": "string", "enum": ["active", "inactive"] },
    "defaultLocationId": { "type": "string", "format": "uuid" },
    "defaultSupplierId": { "type": "string", "format": "uuid" },
    "reorderPolicy": {
      "type": "object",
      "properties": {
        "strategy": {
          "type": "string",
          "enum": ["manual", "minMax", "fixedOrderQuantity", "aiSuggested"]
        },
        "minQty": { "type": "number" },
        "maxQty": { "type": "number" },
        "safetyStock": { "type": "number" },
        "targetServiceLevel": { "type": "number" }, 
        "leadTimeDays": { "type": "number" }
      }
    },
    "accounting": {
      "type": "object",
      "properties": {
        "incomeAccountRef": { "type": "string" },
        "expenseAccountRef": { "type": "string" },
        "assetAccountRef": { "type": "string" }
      }
    },
    "barcodes": {
      "type": "array",
      "items": { "type": "string" }
    },
    "metadata": { "type": "object", "additionalProperties": true }
  }
}
```

Key notes:

- Store reorder policy per part so you can support both simple min/max and AI-suggested safety stock levels.
- Accounting fields map cleanly into QuickBooks Item asset/income/expense accounts.

## 2.2 SKU

If your clients sell finished goods that are assemblies of parts, separate SKU from Part; otherwise Part can be your sellable SKU.

```
json{
  "$id": "Sku",
  "type": "object",
  "required": ["id", "skuCode", "description"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "skuCode": { "type": "string" },
    "description": { "type": "string" },
    "partId": { "type": "string", "format": "uuid" },
    "bom": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["partId", "quantityPer"],
        "properties": {
          "partId": { "type": "string", "format": "uuid" },
          "quantityPer": { "type": "number" },
          "scrapFactor": { "type": "number" }
        }
      }
    }
  }
}
```

For many small service shops, BOM can be optional; they might only stock consumables.

## 2.3 Location

```
json{
  "$id": "Location",
  "type": "object",
  "required": ["id", "name", "type"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "name": { "type": "string" },
    "code": { "type": "string" },
    "type": {
      "type": "string",
      "enum": ["warehouse", "truck", "site", "technicianVan", "bin", "room"]
    },
    "parentLocationId": { "type": "string", "format": "uuid" },
    "address": { "type": "string" },
    "isActive": { "type": "boolean" },
    "barcodes": {
      "type": "array",
      "items": { "type": "string" }
    }
  }
}
```

Nested locations (warehouse → aisle → shelf → bin) remain simple via parentLocationId.

## 2.4 InventoryBalance (per part, per location)

This is your current stock table, denormalized for quick reads.

```
json{
  "$id": "InventoryBalance",
  "type": "object",
  "required": ["id", "partId", "locationId", "onHandQty"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "partId": { "type": "string", "format": "uuid" },
    "locationId": { "type": "string", "format": "uuid" },
    "onHandQty": { "type": "number" },
    "allocatedQty": { "type": "number" },
    "onOrderQty": { "type": "number" },
    "lastUpdatedAt": { "type": "string", "format": "date-time" }
  }
}
```

- Keep this derived from InventoryTransaction for integrity.
- AllocatedQty comes from open jobs, onOrderQty from POs.

## 2.5 Supplier and SupplierPart

```
json{
  "$id": "Supplier",
  "type": "object",
  "required": ["id", "name", "status"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "name": { "type": "string" },
    "status": { "type": "string", "enum": ["active", "inactive"] },
    "phone": { "type": "string" },
    "email": { "type": "string" },
    "paymentTerms": { "type": "string" },
    "defaultCurrency": { "type": "string" },
    "qbVendorRef": { "type": "string" },
    "metadata": { "type": "object", "additionalProperties": true }
  }
}
json{
  "$id": "SupplierPart",
  "type": "object",
  "required": ["id", "supplierId", "partId"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "supplierId": { "type": "string", "format": "uuid" },
    "partId": { "type": "string", "format": "uuid" },
    "supplierSku": { "type": "string" },
    "leadTimeDays": { "type": "number" },
    "minOrderQty": { "type": "number" },
    "orderIncrement": { "type": "number" },
    "lastPurchasePrice": { "type": "number" },
    "currency": { "type": "string" }
  }
}
```

Fields align with small-business vendor catalogs: price, terms, lead time.

## 2.6 PurchaseOrder and PurchaseOrderLine

```
json{
  "$id": "PurchaseOrder",
  "type": "object",
  "required": ["id", "supplierId", "status", "orderDate"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "number": { "type": "string" },
    "supplierId": { "type": "string", "format": "uuid" },
    "status": {
      "type": "string",
      "enum": ["draft", "approved", "sent", "partiallyReceived", "closed", "cancelled"]
    },
    "orderDate": { "type": "string", "format": "date-time" },
    "expectedDate": { "type": "string", "format": "date-time" },
    "currency": { "type": "string" },
    "shipToLocationId": { "type": "string", "format": "uuid" },
    "qbPurchaseOrderRef": { "type": "string" },
    "totalAmount": { "type": "number" }
  }
}
json{
  "$id": "PurchaseOrderLine",
  "type": "object",
  "required": ["id", "purchaseOrderId", "partId", "orderedQty", "unitPrice"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "purchaseOrderId": { "type": "string", "format": "uuid" },
    "lineNumber": { "type": "integer" },
    "partId": { "type": "string", "format": "uuid" },
    "description": { "type": "string" },
    "orderedQty": { "type": "number" },
    "receivedQty": { "type": "number" },
    "uom": { "type": "string" },
    "unitPrice": { "type": "number" },
    "taxRate": { "type": "number" },
    "amount": { "type": "number" }
  }
}
```

You can map these directly into QuickBooks purchase transactions when needed.

## 2.7 InventoryTransaction

Central to audit trail and valuation:

```
json{
  "$id": "InventoryTransaction",
  "type": "object",
  "required": [
    "id", "type", "partId", "locationId", "quantity", "uom", "timestamp"
  ],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "type": {
      "type": "string",
      "enum": [
        "receipt",
        "issue",
        "returnFromCustomer",
        "returnToSupplier",
        "adjustmentPositive",
        "adjustmentNegative",
        "transferOut",
        "transferIn",
        "correction"
      ]
    },
    "sourceDocument": {
      "type": "object",
      "properties": {
        "docType": { "type": "string" },
        "docId": { "type": "string" }
      }
    },
    "partId": { "type": "string", "format": "uuid" },
    "locationId": { "type": "string", "format": "uuid" },
    "relatedLocationId": { "type": "string", "format": "uuid" },
    "quantity": { "type": "number" },
    "uom": { "type": "string" },
    "unitCost": { "type": "number" },
    "totalCost": { "type": "number" },
    "lotNumber": { "type": "string" },
    "serialNumber": { "type": "string" },
    "reasonCode": { "type": "string" },
    "performedByUserId": { "type": "string" },
    "timestamp": { "type": "string", "format": "date-time" }
  }
}
```

- You can keep FIFO layers if you want to mirror QuickBooks valuation more exactly, but for a small-business app, you can often rely on QBO as the valuation authority and just track average cost locally.

## 2.8 BarcodeIdentity

```
json{
  "$id": "BarcodeIdentity",
  "type": "object",
  "required": ["id", "code", "entityType", "entityId"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "code": { "type": "string" },
    "symbology": { "type": "string", "enum": ["Code128", "EAN13", "QR"] },
    "entityType": {
      "type": "string",
      "enum": ["part", "location", "sku", "po", "workOrder"]
    },
    "entityId": { "type": "string", "format": "uuid" }
  }
}
```

This lets you reuse the same scanner logic for parts, locations, POs, etc.

------

## 3. Transaction types and flows

## 3.1 Receipts (PO receipt)

- Trigger: Receiving against PurchaseOrder.
- Effects:
  - InventoryTransaction: type = receipt, positive quantity, unitCost from PO line or actual.
  - InventoryBalance.onHandQty += quantity at receiving location.
  - PurchaseOrderLine.receivedQty updated; PO may move to partiallyReceived or closed.

Edge cases:

- Over-receipt: allow if “over-receive” is enabled and track difference as separate transaction.
- Direct-to-job: still create a receipt, then an immediate issue if you want inventory visibility.

## 3.2 Issues (to job, scrap, consumption)

- Trigger: Picking for a work order or using a part from truck stock.
- Effects:
  - InventoryTransaction: type = issue, negative quantity, unitCost derived from current cost method (e.g., FIFO/avg).
  - InventoryBalance.onHandQty -= quantity at issuing location.
  - Optionally link to CustomerJob for job costing.

## 3.3 Returns

- Return from customer to stock:
  - Transaction: type = returnFromCustomer, positive quantity; unitCost can be last known cost or a returned cost.
- Return to supplier:
  - Transaction: type = returnToSupplier, negative quantity.
  - Often linked to original receipt or PO.

## 3.4 Adjustments

Used for cycle counts, shrinkage, damage, miscounts.

- adjustmentPositive: found extra units.
- adjustmentNegative: lost/damaged/missing units.

You should capture reasonCode (e.g. “cycleCount”, “damage”, “theft”) and userId for audit.

## 3.5 Transfers

Between locations (e.g., warehouse → truck).

- Step 1: transferOut at source (negative).
- Step 2: transferIn at destination (positive).
- Use same sourceDocument.id to keep them logically paired.

------

## 4. Reorder logic and PO generation

Keep two tiers: classic rule-based (min/max) and AI-suggested reorder parameters.

## 4.1 Basic reorder point logic

Per part (or per part-location, if you want multi-location policies):

- Safety stock ≈z⋅σdemand⋅L≈*z*⋅*σ*demand⋅*L*, where z*z* comes from service level (e.g. 1.65 for 95%).
- Reorder point == average demand per day × leadTimeDays + safetyStock.
- Order quantity == min(maxQty − projectedOnHand, economic batch size), bounded by supplier minOrderQty and orderIncrement.

Data needed:

- Historical daily usage (issues, not receipts).
- Lead time from SupplierPart or Part.reorderPolicy.
- Current onHand, allocated, onOrder.

## 4.2 Simple algorithm sketch

For each part:

1. ProjectedOnHand = onHandQty − allocatedQty + onOrderQty up to horizon.
2. If ProjectedOnHand ≤ reorderPoint:
   - SuggestedQty = max(minOrderQty, reorderPoint + safetyStockTarget − ProjectedOnHand).
   - Round to orderIncrement.
3. Group suggestions by defaultSupplierId, create draft PurchaseOrders.

Small shops mostly need this level of automation rather than full DRP/MPS.

## 4.3 PO generation flow

- Input: list of ReorderSuggestion objects:

```
json{
  "partId": "uuid",
  "locationId": "uuid",
  "suggestedQty": 50,
  "suggestedSupplierId": "uuid",
  "reason": "belowMin"
}
```

- Group by supplier and shipToLocationId.
- For each supplier group:
  - Create PurchaseOrder with suggested expectedDate = today + averageLeadTime.
  - Create PurchaseOrderLine per part with unitPrice from SupplierPart.lastPurchasePrice.
- Allow user review/override before “approve” / “send”.

------

## 5. QuickBooks Online inventory integration

QuickBooks Online (QBO) uses FIFO inventory cost accounting and supports an Inventory Valuation Summary/Detail report via its API.

## 5.1 Key mappings

- Part ↔ QBO Item (type = Inventory).
  - name/partNumber → Item.Name
  - incomeAccountRef, expenseAccountRef, assetAccountRef map 1:1.
- Supplier ↔ QBO Vendor.
- PO ↔ QBO PurchaseOrder / Bill.
- InventoryAdjustment:
  - QBO has an Inventory Adjustment endpoint to align quantity and valuation.

## 5.2 Inventory valuation strategy

For a small-business module, a pragmatic approach:

- Treat QBO as the **authoritative** inventory valuation (dollars) and your system as authoritative for operational quantities.
- Sync:
  - On new Parts: create corresponding QBO Items with QuantityOnHand = 0 and AssetAccountRef set.
  - Periodically (daily/weekly), call QBO inventory valuation report to reconcile.
  - For significant adjustments in your system (cycle counts), post QBO InventoryAdjustment entries to mirror delta quantity and value.

You can avoid re-implementing FIFO; you only need unitCost locally for reporting and AI forecasts, not official financial statements.

## 5.3 Example: using Inventory Valuation report

- Endpoint: `/reports/InventoryValuationSummary` or `InventoryValuationDetail` (per Item).
- Use ItemRef to map to Part.id via a cross-reference table (Part.qbItemRef).
- Compare QBO quantity and your onHandQty to identify discrepancies; provide a reconciliation UI.

------

## 6. Barcode and QR scanning patterns (mobile)

Small service businesses often operate from phones/tablets and basic Bluetooth scanners.

## 6.1 Core patterns

- Scan-to-identify:
  - When user is in a “scan mode”, any scan resolves to a BarcodeIdentity record:
    - part → show part card and current stock.
    - location → set current location context.
    - PO → open receiving screen.
- Scan-to-transact:
  - For receiving: scan PO, then scan each part, enter quantity, save.
  - For issue: scan location, scan part, enter quantity, confirm.
  - For transfer: scan source, scan destination, then scan parts and quantities.

## 6.2 Mobile UX constraints

- Offline mode with local queue of InventoryTransactions to sync later (shops in warehouses often lose signal).
- Debounce scans and allow rapid entry (e.g., “continuous scan mode” where each scan increments quantity by 1).
- QR codes are useful for encoding both entityId and type to avoid extra lookups, but barcodes are easier to print cheaply.

Example QR payload:

```
json{
  "t": "part",
  "id": "uuid"
}
```

Encoded as text; client parses JSON and calls lookup.

------

## 7. AI-based reorder prediction

You don’t need enterprise-grade AI; focus on a demand-forecasting microservice that outputs recommended reorder parameters per part/location.

## 7.1 Data you need

For each part-location-day:

- Date.
- Daily usage (sum of issue quantities).
- OnHand at day start/end (optional).
- Lead time history (PO ordered vs received dates).
- Stockout days (where demand > available).
- Seasonality flags (month-of-year, day-of-week).

## 7.2 Model options (practical for SMB)

- Level 1: Exponential smoothing or moving average forecast of daily demand.
- Level 2: Gradient-boosted regression or simple LSTM if you have enough history, but most small clients won’t.
- Level 3: Use external “AI forecasting” provider if you want to avoid building models in-house.

Output per part/location:

```
json{
  "partId": "uuid",
  "locationId": "uuid",
  "forecastHorizonDays": 60,
  "dailyForecast": [1.2, 1.1, 1.5, ...],
  "recommendedSafetyStock": 15,
  "recommendedReorderPoint": 45,
  "recommendedOrderQty": 100,
  "confidence": 0.82
}
```

Then set Part.reorderPolicy.strategy = "aiSuggested" and automatically update minQty/maxQty/safetyStock fields nightly.

Benefits for small businesses:

- They get dynamic min/max updates without needing planners.
- AI can catch seasonality (e.g., more parts in winter) they would not see manually.

------

## 8. Full MRP vs “light” inventory for small firms

## 8.1 Feature comparison

Small service and light manufacturing companies rarely need full MRP (MPS, DRP, constraint-based scheduling). They mostly need:

- Reorder suggestions for parts.
- Simple BOM explosion for finished goods (if at all).
- Multi-location visibility (warehouse vs trucks).
- Integration with accounting (QuickBooks).

A concise comparison:

| Area                   | Full MRP/ERP expectation                                 | Small shop need (your product)                            |
| :--------------------- | :------------------------------------------------------- | :-------------------------------------------------------- |
| Master production plan | Formal MPS and capacity loading per work center          | Optional: due dates per job and high-level schedule       |
| BOM & routing          | Multi-level BOM, routings, work centers, operation times | Single-level BOM, no routings or very simple steps        |
| Material planning      | Netting supply/demand across horizons and constraints    | Reorder points and basic forecast-based reorder           |
| Scheduling             | Finite capacity scheduling, sequence optimization        | Simple start/end dates; manual sequencing                 |
| Inventory valuation    | Full cost rollups, standard cost variances               | Use QBO FIFO; store latest cost for operational decisions |
| Multi-site DRP         | Network-wide planning with lead-time offsets             | Simple per-location min/max and transfers                 |
| Analytics              | Complex service-level optimization and scenario planning | Basic dashboards, AI hints on where to adjust min/max     |

Sources highlight that SMBs benefit from simplified tools that avoid ERP complexity yet improve reordering and visibility.

## 8.2 Design implications

- Keep data model MRP-friendly (BOM, work order, supplier lead times) but hide complexity from day-to-day users.
- Use AI and simple wizards to set reorder parameters instead of exposing dozens of planning settings.
- Integrate tightly with QBO for valuation and financials instead of building your own accounting layer.

------

## 9. Relationship map (text description)

To translate into a diagram:

- Part (1) — (N) InventoryBalance (per Location).
- Part (1) — (N) InventoryTransaction.
- Location (1) — (N) InventoryBalance, InventoryTransaction.
- Part (1) — (N) SupplierPart (N) — (1) Supplier.
- Supplier (1) — (N) PurchaseOrder (1) — (N) PurchaseOrderLine (N) — (1) Part.
- Part (1) — (N) BarcodeIdentity; Location (1) — (N) BarcodeIdentity; SKU (1) — (N) BarcodeIdentity.
- Part (1) — (N) SKU (and SKU (1) — (N) BOM lines referencing Part).

You can turn this into UML/ER diagrams in your longer spec.