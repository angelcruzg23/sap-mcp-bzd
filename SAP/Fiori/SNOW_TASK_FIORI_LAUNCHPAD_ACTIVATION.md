# ServiceNow Task — SAP Fiori Launchpad Initial Activation

---

## SNOW Ticket Fields

**Category:** SAP Basis  
**Subcategory:** Configuration / Fiori  
**Priority:** Medium  
**Assignment Group:** SAP Basis Team  
**Configuration Item:** BZD — SAP ECC 6.0 EHP8 (Client 130)  
**Short Description:** Activate SAP Fiori Launchpad infrastructure on BZD 130 (embedded deployment)

---

## Description

### Business Context

The ABAP development team is initiating the SAP Fiori adoption project on the Amrize BP landscape. The first milestone is to enable the Fiori Launchpad (FLP) on the development system BZD (client 130) so the team can begin building and testing Fiori-based user interfaces for Sales & Distribution processes.

This is a first-time activation — Fiori has never been configured on this landscape. The goal is to establish the FLP infrastructure in DEV so it can later be replicated to QA and Production.

All required software components have been verified and are already installed:

| Component | Version | SP |
|---|---|---|
| SAP_BASIS | 750 | SP32 |
| SAP_GWFND | 750 | SP32 |
| SAP_UI | 754 | SP17 |
| SAP_BS_FND | 748 | SP24 |

No additional software installation is required. This request is purely configuration.

---

## Tasks to Execute

### Task 1 — Run the Fiori Embedded Deployment Task List in STC01

This is the main task. It activates SAP Gateway, the Fiori Launchpad services, OData services, and ICF nodes in a single execution.

**Transaction:** `STC01`  
**Task List:** `SAP_GW_FIORI_ERP_ONE_CLNT_SETUP`  
**Client:** 130

**Steps:**

1. Log in to BZD client 130 via SAP GUI with a user that has SAP_ALL or equivalent Basis authorizations.
2. Execute transaction `STC01`.
3. In the "Task List" field, enter: `SAP_GW_FIORI_ERP_ONE_CLNT_SETUP`
4. Press Enter. If the task list is found, click **"Generate Task List Run"** to create a new execution instance.
5. The system will display all sub-tasks with traffic light indicators (green = done, yellow = review, red = needs execution).
6. Select all tasks with red or yellow status and click **Execute** (F8).
7. When prompted for inputs, use the following values:

| Prompt | Value | Notes |
|---|---|---|
| System Alias | `LOCAL` | Embedded deployment — no external Gateway |
| Customizing Request | Create new or use existing | Description: `"Fiori Launchpad initial setup BZD 130"` |

8. Wait for all tasks to complete. Each task should turn green.
9. If any task remains red, open the task log and document the error message.

**Fallback:** If the combined task list `SAP_GW_FIORI_ERP_ONE_CLNT_SETUP` is not available, execute the following four task lists individually in this exact order:

| Order | Task List | Purpose |
|---|---|---|
| 1 | `SAP_GATEWAY_BASIC_CONFIG` | Activate SAP Gateway |
| 2 | `SAP_FIORI_LAUNCHPAD_INIT_SETUP` | Activate FLP OData and ICF services |
| 3 | `SAP_GATEWAY_ACTIVATE_ODATA_SERV` | Register OData services |
| 4 | `SAP_BASIS_ACTIVATE_ICF_NODES` | Activate ICF nodes for UI5 and Fiori |

---

### Task 2 — Verify ICF Nodes Are Active in SICF

After the task list execution, confirm that the following ICF nodes are active (green icon) in transaction `SICF`:

| ICF Path | Node | Purpose |
|---|---|---|
| `/sap/bc/ui2/` | `flp` | Fiori Launchpad entry point |
| `/sap/bc/ui5_ui5/ui2/ushell/shells/abap/` | `FioriLaunchpad` | Classic FLP URL |
| `/sap/bc/ui5_ui5/` | (entire subtree) | SAPUI5 library delivery |
| `/sap/opu/odata/` | `UI2` | OData services for FLP |
| `/sap/public/bc/ui5_ui5/` | (entire subtree) | Public UI5 resources |
| `/sap/bc/nwbc/` | `nwbc` | NetWeaver Business Client |

If any node is inactive (gray icon), right-click → **Activate Service**.

---

### Task 3 — Verify OData Services Are Registered

In transaction `/IWFND/MAINT_SERVICE`, confirm the following services exist and are active:

| Technical Service Name | System Alias | Purpose |
|---|---|---|
| `/UI2/PAGE_BUILDER_PERS` | `LOCAL` | FLP page personalization |
| `/UI2/PAGE_BUILDER_CONF` | `LOCAL` | FLP catalog configuration (cross-client) |
| `/UI2/PAGE_BUILDER_CUST` | `LOCAL` | FLP customizing |
| `/UI2/INTEROP` | `LOCAL` | App interoperability |
| `/UI2/TRANSPORT` | `LOCAL` | FLP configuration transport |
| `/UI2/CATALOGSERVICE` | `LOCAL` | Service catalog |

If any service is missing, click **Add Service** → search for the technical service name → assign System Alias `LOCAL` → save.

---

### Task 4 — Verify ICM Parameters

In transaction `SMICM`, confirm:

1. ICM is running (green status).
2. HTTP and/or HTTPS services are active. Go to **ICM → Services** (Shift+F1) and verify at least one HTTP/HTTPS service is listed and active.
3. Note the port number for HTTP (typically 8000) and HTTPS (typically 8443 or 44300).

---

## Validation / Acceptance Criteria

After completing all tasks above, please verify the following and document the results:

### Test 1 — FLP URL Access

Open a browser and navigate to:
```
https://fbpl08v010.holcimbp.net:8000/sap/bc/ui2/flp
```

**Expected result:** SAP logon screen appears. After entering valid credentials, the Fiori Launchpad loads (empty, with no tiles — this is expected for a fresh setup). The top bar should show a search field and user menu icon.

**If it fails:** Document the HTTP error code (403, 404, 500) and any error message displayed.

### Test 2 — OData Service Metadata

In transaction `/IWFND/GW_CLIENT`, test the following URL:
```
/sap/opu/odata/UI2/PAGE_BUILDER_PERS/$metadata
```

**Expected result:** HTTP 200 response with XML content showing the OData service metadata (EntityTypes, EntitySets, etc.).

### Test 3 — SAPUI5 Library

Open a browser and navigate to:
```
https://fbpl08v010.holcimbp.net:8000/sap/public/bc/ui5_ui5/resources/sap-ui-core.js
```

**Expected result:** JavaScript file loads (you will see minified JS code in the browser).

### Test 4 — Gateway Health Check

In transaction `/IWFND/GW_CLIENT`, test:
```
/sap/opu/odata/IWFND/CATALOGSERVICE/ServiceCollection
```

**Expected result:** HTTP 200 with XML listing all registered OData services.

---

## Additional Notes

- This is a **development system only** (BZD). No production impact.
- Deployment model: **Embedded** (Gateway and FLP on the same server/client as the ECC backend). No separate front-end server is needed.
- A customizing transport request will be generated during the task list execution. Please provide the transport request number in the task completion notes so we can track it.
- If any SAP Notes are flagged as missing during the task list execution, please document the note numbers so we can evaluate them.
- After Basis completes this task, the development team will handle the FLP content configuration (catalogs, groups, tiles, roles) independently.

---

## Contact

For questions about this request, contact the ABAP development team (requestor).

---
