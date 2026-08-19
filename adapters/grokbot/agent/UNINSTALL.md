# Uninstall / Release

```
Install → Run → Pause → Disable → Remove this directory → Verify
```

Verify:

- `adapters/grokbot/` sidecar (README, runner, SKILL, STANDING_ORDERS) still present  
- `constitution/matrix-grokbot.yaml` untouched  
- no After_* processes  
- Contrail may append `host_event` uninstall; do not rewrite history  

If remove damages the sidecar, **do not install.** Release ≡ Also Love is this cycle, not a slogan.

To remove now (Human or Grokbot after Seat):

```bash
rm -rf ~/afterstring/adapters/grokbot/agent
```
