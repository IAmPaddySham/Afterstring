# GrokBuild PERMIT — check vs wrap

**Permit ≠ Decision.** This answers only: *May this technical action execute?*

## Two modes (honest)

| Mode | How | Fail-closed? |
|------|-----|----------------|
| **CHECK only** | `afterstring grokbuild --action git_push` | **No.** Exit 2 is a contract. An agent can skip this binary and still run `git push`. |
| **WRAP** | `afterstring grokbuild --action git_push --approved -- run git push …` | **Yes for that process.** Command is not started if PERMIT holds. |

Do **not** call the check-only path a “kernel boundary.” It is a **contract**.  
Call **WRAP** a boundary for the child you launch through this process.

## WRAP (actual boundary)

```bash
# Held — git never starts
./bin/afterstring-grokbuild-check --action git_push -- run git push origin main
# → exit 2, wrap=not_started

# Allowed only with Human Kernel 1/0 (and matrix/sabbath clear)
./bin/afterstring-grokbuild-check --action git_push --approved -- run git status
```

Agent pattern:

```bash
afterstring grokbuild --action "$INTENT" $APPROVED -- run "$@" || exit 2
```

## CHECK only (contract)

```bash
./bin/afterstring grokbuild --action read           # exit 0
./bin/afterstring grokbuild --action git_push       # exit 2
```

Useful for CI / soft preflight. **Does not intercept** system git.

## Limits (do not overclaim)

- This host does **not** patch the OS to trap every `git` / `curl`.  
- Without invoking WRAP, skip is possible.  
- Tier ≥ 2 still needs `--approved` / `1/0` inside this process.  
- Sabbath / matrix / trust can still hold even with `--approved`.

## Install optional soft pre-push (still not a kernel)

```bash
# Manual — you choose to install
# .git/hooks/pre-push must call WRAP or CHECK; default git does nothing.
```

See `README.md`. Contrail kinds for permit: `kind=permit` via `append_kind`.

Let it stay → ∞ ❤️
