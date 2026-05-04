# Workshop: Kiro + SAP — AI-Powered ABAP Development
## From hours to minutes: real cases from Holcim BP

---

## What is Kiro?

Kiro is an AI-powered IDE built by Amazon. It looks like VS Code but has an integrated AI agent that can read files, execute commands, follow team rules, and connect to external systems via MCP (Model Context Protocol).

For SAP developers, this means Kiro can read and write ABAP code directly in SAP — without opening SAP GUI or Eclipse ADT.

```
┌─────────────────────────────────────┐
│            Kiro IDE                  │
│  ┌──────────┐  ┌──────┐  ┌───────┐  │
│  │ Steering │  │ Chat │  │ Files │  │
│  │  Rules   │  │Agent │  │       │  │
│  └──────────┘  └──┬───┘  └───────┘  │
│                   │                  │
│            ┌──────┴──────┐           │
│            │ MCP Client  │           │
│            └──────┬──────┘           │
└───────────────────┼─────────────────┘
                    │ HTTP/REST
             ┌──────┴──────┐
             │ MCP Server  │
             │  (Python)   │
             └──────┬──────┘
                    │ ADT REST API
             ┌──────┴──────┐
             │  SAP BZD    │
             │ ECC 6.0 EHP8│
             └─────────────┘
```

### 5 concepts you need

| Concept | What it is |
|---------|-----------|
| LLM | The AI brain (Claude by Anthropic) — predicts code based on patterns from millions of programs |
| Prompt | Your instruction to the AI — the more specific, the better the output |
| Context | Everything the AI knows: open files, team rules, conversation history, SAP code it read |
| MCP | The bridge between Kiro and SAP — translates AI requests into ADT REST API calls |
| Steering | Team rules in `.kiro/steering/*.md` that make Kiro generate code in YOUR style |

---

## The 5 real cases

All cases below happened in actual work sessions at Holcim BP, system BZD 130.

---

### Case 1 — New development from a Functional Design
**CHG0432318: Conestoga Equipment Type for US Bank**

A functional design in `.mht` format described adding field `ZZEQUIPE_TYPE` to delivery processing. Kiro:

1. Parsed the messy HTML document and extracted the 5 technical steps
2. Found the Function Modules in SAP (`ZSDE_GET_DATA_SHPMNT_HD_TAB`, `ZSDE_SET_DATA_SHPMNT_HD_TAB`) and the enhancement `ZSDE_TMS2SAP_DELIVERY_DATA`
3. Generated 4 ABAP files following the existing code patterns (search terms, variable naming, alignment)

| Task | Manual | With Kiro |
|------|--------|-----------|
| Analyze the FD | 30-45 min | 2 min |
| Find SAP objects | 15-20 min | 1 min |
| Generate code | 45-60 min | 3 min |
| **Total** | **~2 hours** | **~6 min** |

---

### Case 2 — Debugging a production report (SCOMNO bug)
**ZSDR_DAILY_INVOICE_REPORT — invoices showing as Failed when actually Transmitted**

A user reported that invoices appeared with red traffic lights in the report even though SOST showed them as "Transmitted". Kiro:

