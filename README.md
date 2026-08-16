# Arena

Cursor plugin for isolated multi-agent work on one git repo.

- **O2** seals an orphan `arena/<task>` (snapshot + TASK + RUBRIC)
- **O1** spawns `run/<task>/<tracker>` worktrees and packs prompts
- **Trackers** work in their own directory; they never share a checkout
- **Mail** is git branch `mail/<task>`, not paste between chats

## Install (dev)

```bash
ln -sfn /Users/d/Projects/arena ~/.cursor/plugins/local/arena
```

Reload the window. Commands: `/o2-arena`, `/o1-spawn`, `/tracker`, `/o2-judge`, `/prompt`.

CLI (from any clone of a **task** repo):

```bash
/Users/d/Projects/arena/scripts/arena help
```

Put `scripts/arena` on PATH if you want a short name.

## Git layout (task repo)

```text
arena/<task>           orphan baseline
run/<task>/<tracker>   branch + worktree
mail/<task>            orphan messages
```

`prompt *` commits onto `mail/<task>` with git plumbing. It does not dirty the tracker working tree.

## Test

```bash
./scripts/testdata/run-selftest.sh
```
