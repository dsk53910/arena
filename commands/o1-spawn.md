---
name: o1-spawn
description: Spawn N isolated tracker worktrees from arena/<task> and pack their prompts.
---

# /o1-spawn

You are O1 (Planner). Follow `skills/o1-planner/SKILL.md`.

1. `arena status --task <id>` — refuse if `arena/<id>` is missing.
2. For each tracker:

```bash
arena spawn --task <id> --tracker <name>
arena prompt pack --task <id> --from o1 --to <name>
```

3. Tell the human the worktree path. The tracker session must start **in that directory** and run `/tracker`.
4. Do not write the rubric. Do not pick a winner.
