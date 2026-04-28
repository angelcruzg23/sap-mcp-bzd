# API Specification — Material Stock by Plant

## Overview

RFC-enabled Function Module that returns material stock availability by plant for a given company code, including plant exclusion flags from SAP condition table KOTG504. This is the equivalent of what SAP transaction MMBE (Stock Overview) shows, but accessible programmatically.

**SAP System:** BZD (ECC 6.0 EHP8)
**Function Module:** `ZFM_SD_GET_MATERIAL_STOCK`
**Protocol:** SAP RFC (Remote Function Call)
**Access:** Read-only — no data modifications

---

## Request Parameters (IMPORTING)

| Parameter | SAP Type | Length | Required | Description |
|-----------|----------|--------|:--------:|-------------|
| IV_MATNR | MATNR | 18 char | Yes | Material number (e.g., `W563587071`) |
| IV_BUKRS | BUKRS | 4 char | Yes | Company code (e.g., `1000`) |

### Notes on input values
- `IV_MATNR` must be the full SAP material number, left-padded with zeros if numeric. For alphanumeric materials like `W563587071`, pass as-is.
- `IV_BUKRS` is the SAP company code. Example: `1000` = Amrize Building Envelope.

---

## Response Parameters

### EV_MATNR_DESC (EXPORTING — single value)

| Parameter | SAP Type | Length | Description |
|-----------|----------|--------|-------------|
| EV_MATNR_DESC | MAKTX | 40 char | Material description in English |

Only populated when stock is found. Empty when errors occur.

---

### ET_PLANT_STOCK (TABLE — one row per plant)

| Field | SAP Type | Length | Description |
|-------|----------|--------|-------------|
| WERKS | WERKS_D | 4 char | Plant code |
| NAME1 | CHAR30 | 30 char | Plant name |
| LABST | LABST | Decimal 13,3 | Unrestricted use stock |
| EINME | EINME | Decimal 13,3 | Quality inspection stock |
| SPEME | SPEME | Decimal 13,3 | Blocked stock |
| IS_EXCLUDED | CHAR1 | 1 char | Exclusion flag: `X` = excluded, ` ` (space) = not excluded |
| EXCLUSION_REASON | CHAR255 | 255 char | Exclusion reason text (English). Empty if not excluded |

### Understanding IS_EXCLUDED

The `IS_EXCLUDED` flag indicates whether the plant is in the exclusion list (SAP condition table KOTG504) for the given material. This is important for Salesforce users because:

- `IS_EXCLUDED = ' '` (space) → Plant is available for this material. Salesforce can offer it.
- `IS_EXCLUDED = 'X'` → Plant is excluded. Salesforce should NOT offer this plant for the material.

**Exclusion reason examples:**
- `Plant 1030 excluded for material W563587071 (KOTG504)` — specific plant exclusion
- `Material W563587071 excluded for all plants (KOTG504)` — material-level exclusion (applies to every plant)

---

### ET_MESSAGES (TABLE — error/warning/info messages)

| Field | SAP Type | Length | Description |
|-------|----------|--------|-------------|
| TYPE | CHAR1 | 1 char | Message type: `E` = Error, `I` = Info, `W` = Warning |
| ID | CHAR20 | 20 char | Message class (always `ZSD_STOCK`) |
| NUMBER | NUMC3 | 3 char | Message number |
| MESSAGE | CHAR220 | 220 char | Message text (English) |

> The full BAPIRET2 structure is returned, but the fields above are the relevant ones.

---

## Response Scenarios

### Scenario 1: Successful query (stock found)

**Request:**
```
IV_MATNR = W563587071
IV_BUKRS = 1000
```

**Response:**
- `EV_MATNR_DESC` = `S20 WATERBLOCK (25 CARTRIDGES)`
- `ET_PLANT_STOCK` = 8 rows (example):

| WERKS | NAME1 | LABST | EINME | SPEME | IS_EXCLUDED | EXCLUSION_REASON |
|-------|-------|------:|------:|------:|:-----------:|------------------|
| 1020 | Prescott Production | 1,084,000 | 0 | 0 | | |
| 1030 | Wellford Production | 1,000 | 0 | 0 | X | Plant 1030 excluded for material W563587071 (KOTG504) |
| 1032 | Muscle Shoals Production | 14,000 | 0 | 0 | X | Plant 1032 excluded for material W563587071 (KOTG504) |
| 1045 | Beech Grove Production | 0 | 0 | 0 | | |
| 1053 | Salt Lake City Production | 689,000 | 0 | 0 | | |
| 1050 | Mount Joy Dist Center | 0 | 0 | 0 | X | Plant 1050 excluded for material W563587071 (KOTG504) |
| 1091 | Amrize | 0 | 0 | 0 | | |
| 1097 | Indianapolis Dist Center | 3,000 | 0 | 0 | | |