1. Read the main program + 4 includes from SAP (when the MCP server couldn't read includes, we added that capability in 3 minutes and kept working)
2. Simulated the data flow through `f_get_data` and found the root cause:

```abap
DELETE ltt_sood WHERE NOT scomno IS INITIAL.
```

After EHP8, SAPconnect assigns `SCOMNO` immediately on transmission. This line deletes exactly the documents that WERE sent successfully.

3. Proposed a fix using a TVARVC date switch to protect pre-EHP8 behavior
4. Generated bilingual analysis reports (EN/ES) and the modified include

| Task | Manual | With Kiro |
|------|--------|-----------|
| Read program + 4 includes | 15-20 min | 1 min |
| Find root cause | 1-2 hours | 5 min |
| Generate fix + reports | 50-75 min | 4 min |
| **Total** | **~3 hours** | **~13 min** |

---

### Case 3 — FM modification with live deploy to SAP
**CHG0436393: Enqueue lock for ZSD_PPD_REJ_UPDATE**

The FM called `BAPI_CUSTOMERQUOTATION_CHANGE` without checking if the quotation was locked. Kiro:

1. Read the FM source, analyzed both execution paths (CPQ and Workflow)
2. Generated the enqueue/dequeue logic with retry loop (24 × 5s = 2 min max)
3. When the MCP server couldn't write FMs, we added that capability in 5 minutes
4. Deployed, activated, and verified — all from the chat
5. After testing revealed a loop issue, Kiro analyzed a debugger screenshot and fixed the `DO...ENDDO` → `WHILE` conversion
6. Added `MESSAGE TYPE 'E'` for Workflow integration so failed steps land in SWPR for restart

Three deploy cycles in one session — code → deploy → test → fix → redeploy — without opening Eclipse.

| Task | Manual | With Kiro |
|------|--------|-----------|
| Read and analyze FM | 20-30 min | 2 min |
| Design + documentation | 1-2 hours | 5 min |
| 3 deploy cycles + fixes | 1-2 hours | 11 min |
| **Total** | **~4 hours** | **~19 min** |

---

### Case 4 — Authority check investigation
**ZSDR_ANOKA_REPORT_BAK_N — "No authorization for W56LE601004 in plant 3096"**

A user got an authorization error when running transaction ZSD_ORDER_TRACKING1. Nobody knew where it came from. Kiro:

1. Read the main program + 3 includes (~2,500 lines of ABAP)
2. Found 3 explicit authority checks in the code — and ruled out all 3
3. Identified the real culprit: `MD_STOCK_REQUIREMENTS_LIST_API` performs an internal `AUTHORITY-CHECK` on object `M_MTDI_ORG` that the program never handles:

```abap
IF sy-subrc <> 0.
  " ← Empty block: error leaks to status bar
ENDIF.
```

4. Proposed a 9-line pre-check that replicates the FM's internal validation:

```abap
AUTHORITY-CHECK OBJECT 'M_MTDI_ORG'
  ID 'MDAKT' FIELD 'A'
  ID 'WERKS' FIELD wa_vbap-werks
  ID 'DISPO' DUMMY.
IF sy-subrc NE 0.
  CLEAR ls_mdps.
  CONTINUE.
ENDIF.
```

5. Generated a complete technical analysis report in English

| Task | Manual | With Kiro |
|------|--------|-----------|
| Read 2,500+ lines across 3 includes | 60-90 min | 2 min |
| Identify root cause (standard FM, not custom code) | 30-60 min | 1 min |
| Propose fix + generate report | 45-65 min | 3 min |
| **Total** | **~3-4 hours** | **~6 min** |

---

### Case 5 — Modern ABAP development with SOLID patterns
**ZR_SD_QUICK_ORDERS — from monolith to testable architecture**

Kiro helped refactor a classic monolithic report into a clean architecture:

```
BEFORE:                          AFTER:
ZR_SD_QUICK_ORDERS               ZR_SD_QUICK_ORDERS        → UI only
├── Selection screen              └── ZCL_SD_QUICK_ORDERS   → Business logic
├── SELECT on VBAK/VBAP                └── ZIF_SD_QUICK_ORDERS_DAO  → Contract
├── Processing logic                         └── ZCL_SD_QUICK_ORDERS_DAO  → Data access
└── ALV display               ZCL_SD_QUICK_ORDERS_TEST     → Unit tests with mocks
```

Key principles applied:
- **DAO pattern** — all SELECTs in a separate class, never in the report
- **Dependency Inversion** — business class receives `ZIF_` interface, not `ZCL_` concrete class
- **ABAP Unit** — tests with mock DAO, no database needed, runs in seconds


---

## The numbers

### Time savings across all cases

| Case | Manual | With Kiro | Savings |
|------|--------|-----------|---------|
| 1 — New development (Conestoga) | ~2 hours | ~6 min | 95% |
| 2 — Debugging (SCOMNO bug) | ~3 hours | ~13 min | 93% |
| 3 — FM deploy + 3 iterations (PPD) | ~4 hours | ~19 min | 92% |
| 4 — Authority check investigation | ~3-4 hours | ~6 min | 97% |
| **Combined** | **~12-13 hours** | **~44 min** | **~94%** |

### What Kiro does vs. what stays with you

| Kiro does | You do |
|-----------|--------|
| Read thousands of lines of code in seconds | Decide if the analysis is correct |
| Find objects across SAP modules | Validate business impact |
| Generate code following team patterns | Review every line before deploy |
| Produce technical documentation | Test in the real system |
| Deploy and activate in DEV | Transport to QAS/PRD (manual, controlled) |
| Analyze debugger screenshots | Make design decisions |

---

## MCP Server capabilities

The MCP server grew organically — each real case revealed a missing capability that was added in minutes.

| Capability | Tool | Added in |
|-----------|------|----------|
| Ping SAP | `sap_ping` | Initial |
| Read programs | `sap_get_program_source` | Initial |
| Read includes | `sap_get_include_source` | Case 2 (3 min) |
| Read classes | `sap_get_class_source` | Initial |
| Read Function Modules | `sap_get_function_module_source` | Initial |
| Search objects | `sap_search_objects` | Initial |
| Read DDIC tables | `sap_get_table_definition` | Initial |
| Create programs | `sap_create_program` | Initial |
| Update programs/includes | `sap_update_program_source` | Initial |
| Update Function Modules | `sap_update_function_module_source` | Case 3 (5 min) |
| Activate objects | `sap_activate_object` | Initial |
| Run ABAP Unit | `sap_run_abap_unit` | Initial |
| Create transport requests | `sap_create_transport` | Case 2 deploy |

---

## Rules for working with AI in SAP

These rules come from real mistakes and lessons learned across all sessions.

### Transport control
1. **Always create the OT manually in SE09** — give the number to Kiro explicitly
2. **Never let Kiro create OTs in systems with CTS Project Management** — it doesn't support the project assignment

### Deploy control
3. **Read the current code from SAP before uploading** — verify the diff
4. **One object at a time** — if something breaks, you know exactly what
5. **Verify after deploy** — read the code back from SAP to confirm
6. **Activate explicitly** — separate the upload from the activation

### Quality control
7. **Never upload code you don't understand** — ask Kiro to explain line by line
8. **Kiro deploys to DEV only** — transport to QAS/PRD is 100% manual and controlled
9. **The MCP server is your responsibility** — review its code, apply least privilege to the SAP user
10. **The developer is always accountable** — Kiro is a tool, you sign off on the code

```
┌──────────────────────────────────────────────┐
│          CONTROLLED DEPLOY FLOW               │
│                                               │
│  1. Dev creates OT in SE09 ─────┐             │
│  2. Kiro reads current code     │  HUMAN      │
│  3. Dev reviews the diff        │  CONTROL    │
│  4. Dev gives OT to Kiro ───────┘             │
│  5. Kiro uploads code                         │
│  6. Dev requests verification ──┐             │
│  7. Dev activates (or asks Kiro)│ VERIFICATION│
│  8. Kiro reads code back ───────┘             │
│  9. Dev tests in system                       │
│ 10. Dev transports to QAS/PRD ── TRANSPORT    │
└──────────────────────────────────────────────┘
```

---

## Steering files — why Kiro generates code that looks like yours

Four markdown files in `.kiro/steering/` make the difference between generic ABAP and team-standard ABAP:

| File | Purpose |
|------|---------|
| `01-holcim-context.md` | System info: ECC 6.0 EHP8, BZD 130, ABAP 7.5 SP19, no S/4HANA syntax |
| `02-naming-conventions.md` | Prefixes: ZCL_, ZIF_, ZR_, variable prefixes (mo_, mv_, lv_, lt_...) |
| `03-coding-standards.md` | Mandatory: ABAP Unit tests, no SELECT *, no SELECTs in LOOPs |
| `04-solid-patterns.md` | DIP with ZIF_ interfaces, DAO pattern, dependency injection |

Without these files, Kiro generates valid but generic ABAP. With them, it generates code that follows your team's conventions from day one.

---

## Key takeaways

1. **Kiro compresses mechanical work, not thinking** — you still design, review, test, and decide. But the reading, searching, writing, and documenting happens in minutes instead of hours.

2. **The MCP server is a living asset** — every real case discovers a missing capability. Adding it takes minutes, not days. The pattern (lock → write → unlock) is consistent across SAP object types.

3. **Kiro does static debugging** — it doesn't need to run the program. By simulating data flow through the source code, it can identify root causes that would take hours of manual tracing.

4. **Quality of output = quality of input** — vague prompts get vague code. Specific instructions with object names, field names, and business rules get production-ready proposals.

5. **The developer's role shifts from executor to reviewer** — the value is no longer in typing speed. It's in technical judgment, business knowledge, and the ability to say "this is right" or "this won't work because..."

6. **Documentation becomes a byproduct** — analysis reports, technical designs, and implementation guides are generated as part of the work, not as an afterthought.

7. **Kiro reads debugger screenshots** — developers can share images from the ABAP debugger and Kiro correlates variable values with code to identify bugs.

8. **Three deploy cycles in one session is normal** — code → deploy → test → fix → redeploy without switching tools. The feedback loop is dramatically shorter.

---

*Built from real work sessions at Holcim BP — April 2026*
*System: SAP ECC 6.0 EHP8 (BZD, Client 130)*
*AI: Kiro IDE with Claude (Anthropic) via MCP*
