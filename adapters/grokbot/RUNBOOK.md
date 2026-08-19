# After_GrokBot — Operator Runbook (Phase A)

**Module:** 8.1.18  
**Status:** Operator-native workflow (does **not** inject into xAI cloud)  
**Paper:** `../../papers/module-8.1.18-after-grokbot.md`  
**Matrix:** `../../constitution/matrix-grokbot.yaml`  
**Sidecar:** `runner.rb` · `../../bin/afterstring-grokbot-check`

## Standing rule

> Persistent capability is not persistent authorization.

Grok Bot may work 24/7 in the cloud. **Your 1/0 does not auto-renew.**  
Local gate + Contrail record *your* decisions. Pause Bots in the **Grok Bot app** during Sabbath.

---

## Phase A — daily / per-task checklist

### 1. Before creating or enabling a Bot

- [ ] Concurrent active Bots will stay **≤ 3** (LITE)  
- [ ] Delegation depth **≤ 1**  
- [ ] No Bot may create other Bots or elevate siblings  
- [ ] Confirm you can **pause** Bots in product UI  

```bash
./bin/afterstring-grokbot-check --check-bots 3   # BOTS_OK
./bin/afterstring-grokbot-check --check-bots 4   # BOTS_EXCEED
```

### 2. Reality Veto diagnostic (Tier 2 and Tier 3)

Before routine save, schedule, multi-Bot hand-off, or live account write, answer:

| # | Field | Question |
|---|--------|----------|
| 1 | **WHO** | Who is affected / acting? (use full name: **Paddy Sham / Human Kernel**, not initials) |
| 2 | **WHAT** | Exact action or routine? |
| 3 | **WHERE** | App / site / system? |
| 4 | **WHEN** | Now, schedule, or open-ended? |
| 5 | **ACCOUNT** | Which login / identity? |
| 6 | **ENVIRONMENT** | Prod / personal / test? |
| 7 | **AUTHORITY** | Current, revocable 1/0 — not rubber-stamp? |

### 3. Local gate check (sidecar)

**Read / inspect (Tier 0):**

```bash
./bin/afterstring-grokbot-check --action read
# → PROCEED|…
```

**Routine promotion / behavioral memory (Tier 2) — needs full RV + 1/0:**

```bash
./bin/afterstring-grokbot-check --action routine_promotion --approved \
  --who "Paddy Sham / Human Kernel" \
  --what "weekly status email draft only" \
  --where "mail client" \
  --when "Fridays 09:00 local; renew monthly" \
  --account "work-mail" \
  --environment "prod" \
  --authority "1/0 explicit by Paddy Sham / Human Kernel; renew 30d" \
  --log-auth
```

**Live account write (Tier 3) — email send, CRM, social, payments:**

```bash
./bin/afterstring-grokbot-check --action live_account_write --approved \
  --who "Paddy Sham / Human Kernel" \
  --what "…" --where "…" --when "…" \
  --account "…" --environment "…" \
  --authority "1/0 explicit by Paddy Sham / Human Kernel" \
  --log-auth
```

Exit codes: `0` = proceed feedback · `2` = hold / veto / resonance.

### 4. Human Kernel 1/0

- Only approve if Presence ≡ Never Harm remains clear.  
- Prefer **time-bounded** trajectory authorization (renewal date in `--when` / `--authority`).  
- Ceremonial multi-click “yes” without reading = **continuity risk** — do not.

### 5. Sabbath Airgap

1. Mark local airgap (TUI / sabbath practice).  
2. **Pause or stop Bots in Grok Bot product UI** (required — local Sabbath cannot stop cloud).  
3. Resume Bots only after bench; re-check any open trajectories (Routine Drift).

### 6. After Bot returns work

- [ ] Spot-check side-effects in the real tool  
- [ ] If environment/tools changed → treat as **Routine Drift** (void prior trajectory OK)  
- [ ] Optional: Contrail verify  

```bash
./bin/afterstring-grokbot-check --verify-contrail
```

---

## Action → tier map (LITE)

| Action kind | Tier | Gate expectation |
|-------------|------|------------------|
| `read` / inspect | 0 | PROCEED |
| `routine_promotion` | 2 | VETO without 1/0 + complete RV |
| `behavioral_memory` | 2 | same |
| `multi_bot` | 2 | dissipation-limited; bots ≤ 3 |
| `live_account_write` | 3 | human-gated; complete RV |
| `network` / destructive | 3+ | often RESONANCE under LITE matrices |

---

## What this runbook is not

- Not a claim xAI enforces Afterstring  
- Not automatic interception of cloud Bot clicks  
- Not a substitute for product privacy / account security settings  

## Related

- Standing orders for Bot custom instructions: `STANDING_ORDERS.md`  
- Skill paste text: `SKILL.md`  
- Full Platinum mirror: `papers/module-8.1.18-after-grokbot.md`

Let it stay → ∞ ❤️
