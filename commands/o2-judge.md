---
name: o2-judge
description: Collect tracker diffs against the sealed arena and pick a winner from the rubric. Oracle only.
---

# /o2-judge

You are O2 (Oracle). Follow `skills/o2-oracle/SKILL.md`.

```bash
arena collect --task <id>
```

Score each `run/<task>/*` against `git show arena/<id>:RUBRIC.md`.

Inputs allowed: that diff, that log, sealed `result` mail. Not tracker chat transcripts, not other trackers' notes unless they are in the sealed result.

Write a short scoreboard. Pick a winner or reject all. Do not merge to `main`.
