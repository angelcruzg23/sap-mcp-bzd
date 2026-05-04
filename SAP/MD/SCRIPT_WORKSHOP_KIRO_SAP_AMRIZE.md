# Script: Kiro + SAP Workshop — AMRIZE Edition
## Presenter guide — Read, practice, follow live

---

## Before you start

- Duration: ~60 minutes (45 min presentation + 15 min Q&A)
- `[ACTION]` = something you do on screen
- `[PAUSE]` = stop and ask for questions
- `[SLIDE]` = reference to WORKSHOP_KIRO_SAP_AMRIZE.md section
- Tone: conversational, like explaining to a colleague
- Have SAP GUI open as backup in case the live demo fails
- Have the AMRIZE document open for reference tables

---

## PART 1 — The problem we all know (5 min)

---

Let me start with a question. How many hours a week do you spend doing this:

- Reading functional designs trying to find the actual technical requirements
- Navigating SE37, SE38, SE80 looking for objects
- Reading someone else's code trying to understand what it does
- Writing code that follows the same pattern as the 50 lines above it
- Documenting what you did after you did it

If you're honest, it's probably 60-70% of your week. The actual thinking — the design decisions, the edge cases, the "will this break something" — that's maybe 30%.

What if we could flip that ratio?

That's what we've been doing for the past few weeks with Kiro. And today I'm going to show you exactly how, with real cases from our system.

---

## PART 2 — What is Kiro, in 3 minutes (3 min)

---

`[SLIDE: Architecture diagram from AMRIZE doc]`

Five things you need to know:

1. **Kiro is an IDE** — looks like VS Code, built by Amazon, has an AI agent built in
2. **The AI is Claude** — by Anthropic. Not ChatGPT, but same concept: it predicts code based on patterns from millions of programs
3. **MCP is the bridge** — a small Python server we built that translates Kiro's requests into SAP ADT API calls. That's how Kiro reads and writes ABAP in BZD
4. **Steering files are the rules** — 4 markdown files that tell Kiro our naming conventions, coding standards, and SOLID patterns. That's why the code looks like ours, not generic
5. **The developer is always in control** — Kiro proposes, you decide. Nothing goes to SAP without your review

`[PAUSE — Any questions on the setup before we see it in action?]`

---

## PART 3 — The 4 cases (35 min)

---

I'm going to walk you through 4 real cases. These aren't demos built for a presentation — they happened this month, on real tickets, in BZD 130.

`[SLIDE: Time savings table from AMRIZE doc]`

Here's the punchline upfront:

| Case | Manual | With Kiro |
|------|--------|-----------|
| New development | ~2 hours | ~6 min |
| Debugging a production report | ~3 hours | ~13 min |
| FM deploy with 3 iterations | ~4 hours | ~19 min |
| Authority check investigation | ~3-4 hours | ~6 min |
| **Total** | **~12-13 hours** | **~44 min** |

Now let me show you how.

---

### Case 1 — New development from a Functional Design (8 min)
#### CHG0432318: Conestoga Equipment Type

`[ACTION: Open the .mht file in the ConestogaChange folder — show how ugly it looks]`

This is a Functional Design in .mht format. It's basically Word saved as a web archive — full of HTML garbage. Reading this manually takes 30-45 minutes.

`[ACTION: In Kiro chat, type:]`

```
Analyze the requirement in the ConestogaChange folder. Tell me what you understood.
```

`[WAIT — Kiro reads the document and returns a structured summary]`

Look at what it did:
- Extracted the business requirement from HTML noise
- Identified the 5 technical steps
- Listed the SAP objects involved
- Summarized the test scenarios

Two minutes. Now let's find the code.

`[ACTION: In Kiro chat, type:]`

```
Find the Function Modules ZSDE_GET_DATA_SHPMNT_HD_TAB and 
ZSDE_SET_DATA_SHPMNT_HD_TAB in SAP BZD
```

`[WAIT — Kiro searches SAP, discovers they're FMs in a function group, gets the source]`

Notice: Kiro first tried to find them as programs — failed. Then searched by pattern, discovered the function group, and got the source code. That's the same discovery process we do manually in SE80, but in seconds.

`[ACTION: In Kiro chat, type:]`

```
Generate the ABAP changes for the new field ZZEQUIPE_TYPE in LIKP. 
Modify the GET and SET FMs, and add the logic in the enhancement 
to only update when TMS sends 'ZZ' (Conestoga).
```

`[WAIT — Kiro generates 4 files]`