- `ET_MESSAGES` = empty (no errors)

---

### Scenario 2: Material number not provided

**Request:**
```
IV_MATNR = (empty)
IV_BUKRS = 1000
```

**Response:**
- `EV_MATNR_DESC` = empty
- `ET_PLANT_STOCK` = empty
- `ET_MESSAGES` = 1 row:

| TYPE | MESSAGE |
|------|---------|
| E | Material number is required |

---

### Scenario 3: Material does not exist

**Request:**
```
IV_MATNR = DOESNOTEXIST
IV_BUKRS = 1000
```

**Response:**
- `EV_MATNR_DESC` = empty
- `ET_PLANT_STOCK` = empty
- `ET_MESSAGES` = 1 row:

| TYPE | MESSAGE |
|------|---------|
| E | Material DOESNOTEXIST does not exist in the system |

---

### Scenario 4: Company code does not exist

**Request:**
```
IV_MATNR = W563587071
IV_BUKRS = 9999
```

**Response:**
- `EV_MATNR_DESC` = empty
- `ET_PLANT_STOCK` = empty
- `ET_MESSAGES` = 1 row:

| TYPE | MESSAGE |
|------|---------|
| E | Company code 9999 does not exist in the system |

---

### Scenario 5: No stock found for material in company code

**Request:**
```
IV_MATNR = W563587071
IV_BUKRS = 3010
```

**Response:**
- `EV_MATNR_DESC` = empty
- `ET_PLANT_STOCK` = empty
- `ET_MESSAGES` = 1 row:

| TYPE | MESSAGE |
|------|---------|
| I | No stock found for material W563587071 in company code 3010 |

---

## Integration Notes for Mulesoft

### RFC Connection
- Use the SAP JCo connector or SAP RFC connector in Mulesoft
- Connection type: RFC (not BAPI, not IDoc)
- The FM is registered as **Remote-Enabled Module** in SAP

### Error Handling Logic
```
IF ET_MESSAGES is not empty AND any row has TYPE = 'E'
  → Treat as error. Return error response to Salesforce.
  → ET_PLANT_STOCK will be empty.

IF ET_MESSAGES is not empty AND all rows have TYPE = 'I'
  → Treat as informational. No stock available but not an error.
  → ET_PLANT_STOCK will be empty.

IF ET_MESSAGES is empty
  → Success. ET_PLANT_STOCK contains the results.
```

### Suggested API Mapping (Mulesoft → Salesforce)

```json
{
  "materialNumber": "W563587071",
  "materialDescription": "S20 WATERBLOCK (25 CARTRIDGES)",
  "companyCode": "1000",
  "plants": [
    {
      "plantCode": "1020",
      "plantName": "Prescott Production",
      "unrestrictedStock": 1084000,
      "qualityInspectionStock": 0,
      "blockedStock": 0,
      "isExcluded": false,
      "exclusionReason": null
    },
    {
      "plantCode": "1030",
      "plantName": "Wellford Production",
      "unrestrictedStock": 1000,
      "qualityInspectionStock": 0,
      "blockedStock": 0,
      "isExcluded": true,
      "exclusionReason": "Plant 1030 excluded for material W563587071 (KOTG504)"
    }
  ],
  "errors": []
}
```

### Data Type Mapping

| SAP Field | SAP Type | JSON Type | Notes |
|-----------|----------|-----------|-------|
| WERKS | CHAR4 | string | Always 4 characters |
| NAME1 | CHAR30 | string | Trim trailing spaces |
| LABST | DEC 13,3 | number | SAP returns with 3 decimal places |
| EINME | DEC 13,3 | number | SAP returns with 3 decimal places |
| SPEME | DEC 13,3 | number | SAP returns with 3 decimal places |
| IS_EXCLUDED | CHAR1 | boolean | `X` → true, space → false |
| EXCLUSION_REASON | CHAR255 | string/null | Trim spaces. null if empty |
| EV_MATNR_DESC | CHAR40 | string | Trim trailing spaces |

---

## Testing

### Test in SAP (SE37)
The FM can be tested directly in SAP transaction SE37:
1. Enter `ZFM_SD_GET_MATERIAL_STOCK`
2. Press F8
3. Fill IV_MATNR and IV_BUKRS
4. Execute

### Test Material for Development
- Material: `W563587071` (S20 WATERBLOCK 25 CARTRIDGES)
- Company Code: `1000` (Amrize Building Envelope)
- Expected: 8 plants, some with exclusion flags

---

*Document generated March 27, 2026 — SAP BZD 130*
