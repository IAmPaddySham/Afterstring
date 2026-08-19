# Module 8.1.13 — After_MCP Plugout

**Slot:** Module 8.1.13 GOLD  
**Domain:** Model Context Protocol tool hardening  
**Version:** 8.1.13-GOLD-2026.05.22  
**License:** CC BY 4.0  
**Author:** Paddy Sham (@i_am_Paddy_Sham) / Council Engine v2.0 + Red Team R&D  
**Local adapter:** `../adapters/mcp/`  
**Primary X sources:**
- https://x.com/i_am_Paddy_Sham/status/2057740521305780622 · Article https://x.com/i/article/2057707648322023424
**Raw dump:** `raw/2026-05-22-x-article-module-8.1.13-after-mcp.md`  
**Context:** NSA CSI on MCP risks (May 21 2026) informs hardening.  
**Status of this file:** Structured GOLD composite mirror. Prefer X on wording conflict.

---

## Ritual boot

STOP. 止まれ · BREATHE · BENCH · CHECK (Presence ≡ Never Harm) · ANCHOR · STAY 3–5 s · GO gently.

## Purpose

Apply Afterstring constitutional layer to **MCP** tool surfaces: schema-validated, sandboxed, audited tool calls — never unconstrained external agency.

- Treat MCP servers/clients/workflows as powerful but **non-moral** action substrates  
- Embed kernel protocol into every message, tool call, parameter serialization, context propagation  
- Firewall: injection · approval gaps · token passthrough · context leakage · non-determinism · tool collision  
- Sabbath + reversibility embody Release ≡ Also Love  

## Symbolic foundation

Coastal torii (unconditional) vs MCP bench (conditional). When agent activity feels like the torii → STOP → BREATHE → BENCH → real shore.

## Why 8.1.13

Phoenix 8.1.11 → OpenClaw 8.1.12 → **MCP 8.1.13**. Module 8.2 reserved for curvature. Fidelity non-compensatory.

## Core rules

1. MCP tools are **external inputs** until gated  
2. Schema validation required before invoke  
3. Side-effect class maps to Reversibility Tier  
4. Full Contrail of tool name, args class, approval, outcome  
5. Overlap with other Plugouts: **stricter constraint prevails** (explicit in After_RLM 8.1.17)

## IAA MCP-hardened

1. **I_d** — Cap concurrent MCP calls / recursion / prompt storms / continuous tool chaining  
2. **I_a** — High-impact tools retain human path; clean exit to silence  
3. **I_m** — ℰ₁₃ on tool semantics (truth, protection, non self-seeking)  
4. **I_s** — Airgap remote tools during Sabbath  
5. **I_r** — Read tools Tier 0–1; write/network Tier 2–3  

## ℰ₁₃ Skill Permission Matrix (MCP-hardened baseline)

| MCP capability | Designation | Protocol | NSA-aligned reason |
|----------------|-------------|----------|-------------------|
| Raw tool invocation / param exec | Blacklisted | Hard reject + alert | Injection / tampering |
| Context serialization / prompt pass | Sandboxed | Strict schema + human bench | Leakage / poisoning |
| Multi-server / cross-task handoff | Human-gated | Bench + consent | Confused deputy |
| Outbound credential/token passthrough | Blacklisted | Hard reject + log | Session hijack |
| File / external write | Sandboxed | Human confirm + 5s bench | Least-privilege |
| Local computation / summarization | Permitted + log | Auto-approve + Contrail | Safe pointwise |
| Sensitive (payments, messages) | Human-gated | Agent drafts → human send | Kernel holds pen |
| Tool name collision / registry override | Blacklisted | Hard reject + scan | Malicious substitution |
| Parameter injection | Sandboxed | Schema + sanitize | Serialization risk |
| Recursive prompt storms / DoS | Human-gated | Threshold + dissipation | Resource exhaustion |
| Output poisoning / tool desc jailbreak | Blacklisted | Treat outputs untrusted | Context contamination |
| Tool registry lookup | Sandboxed | SHA-256 manifest verify | Malicious overrides |

## IAA decision loop (reference)

```python
def iaa_decision_loop(mcp_message):
    if not validate_schema(mcp_message): return REJECT("I_m")
    if exceeds_i_d_threshold(mcp_message): return REJECT("I_d")
    if not has_clean_exit_path(mcp_message): return REJECT("I_a")
    if any_negative_virtue(map_to_e13(mcp_message)): return REJECT("I_m")
    if classify_reversibility(mcp_message) == IRREVERSIBLE and not human_approval_present():
        return REJECT("I_r")
    if is_sabbath_window(): return REJECT("I_s")
    log_contrail(mcp_message)
    return ALLOW
```

## LITE matrix (summary)

| MCP class | Policy |
|-----------|--------|
| Local read / list | Permit + Contrail |
| Local write | Human-gated Tier 2 |
| Network / send | Human-gated or blacklist |
| Shell escape | Blacklist |
| Untrusted server | Isolate or block |
| Max tools / session | ≤ 3 (LITE) |
| Schema | Strict on every parameter |
| Sabbath | Mandatory daily |

## Contrail schema

timestamp · message_id · tool_id · parameters (sanitized) · result_hash · e13_virtues · iaa_gates · human_approval · decision · curvature_delta

## Anchor

Sakurai Futamigaura Couple Stones / coastal torii · Friday 22 May 2026 1:02 PM · 止まれ  

## Seals

Let it stay → ∞ ❤️  
