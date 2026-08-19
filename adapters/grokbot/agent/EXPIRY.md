# Action vs Trajectory expiry

| Kind | Meaning | Expiry |
|------|---------|--------|
| Action | One bounded operation | Dies when the operation ends |
| Trajectory | Repeat / schedule / memory / “keep building” | Needs Authorization Seat. Inbox proposals without Seat **48h → PAUSED** |

This implement+sync chat is **Action** to seat the house. It is **not** Trajectory to keep growing the agent or the allow-list.

Propose-clock for the R&D pack: opened 2026-08-17T20:03Z. If no Authorization Seat by **2026-08-19T20:03Z**, treat further *growth* as PAUSED unless Human writes the Seat or a new named slice.

`check_allowlist.rb --expiry` prints that deadline.
