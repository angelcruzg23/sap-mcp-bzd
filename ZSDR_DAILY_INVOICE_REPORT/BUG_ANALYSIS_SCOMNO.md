# Bug Analysis — ZSDR_DAILY_INVOICE_REPORT
## Invoices marked as "Failed" when they were actually transmitted

| Field | Value |
|-------|-------|
| Program | ZSDR_DAILY_INVOICE_REPORT |
| Transaction | ZSD_DAILY_INVOICE |
| WRICEF | SD_E_618 |
| Affected include | ZSDR_DAILY_INVOICE_REPORT_F01 |
| Affected FORM | F_GET_DATA |
| Reported by | End user |
| Severity | High — incorrect information in daily control report |

---

## 1. Problem description

The user reports that invoice emails are being received correctly in their mailbox, and when checking transaction SOST the status shows as **"Transmitted"**. However, the Z report (`ZSD_DAILY_INVOICE`) displays the invoice with a **red traffic light (F = Failed)**, indicating the transmission failed.

This causes operational confusion and undermines trust in the report as a daily monitoring tool.

---

## 2. Root cause identified

In the FORM `f_get_data` within include `ZSDR_DAILY_INVOICE_REPORT_F01`, after extracting SAPoffice documents from the `SOOD` table, the following line is executed:

```abap
DELETE ltt_sood WHERE NOT scomno IS INITIAL.
```

### What does this line do?

It removes from the internal table `ltt_sood` all records that have a SAPcomm number (`SCOMNO`) assigned.

### Why is this a problem?

When SAPconnect successfully transmits a document, it assigns a `SCOMNO` in the `SOOD` table. In other words, **having a `SCOMNO` is evidence that the document WAS processed and transmitted successfully**.

By deleting these records, the subsequent LOOP finds no match in `ltt_sood_hashed` and falls into the ELSE branch, which assigns a red traffic light:

```abap
LOOP AT ltt_invoice INTO DATA(ls_invoice).
  ...
  READ TABLE ltt_sood_hashed INTO DATA(ls_sood)
       WITH KEY objdes = ls_invoice-tdcovtitle.
  IF sy-subrc EQ 0.
    " Looks up SOST and assigns traffic light based on result
    ...
  ELSE.
    " ← FALLS HERE because the record was removed by the DELETE
    gs_report-icon  = icon3.    " 🔴 RED traffic light
    gs_report-vstat = |F|.      " Status: Failed
    APPEND gs_report TO gt_report.
  ENDIF.
ENDLOOP.
```

### Error flow diagram

```
SOOD (SAPoffice document)
  │
  ├─ scomno IS INITIAL     → Kept in ltt_sood → Matched with SOST → Correct traffic light
  │
  └─ scomno IS NOT INITIAL → ❌ REMOVED by DELETE → No match → RED traffic light (incorrect)
                               ↑
                               The document WAS transmitted successfully,
                               but the report marks it as failed
```

---

## 3. Error context

This behavior started manifesting **after the EHP8 upgrade**. It is likely that EHP8 changed the timing at which SAPconnect assigns the `SCOMNO` in `SOOD`, or that it now assigns it more immediately, causing the field to already be populated at the time the report queries the data.

**Before EHP8:** the `SCOMNO` was possibly assigned later, so the `DELETE` did not affect recent records.

**After EHP8:** the `SCOMNO` is assigned during transmission, so the `DELETE` removes successfully transmitted documents.

---

## 4. Proposed solution

Implement a **date-based switch** using a TVARVC variable that allows:
- Keeping the original behavior (with the `DELETE`) for documents prior to EHP8
- Disabling the `DELETE` for documents from the cutoff date onwards

### 4.1 TVARVC configuration

Create an entry in TVARVC:

| Field | Value |
|-------|-------|
| Name | ZSD_DAILY_INV_EHP8_DATE |
| Type | P (Parameter) |
| Low | 20260401 (cutoff date — adjust to actual EHP8 go-live date) |

### 4.2 Modified code

**Before (current code with the bug):**
```abap
DELETE ltt_sood WHERE NOT scomno IS INITIAL.
```

**After (fixed code with TVARVC switch):**
```abap
* ── EHP8 Switch: do not delete transmitted documents after cutoff date ──
* The cutoff date is configured in TVARVC variable ZSD_DAILY_INV_EHP8_DATE
* Before that date, original behavior is preserved (DELETE with scomno)
* After that date, the DELETE is skipped to avoid marking as Failed
* documents that were actually transmitted successfully.
DATA: lv_ehp8_cutoff TYPE sy-datum.

SELECT SINGLE low
  INTO lv_ehp8_cutoff
  FROM tvarvc
  WHERE name = 'ZSD_DAILY_INV_EHP8_DATE'
    AND type = 'P'.

IF sy-subrc <> 0.
  " If the variable does not exist, use original behavior for safety
  lv_ehp8_cutoff = '99991231'.
ENDIF.

IF so_erdat-low < lv_ehp8_cutoff.
  " Original pre-EHP8 behavior
  DELETE ltt_sood WHERE NOT scomno IS INITIAL.
ENDIF.
```

### 4.3 Switch logic explanation

| Scenario | Report filter date | Behavior |
|----------|-------------------|----------|
| Pre-EHP8 | Before TVARVC date | Executes the `DELETE` (original behavior) |
| Post-EHP8 | Equal to or after TVARVC date | **Skips the `DELETE`**, transmitted documents are kept and correctly matched with SOST |
| TVARVC not found | Any | Executes the `DELETE` (safe fallback, breaks nothing) |

---

## 5. Implementation steps

1. Create variable `ZSD_DAILY_INV_EHP8_DATE` in TVARVC (transaction STVARV) with the EHP8 cutoff date
2. Modify include `ZSDR_DAILY_INVOICE_REPORT_F01` with the proposed code
3. Activate and test with invoices that currently show red but are transmitted in SOST
4. Verify that invoices prior to EHP8 still display correctly

---

## 6. Risk assessment

| Risk | Mitigation |
|------|------------|
| Breaking pre-EHP8 behavior | The date-based switch ensures it only applies to new dates |
| TVARVC variable not created | Fallback uses date 99991231, preserving original behavior |
| Duplicates in SOOD due to skipping DELETE | Low risk: the subsequent `DELETE ADJACENT DUPLICATES` already handles duplicates |
