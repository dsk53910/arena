# git plumbing for arena/run/mail refs. Never checkout the caller's worktree.
# Requires: die, PLUGIN_ROOT. Callers must run inside a git repo.

arena_abs_git_common() {
  local d
  d=$(git rev-parse --git-common-dir) || die "not a git repository"
  (cd "$d" && pwd)
}

arena_repo_name() {
  local top
  top=$(git rev-parse --show-toplevel) || die "not a git repository"
  basename "$top"
}

arena_lock() {
  local common lockdir
  if [ -n "${ARENA_LOCKDIR:-}" ]; then
    return 0
  fi
  common=$(arena_abs_git_common)
  lockdir="$common/arena.lock"
  while ! mkdir "$lockdir" 2>/dev/null; do
    sleep 0.05
  done
  ARENA_LOCKDIR=$lockdir
  trap 'rmdir "$ARENA_LOCKDIR" 2>/dev/null || true' EXIT INT TERM
}

arena_ref_exists() {
  git show-ref --verify --quiet "refs/heads/$1"
}

arena_with_temp_index() {
  ARENA_GIT_DIR=$(arena_abs_git_common)
  ARENA_INDEX=$(mktemp -t arena-index)
  rm -f "$ARENA_INDEX"
  export GIT_DIR=$ARENA_GIT_DIR
  export GIT_INDEX_FILE=$ARENA_INDEX
  unset GIT_WORK_TREE
}

arena_drop_temp_index() {
  rm -f "${ARENA_INDEX:-}"
  unset GIT_DIR GIT_INDEX_FILE ARENA_INDEX ARENA_GIT_DIR
}

arena_author_env() {
  if [ -z "${GIT_AUTHOR_NAME:-}" ]; then
    export GIT_AUTHOR_NAME=arena
    export GIT_AUTHOR_EMAIL=arena@local
  fi
  if [ -z "${GIT_COMMITTER_NAME:-}" ]; then
    export GIT_COMMITTER_NAME="${GIT_AUTHOR_NAME}"
    export GIT_COMMITTER_EMAIL="${GIT_AUTHOR_EMAIL:-arena@local}"
  fi
}

# Create orphan refs/heads/$1 from tree of $2, overlay files from remaining
# args as "path=srcfile" pairs.
arena_commit_orphan_from() {
  local branch=$1
  local from_ref=$2
  shift 2
  local from_sha tree commit src dest blob

  from_sha=$(git rev-parse --verify "$from_ref") || die "cannot resolve $from_ref"
  arena_ref_exists "$branch" && die "branch $branch already exists"

  arena_lock
  arena_with_temp_index
  git read-tree "$from_sha" || die "read-tree $from_sha failed"
  while [ $# -gt 0 ]; do
    dest=${1%%=*}
    src=${1#*=}
    [ -f "$src" ] || die "missing overlay file $src"
    blob=$(git hash-object -w "$src") || die "hash-object $src failed"
    git update-index --add --cacheinfo 100644 "$blob" "$dest" || die "update-index $dest failed"
    shift
  done
  tree=$(git write-tree) || die "write-tree failed"
  arena_author_env
  commit=$(git commit-tree "$tree" -m "arena baseline from $from_sha") || die "commit-tree failed"
  git update-ref "refs/heads/$branch" "$commit" || die "update-ref $branch failed"
  arena_drop_temp_index
}

# Commit file $3 (absolute) as path $2 onto branch $1. Creates orphan if needed.
arena_commit_file_on_branch() {
  local branch=$1
  local relpath=$2
  local src=$3
  local msg=$4
  local parent tree commit blob

  [ -f "$src" ] || die "missing $src"
  arena_lock
  arena_with_temp_index
  if arena_ref_exists "$branch"; then
    parent=$(git rev-parse "$branch")
    git read-tree "$parent" || die "read-tree $branch failed"
  else
    parent=""
  fi
  blob=$(git hash-object -w "$src") || die "hash-object failed"
  git update-index --add --cacheinfo 100644 "$blob" "$relpath" || die "update-index $relpath failed"
  tree=$(git write-tree) || die "write-tree failed"
  arena_author_env
  if [ -n "$parent" ]; then
    commit=$(git commit-tree "$tree" -p "$parent" -m "$msg") || die "commit-tree failed"
  else
    commit=$(git commit-tree "$tree" -m "$msg") || die "commit-tree failed"
  fi
  git update-ref "refs/heads/$branch" "$commit" || die "update-ref $branch failed"
  arena_drop_temp_index
  echo "$commit"
}

arena_default_worktree() {
  local task=$1
  local tracker=$2
  local root=${ARENA_WORKTREE_ROOT:-"$HOME/.cursor/worktrees"}
  echo "$root/$(arena_repo_name)/${task}-${tracker}"
}

arena_spawn_run() {
  local task=$1
  local tracker=$2
  local path=$3
  local arena_branch="arena/$task"
  local run_branch="run/$task/$tracker"

  arena_ref_exists "$arena_branch" || die "missing $arena_branch (create with arena-create)"
  arena_ref_exists "$run_branch" && die "branch $run_branch already exists"
  [ -e "$path" ] && die "worktree path exists: $path"

  mkdir -p "$(dirname "$path")"
  git worktree add -b "$run_branch" "$path" "$arena_branch"
}

arena_fill_template() {
  local src=$1
  local dest=$2
  local task=$3
  local tracker=${4:-}
  sed -e "s/{{task}}/$task/g" -e "s/{{tracker}}/$tracker/g" "$src" >"$dest"
}
