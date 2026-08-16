---
name: tracker
description: Start or continue a tracker session: pull mail, stay in the cage, send result.
---

# /tracker

Follow `skills/tracker/SKILL.md` and `rules/tracker-cage.mdc`.

```bash
arena prompt next --task <id> --me <you>
```

Exit code 2 means no unread mail — continue the current assignment or wait.

Work only on `run/<task>/<you>`. When done, commit `RESULT.md` and:

```bash
arena prompt send --task <id> --from <you> --to o2 --type result --body-file RESULT.md
```
