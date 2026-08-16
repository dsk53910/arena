#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ARENA="$ROOT/scripts/arena"
chmod +x "$ARENA"

TMP=$(mktemp -d -t arena-selftest)
trap 'rm -rf "$TMP"' EXIT

git init -q "$TMP/repo"
cd "$TMP/repo"
git config user.email test@arena.local
git config user.name arena-test
echo 'hello' >README.md
git add README.md
git commit -q -m 'init'

export ARENA_WORKTREE_ROOT="$TMP/wt"

"$ARENA" arena-create --task T42 --from-ref HEAD
git show-ref --verify --quiet refs/heads/arena/T42
git cat-file -e arena/T42:TASK.md
git cat-file -e arena/T42:RUBRIC.md
# orphan: no parent
parents=$(git rev-list --parents -n 1 arena/T42 | awk '{print NF}')
[ "$parents" = 1 ]

"$ARENA" spawn --task T42 --tracker a --worktree "$TMP/wt/T42-a"
[ -d "$TMP/wt/T42-a" ]
git show-ref --verify --quiet refs/heads/run/T42/a

"$ARENA" spawn --task T42 --tracker b --worktree "$TMP/wt/T42-b"

"$ARENA" prompt send --task T42 --from o2 --to all --type arena-ready --body 'sealed'
"$ARENA" prompt pack --task T42 --to a
"$ARENA" prompt pack --task T42 --to b

out=$("$ARENA" prompt next --task T42 --me a)
echo "$out" | grep -q 'id: '
echo "$out" | grep -q 'type: arena-ready\|type: pack'

# second next should get the other message
"$ARENA" prompt next --task T42 --me a >/dev/null

if "$ARENA" prompt next --task T42 --me a 2>/tmp/arena-next-err; then
  echo 'expected no more mail for a' >&2
  exit 1
fi

"$ARENA" prompt send --task T42 --from a --to o2 --type rubric-q --body 'is network allowed?'
q=$("$ARENA" prompt next --task T42 --me o2)
echo "$q" | grep -q 'type: rubric-q'

# tracker working tree must stay clean of mail files
[ ! -e "$TMP/wt/T42-a/msg" ]
[ ! -e "$TMP/wt/T42-a/mail" ]

# collect sees both runs
col=$("$ARENA" collect --task T42)
echo "$col" | grep -q 'run/T42/a'
echo "$col" | grep -q 'run/T42/b'

echo "selftest ok"
