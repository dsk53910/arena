---
name: prompt
description: Pack, pull, or send Arena mail on mail/<task> (prompts and talk between O1, O2, trackers).
---

# /prompt

Follow `rules/mail-protocol.mdc`. Never paste briefs between chats.

```bash
arena prompt pack --task <id> --to <role> [--body TEXT]
arena prompt next --task <id> --me <role>
arena prompt send --task <id> --from <role> --to <role> --type <type> --body TEXT
```

Types: `arena-ready` | `pack` | `question` | `reply` | `result` | `rubric-q` | `rubric-a`.
