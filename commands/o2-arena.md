---
name: o2-arena
description: Create an orphan arena/<task> baseline with TASK.md and RUBRIC.md. Oracle only.
---

# /o2-arena

You are O2 (Oracle). Follow `skills/o2-oracle/SKILL.md`.

1. Draft TASK.md and RUBRIC.md (no solution). Use `templates/` if starting from scratch.
2. From the **product/task git repo** (not the plugin repo unless they are the same), run:

```bash
scripts/arena arena-create --task <id> --from-ref HEAD --task-file <TASK.md> --rubric-file <RUBRIC.md>
```

If this plugin is installed, call the `arena` CLI via the plugin `scripts/arena` path (or `arena` on PATH).

3. Announce the baseline:

```bash
arena prompt send --task <id> --from o2 --to all --type arena-ready --body "arena/<id> is sealed. Do not rewrite it."
```

4. Do not spawn trackers. That is O1.