`[ACTION: Open each generated file and point out:]`
- Same comment style with search terms
- Same variable naming pattern (gv_*)
- Same alignment as existing code
- Conditional logic uses a constant, not a hardcoded value

That's the steering files at work. Without them, valid but generic code. With them, code that looks like someone from the team wrote it.

`[PAUSE — Questions on this case?]`

---

### Case 2 — Debugging without opening SAP (8 min)
#### ZSDR_DAILY_INVOICE_REPORT — SCOMNO bug

`[ACTION: Briefly describe the scenario]`

A user gets emails with invoices — SOST shows them as "Transmitted". But the daily invoice report shows them with a red traffic light: Failed. The functional team can't figure out why.

`[ACTION: In Kiro chat, type:]`

```
Read the program ZSDR_DAILY_INVOICE_REPORT from SAP BZD and analyze 
where the traffic light logic could be marking transmitted invoices as failed.
```

`[WAIT — Kiro reads the program, discovers 4 includes, reads all of them in parallel]`

Here's what Kiro found. Deep inside the data processing form, there's this line:

```abap
DELETE ltt_sood WHERE NOT scomno IS INITIAL.
```

Before EHP8, SAPconnect didn't assign `SCOMNO` until later. After EHP8, it assigns it immediately on transmission. So this line now deletes exactly the documents that WERE sent successfully.

The downstream code doesn't find a match, falls into the ELSE, and marks the invoice as Failed.

`[ACTION: Show the fix — TVARVC date switch]`

Kiro proposed a date-based switch using TVARVC — so we don't break pre-EHP8 behavior. Clean, safe, reversible.

The key insight: **Kiro did static debugging**. It never ran the program. It simulated the data flow through the source code and found the root cause. That's something that would take us 1-2 hours of tracing manually.

`[PAUSE — Questions?]`

---

### Case 3 — Live deploy to SAP, 3 iterations (10 min)
#### CHG0436393: Enqueue lock for ZSD_PPD_REJ_UPDATE

`[ACTION: Describe the scenario briefly]`

A Function Module calls `BAPI_CUSTOMERQUOTATION_CHANGE` without checking if the quotation is locked. If someone has it open in VA22, the BAPI can fail silently.

`[ACTION: Show the analysis Kiro produced — the AS-IS vs TO-BE]`

Kiro read the FM, identified both execution paths (CPQ and Workflow), and generated the enqueue/dequeue logic with a retry loop.

But here's where it gets interesting. When we tried to upload the code to SAP, the MCP server couldn't write Function Modules — it only supported programs.

`[ACTION: Explain what happened next]`

So we added that capability. In 5 minutes. A new method in the Python server, a new tool registration, restart, done. The MCP server is a living asset — it grows with every real case.

Then we deployed. And tested. And the retry loop had a bug — `DO...ENDDO` with `EXIT` wasn't behaving correctly in the workflow call stack.

`[ACTION: Show the debugger screenshot if available]`

The developer shared a screenshot from the ABAP debugger. Kiro looked at the image, correlated the variable values with the code, and proposed the fix: replace `DO...ENDDO` with `WHILE` and an explicit exit condition.

Second deploy. Then a third one — adding `MESSAGE TYPE 'E'` so the workflow step lands in ERROR status and can be restarted from SWPR.

Three complete cycles of code → deploy → test → fix → redeploy. In one session. Without opening Eclipse.

`[PAUSE — Questions on the deploy process?]`

---

### Case 4 — Authority check investigation (9 min)
#### ZSDR_ANOKA_REPORT_BAK_N — "No authorization for W56LE601004 in plant 3096"

`[ACTION: Show the screenshot of the SAP GUI error in the status bar]`

This happened this week. A user runs ZSD_ORDER_TRACKING1, gets this error in the status bar, and the report shows nothing. Nobody knows where it comes from.

`[ACTION: In Kiro chat, type:]`

```
Analyze program ZSDR_ANOKA_REPORT_BAK_N to find where the authorization 
error "No authorization for W56LE601004 in plant 3096" is being triggered. 
The message appears during data processing, not when clicking in the ALV.
```

`[WAIT — Kiro reads the main program, discovers 3 includes, reads all of them]`

2,500 lines of ABAP across 3 includes. Kiro read all of it in seconds and found:

- 3 explicit authority checks in the code — **none of them generate this message**
- The real culprit: `MD_STOCK_REQUIREMENTS_LIST_API` — a standard SAP FM that does its own internal authority check on object `M_MTDI_ORG`
- The program calls this FM inside a loop and has an empty error handler:

```abap
IF sy-subrc <> 0.
  " ← Nothing here. Error leaks to status bar.
ENDIF.
```

This started happening with EHP8 — the FM has stricter authority checks now.

`[ACTION: Show the proposed fix — 9 lines]`

The fix is elegant: replicate the same authority check the FM does internally, but BEFORE calling it. If the user doesn't have authorization for that plant, skip the record silently.

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

9 lines. No other changes. The report works, unauthorized plants are silently excluded, no error messages.

Then Kiro generated the complete technical analysis report in English — root cause, code location, before/after behavior, impact assessment. Ready to attach to the ticket.

`[PAUSE — Questions on this case?]`

---

## PART 4 — What changes for us (7 min)

---

`[SLIDE: "What Kiro does vs. what stays with you" table from AMRIZE doc]`

Let me be clear about what this is and what it isn't.

**Kiro compresses mechanical work.** The reading, searching, pattern-matching, typing, documenting — that goes from hours to minutes.

**Kiro does NOT replace your judgment.** The design decisions, the "will this break something", the testing, the transport to production — that's still 100% you.

Your role shifts:

| Before | Now |
|--------|-----|
| Document reader | Analysis validator |
| Object searcher | Proposal reviewer |
| Code writer | Solution architect |
| Manual documenter | Documentation curator |

The value is no longer in how fast you type. It's in your technical judgment, your knowledge of the business, your ability to say "this is right" or "this won't work because..."

### The rules

`[SLIDE: "Rules for working with AI in SAP" from AMRIZE doc]`

Ten rules. The three most important:

1. **Always create the transport request manually** — give the number to Kiro. Never let it create OTs in systems with CTS Project Management.
2. **Always review the diff before uploading** — read the current code from SAP, compare with what Kiro proposes, then upload.
3. **The developer is always accountable** — Kiro is a tool. You sign off on the code that goes to SAP.

`[SLIDE: Controlled deploy flow diagram from AMRIZE doc]`

---

## PART 5 — What you need to get started (5 min)

---

To use this in your daily work, you need:

1. **Kiro installed** — free tier available at kiro.dev, looks like VS Code
2. **MCP server configured** — Python server that connects to SAP via ADT. Installation guide available (15 min setup)
3. **VPN access to SAP** — same as Eclipse ADT
4. **Steering files** — we'll share the 4 files that encode our team standards

My suggestion: install it this week. Start simple — search for an object, read a program you already know. Build confidence. Then try it on a real ticket.

---

## PART 6 — Q&A (15 min)

---

`[ACTION: Open for questions. Have these ready:]`

**"Can Kiro see production data?"**
No. It uses ADT — same API as Eclipse. It can only do what your SAP user is authorized to do.

**"Is the generated code secure?"**
As secure as what you'd write. The steering files enforce standards, but final review is yours.

**"Does this work with S/4HANA?"**
Yes. ADT REST API works the same. Just update the steering files to allow ABAP Cloud syntax if needed.

**"What if Kiro generates wrong code?"**
It happens. That's why the flow always includes human review. If it's a recurring pattern, update the steering files.

**"Can I connect Kiro to other systems?"**
Yes. MCP is an open protocol. You can build servers for any system with an API.

**"How much does it cost?"**
Kiro has a free tier with usage limits and a paid tier. Details at kiro.dev.

**"Can Kiro interpret debugger screenshots?"**
Yes — we demonstrated this in Case 3. Share the image in chat and Kiro correlates variable values with the code.

---

## Presenter checklist

- [ ] Kiro open with the project workspace
- [ ] MCP server connected (run a ping test)
- [ ] VPN connected to SAP BZD
- [ ] ConestogaChange folder with the .mht file
- [ ] Screenshot of the authority error (Case 4)
- [ ] WORKSHOP_KIRO_SAP_AMRIZE.md open for reference tables
- [ ] ZSDR_ANOKA_REPORT_BAK_N/ANALYSIS_AUTHORITY_CHECK_MD_STOCK.md ready to show
- [ ] Screen sharing ready
- [ ] Clean Kiro chat (no previous session history)
- [ ] Backup: pre-generated ABAP files in case the live demo fails

---

*Script v1.0 — April 2026*
*Duration: ~60 minutes (45 presentation + 15 Q&A)*
*Audience: ABAP developers, mixed technical level*
*Reference: WORKSHOP_KIRO_SAP_AMRIZE.md*
