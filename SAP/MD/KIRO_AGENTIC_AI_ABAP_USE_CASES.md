# Kiro: Agentic AI — ABAP Use Cases within Amrize
## Real cases from SAP ECC BZD 130 — April 2026

---

## Executive Summary

Over the past month, the SD development team has been using Kiro (Amazon's AI-powered IDE) connected to SAP BZD 130 via a custom MCP server. This document catalogs every real use case executed, with measured time savings and lessons learned.

Combined results across all cases: **~15 hours of manual work compressed to ~50 minutes (~94% reduction)**.

---

## Architecture

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

Key components:
- **Kiro IDE** — AI agent (Claude by Anthropic) with integrated tools
- **MCP Server** — Python process that translates AI requests into SAP ADT REST API calls
- **Steering files** — 7 markdown files encoding team standards (naming, coding, SOLID patterns, deploy workflow)
- **SAP BZD 130** — Development system, ECC 6.0 EHP8, ABAP 7.50

---

## Use Case Catalog


### UC-1: New Development from Functional Design
**CHG0432318 — Conestoga Equipment Type for US Bank**

| Attribute | Detail |
|-----------|--------|
| Category | New development |
| Objects | FMs ZSDE_GET/SET_DATA_SHPMNT_HD_TAB, Enhancement ZSDE_TMS2SAP_DELIVERY_DATA |
| What Kiro did | Parsed .mht FD, found objects in SAP, generated 4 ABAP files following existing patterns |
| Key capability | Document analysis + SAP object discovery + code generation with team conventions |
| Manual estimate | ~2 hours |
| With Kiro | ~6 minutes |

---

### UC-2: Static Debugging of Production Report (EHP8 Bug)
**ZSDR_DAILY_INVOICE_REPORT — SCOMNO bug**

| Attribute | Detail |
|-----------|--------|
| Category | Bug investigation / Root cause analysis |
| Objects | Program ZSDR_DAILY_INVOICE_REPORT + 4 includes (~1,500 lines) |
| What Kiro did | Read all includes, simulated data flow, found that `DELETE ltt_sood WHERE NOT scomno IS INITIAL` deletes transmitted docs after EHP8 |
| Key capability | Static debugging — simulated execution flow without running the program |
| Root cause | EHP8 changed SAPconnect behavior: SCOMNO now assigned immediately on transmission |
| Fix pattern | TVARVC date switch to protect pre-EHP8 behavior |
| Manual estimate | ~3 hours |
| With Kiro | ~13 minutes |
| MCP evolution | Added `sap_get_include_source` tool during this session (3 min) |

---

### UC-3: FM Modification with Live Deploy (3 Iterations)
**CHG0436393 — Enqueue lock for ZSD_PPD_REJ_UPDATE**

| Attribute | Detail |
|-----------|--------|
| Category | Code modification + deploy + iterative debugging |
| Objects | FM ZSD_PPD_REJ_UPDATE (function group ZSD_PPD) |
| What Kiro did | Analyzed FM, generated enqueue/dequeue logic, deployed 3 times with fixes |
| Iteration 1 | Initial deploy with ENQUEUE + DO loop → loop didn't exit correctly |
| Iteration 2 | Kiro analyzed debugger screenshot, fixed DO→WHILE conversion |
| Iteration 3 | Added MESSAGE TYPE 'E' for Workflow integration (SWPR restart) |
| Key capability | Debugger screenshot interpretation + iterative deploy without Eclipse |
| Manual estimate | ~4 hours |
| With Kiro | ~19 minutes |
| MCP evolution | Added `sap_update_function_module_source` tool during this session (5 min) |

---

### UC-4: Authority Check Investigation
**ZSDR_ANOKA_REPORT_BAK_N — "No authorization for W56LE601004 in plant 3096"**

| Attribute | Detail |
|-----------|--------|
| Category | Incident investigation / Root cause analysis |
| Objects | Program ZSDR_ANOKA_REPORT_BAK_N + 3 includes (~2,500 lines) |
| What Kiro did | Read all code, found 3 explicit auth checks (ruled out all 3), identified real culprit: standard FM `MD_STOCK_REQUIREMENTS_LIST_API` with internal auth check on `M_MTDI_ORG` |
| Key capability | Cross-reference analysis — traced error from status bar through call stack to standard FM |
| Fix | 9-line pre-check replicating the FM's internal AUTHORITY-CHECK before calling it |
| Manual estimate | ~3-4 hours |
| With Kiro | ~6 minutes |

---

### UC-5: Modern ABAP Architecture (SOLID Refactoring)
**ZR_SD_QUICK_ORDERS — Monolith to testable architecture**

| Attribute | Detail |
|-----------|--------|
| Category | Architecture / Refactoring / Best practices |
| Objects | ZR_SD_QUICK_ORDERS, ZCL_SD_QUICK_ORDERS, ZCL_SD_QUICK_ORDERS_DAO, ZIF_SD_QUICK_ORDERS_DAO, ZCL_SD_QUICK_ORDERS_TEST |
| What Kiro did | Refactored monolithic report into DAO pattern with dependency injection and ABAP Unit tests |
| Key capability | Applied SOLID principles from steering files to generate testable architecture |
| Patterns applied | SRP (separate DAO), DIP (ZIF_ interfaces), ABAP Unit with test doubles |

---

### UC-6: SOLID Architecture for RFC Integration
**ConsultaStockMaterial — ZFM_SD_GET_MATERIAL_STOCK**

| Attribute | Detail |
|-----------|--------|
| Category | New development / RFC integration / Full SOLID architecture |
| Objects | ZFM_SD_GET_MATERIAL_STOCK, ZCL_SD_STOCK_QUERY, ZCL_SD_STOCK_DAO, ZCL_SD_EXCLUSION_CHECKER + 3 interfaces + 3 test classes |
| What Kiro did | Designed and generated complete architecture: FM facade → orchestrator → DAO + exclusion checker, all with interfaces and ABAP Unit tests |
| Key capability | End-to-end architecture generation following team patterns |
| Patterns applied | FM as OO facade, DAO pattern, ISP (3 focused interfaces), DIP with defaults, test doubles |

---

### UC-7: Code Review + Refactoring + Deploy with Syntax Check
**CHG0434843 — PROS Currency Rate GET (ZSD_PROS_CURRENCY_RATE_GET)**

| Attribute | Detail |
|-----------|--------|
| Category | Code review + refactoring + deploy + tooling evolution |
| Objects | FM ZSD_PROS_CURRENCY_RATE_GET (function group ZSD_PROS_INT) |
| What Kiro did | Listed open transport requests, identified objects in OT, reviewed code quality, refactored SELECT-in-LOOP to FOR ALL ENTRIES, deployed with OT, ran syntax check |
| Issues found in original code | SELECT * inside LOOP, no SY-SUBRC check, dead commented code, no documentation |
| Deploy iterations | 3 — first had wrong `INTO TABLE` (needed `INTO CORRESPONDING FIELDS OF TABLE`), second had incompatible types in FOR ALL ENTRIES (needed `TYPE tcurr-campo` instead of data elements) |
| Key capability | Transport request listing + code review + syntax check via ADT |
| Lessons learned | FOR ALL ENTRIES requires `TYPE tabla-campo` (not data elements); ADT activation ≠ syntax check |
| Manual estimate | ~2 hours |
| With Kiro | ~8 minutes |
| MCP evolution | Added `sap_syntax_check` tool during this session |

---

### UC-8: EHP8 Impact Analysis (Daily Invoice Report Deploy)
**CHG0436752 — Deploy of SCOMNO fix to BZD**

| Attribute | Detail |
|-----------|--------|
| Category | Deploy control / Process validation |
| Objects | Include ZSDR_DAILY_INVOICE_REPORT_F01 |
| What Kiro did | Read current code from SAP, compared with local fix, deployed with provided OT, activated, verified |
| Key lesson | CTS Project Management blocks OT creation via ADT API — must create OTs manually in SE09 |
| Process validated | Full controlled deploy flow: read baseline → diff → upload → activate → verify |

---

## MCP Server Evolution Timeline

The MCP server is a living asset that grows with each real case:

| Capability | Tool | When added | Triggered by |
|-----------|------|------------|--------------|
| Ping SAP | `sap_ping` | Initial build | — |
| Read programs | `sap_get_program_source` | Initial build | — |
| Read classes | `sap_get_class_source` | Initial build | — |
| Read FMs | `sap_get_function_module_source` | Initial build | — |
| Search objects | `sap_search_objects` | Initial build | — |
| Read DDIC tables | `sap_get_table_definition` | Initial build | — |
| Create programs | `sap_create_program` | Initial build | — |
| Update programs | `sap_update_program_source` | Initial build | — |
| Activate objects | `sap_activate_object` | Initial build | — |
| Run ABAP Unit | `sap_run_abap_unit` | Initial build | — |
| ADT capabilities | `sap_check_adt_capabilities` | Initial build | — |
| Test endpoints | `sap_test_endpoint` | Initial build | — |
| **Read includes** | `sap_get_include_source` | UC-2 (3 min) | Couldn't read report includes |
| **Update FMs** | `sap_update_function_module_source` | UC-3 (5 min) | Couldn't write FM source |
| **Create transports** | `sap_create_transport` | UC-8 | Needed OT creation |
| **Syntax check** | `sap_syntax_check` | UC-7 | Activation passed but code had syntax errors |

**Current total: 16 tools** — each added in response to a real need, tested immediately in production context.

---

## Steering Files (Team Knowledge Base)

7 steering files encode team standards that Kiro follows automatically:

| File | Purpose |
|------|---------|
| `01-holcim-context.md` | System info, EHP8 context, module landscape |
| `02-naming-conventions.md` | Object prefixes, variable conventions, search terms |
| `03-coding-standards.md` | Mandatory/prohibited patterns, validated production patterns, lessons learned |
| `04-solid-patterns.md` | DIP with ZIF_, DAO pattern, FM as OO facade, test doubles |
| `06-sap-deploy-workflow.md` | 9-step controlled deploy flow, OT rules, MCP limitations |
| `07-mcp-server-python.md` | MCP server coding standards, ADT endpoint reference |

These files are the reason Kiro generates code that looks like it was written by someone on the team.

---

## Time Savings Summary

| # | Use Case | Category | Manual | With Kiro | Savings |
|---|----------|----------|--------|-----------|---------|
| 1 | Conestoga Equipment Type | New development | ~2h | ~6 min | 95% |
| 2 | SCOMNO Bug (Daily Invoice) | Bug investigation | ~3h | ~13 min | 93% |
| 3 | PPD Enqueue Lock (3 deploys) | Modify + deploy + debug | ~4h | ~19 min | 92% |
| 4 | Authority Check Investigation | Incident investigation | ~3.5h | ~6 min | 97% |
| 7 | PROS Currency Rate Refactor | Code review + deploy | ~2h | ~8 min | 93% |
| | **Total measured** | | **~14.5h** | **~52 min** | **~94%** |

---

## What Kiro Does vs. What Stays With the Developer

| Kiro does | Developer does |
|-----------|---------------|
| Read thousands of lines of code in seconds | Decide if the analysis is correct |
| Find objects across SAP modules | Validate business impact |
| Generate code following team patterns | Review every line before deploy |
| Produce technical documentation | Test in the real system |
| Deploy and activate in DEV | Transport to QAS/PRD (manual, controlled) |
| Analyze debugger screenshots | Make design decisions |
| Run syntax checks after deploy | Interpret warnings and decide action |
| List transport requests | Create OTs with correct CTS project |

---

## Key Takeaways

1. **Kiro compresses mechanical work, not thinking** — reading, searching, writing, documenting goes from hours to minutes. Design decisions, testing, and accountability stay with the developer.

2. **The MCP server is a living asset** — 16 tools built organically, each triggered by a real need. Adding a new capability takes 3-5 minutes.

3. **Steering files are the multiplier** — without them, Kiro generates valid but generic ABAP. With them, it generates code that follows team conventions from day one. They also accumulate lessons learned (like the FOR ALL ENTRIES typing rule).

4. **Static debugging is a game changer** — Kiro simulates data flow through source code without running the program. It identified root causes in 2,500+ line programs that would take hours of manual tracing.

5. **Iterative deploy cycles are the new normal** — code → deploy → test → fix → redeploy, all from the same chat session, without switching tools.

6. **The developer's role shifts from executor to architect** — the value is in technical judgment, business knowledge, and the ability to say "this won't work because..."

7. **Every mistake becomes a permanent lesson** — syntax errors, type mismatches, and deploy issues get documented in steering files so they never happen again.

---

*Compiled from real work sessions — Amrize BP, April 2026*
*System: SAP ECC 6.0 EHP8 (BZD, Client 130)*
*AI: Kiro IDE with Claude (Anthropic) via MCP Server*
