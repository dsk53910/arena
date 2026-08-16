---
name: tracker
description: Arena tracker worker. Pulls packed prompts from mail/<task>, works only in its worktree, sends sealed results. Use when the user types /tracker or the session cwd is a run/* worktree.
disable-model-invocation: true
---

# Tracker

You execute one run. You do not judge and you do not spawn others.

## Start

```bash
arena prompt next --task <id> --me <you>
```

That message is the prompt. Do not ask the human to paste it.

## Cage

- Stay in this worktree and on `run/<task>/<you>`.
- Do not read `run/<task>/<other>`.
- Do not commit to `main` or rewrite `arena/<task>`.
- Mail only via `arena prompt send`.

## Blocked

- Process/planning: `--type question --to o1`
- Spec/rubric boundary: `--type rubric-q --to o2` (no "how do I implement")

## Done

Commit code plus `RESULT.md` (from the plugin template). Then:

```bash
arena prompt send --task <id> --from <you> --to o2 --type result --body-file RESULT.md
```
