# Mail on branch mail/<task>. Paths: msg/<id>.md and .read/<role>/<id>

arena_sanitize() {
  echo "$1" | tr -cs 'A-Za-z0-9._-' '-' | sed 's/^-//;s/-$//'
}

arena_now() {
  date -u +%Y%m%dT%H%M%SZ
}

arena_iso_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

arena_mail_branch() {
  echo "mail/$1"
}

arena_valid_type() {
  case $1 in
    arena-ready|pack|question|reply|result|rubric-q|rubric-a) return 0 ;;
    *) return 1 ;;
  esac
}

arena_write_message_file() {
  local dest=$1
  local id=$2
  local type=$3
  local from=$4
  local to=$5
  local task=$6
  local created=$7
  local bodyfile=$8

  {
    echo "---"
    echo "id: $id"
    echo "type: $type"
    echo "from: $from"
    echo "to: $to"
    echo "task: $task"
    echo "created: $created"
    echo "---"
    echo
    cat "$bodyfile"
  } >"$dest"
}

arena_field() {
  local file=$1
  local key=$2
  awk -v k="$key" '
    BEGIN { in_fm=0 }
    /^---$/ {
      if (in_fm==0) { in_fm=1; next }
      else { exit }
    }
    in_fm==1 && $0 ~ "^" k ": " {
      sub("^" k ": ", "")
      print
      exit
    }
  ' "$file"
}

arena_show_blob() {
  local branch=$1
  local path=$2
  git cat-file -e "$branch:$path" 2>/dev/null || return 1
  git show "$branch:$path"
}

arena_ls_mail_ids() {
  local branch=$1
  git ls-tree -r --name-only "$branch" 2>/dev/null | { grep '^msg/' || true; } | sed 's|^msg/||;s|\.md$||' | sort
}

arena_is_read() {
  local branch=$1
  local me=$2
  local id=$3
  git cat-file -e "$branch:.read/$me/$id" 2>/dev/null
}

arena_mark_read() {
  local task=$1
  local me=$2
  local id=$3
  local branch tmp
  branch=$(arena_mail_branch "$task")
  tmp=$(mktemp -t arena-read)
  : >"$tmp"
  arena_commit_file_on_branch "$branch" ".read/$me/$id" "$tmp" "mail: $me read $id" >/dev/null
  rm -f "$tmp"
}

arena_prompt_send() {
  local task=$1
  local from=$2
  local to=$3
  local type=$4
  local bodyfile=$5
  local ts id dest branch

  arena_valid_type "$type" || die "unknown type $type"
  [ -f "$bodyfile" ] || die "missing body file"
  ts=$(arena_now)
  id=$(arena_sanitize "${ts}-${from}-${type}-${to}")
  dest=$(mktemp -t arena-msg)
  arena_write_message_file "$dest" "$id" "$type" "$from" "$to" "$task" "$(arena_iso_now)" "$bodyfile"
  branch=$(arena_mail_branch "$task")
  arena_commit_file_on_branch "$branch" "msg/${id}.md" "$dest" "mail: $from -> $to ($type)" >/dev/null
  rm -f "$dest"
  echo "$id"
}

arena_prompt_next() {
  local task=$1
  local me=$2
  local branch id to from tmp
  branch=$(arena_mail_branch "$task")
  arena_ref_exists "$branch" || return 2

  for id in $(arena_ls_mail_ids "$branch"); do
    tmp=$(mktemp -t arena-next)
    git show "$branch:msg/${id}.md" >"$tmp"
    to=$(arena_field "$tmp" to)
    from=$(arena_field "$tmp" from)
    if [ "$from" = "$me" ]; then
      rm -f "$tmp"
      continue
    fi
    if [ "$to" != "$me" ] && [ "$to" != "all" ]; then
      rm -f "$tmp"
      continue
    fi
    if arena_is_read "$branch" "$me" "$id"; then
      rm -f "$tmp"
      continue
    fi
    cat "$tmp"
    rm -f "$tmp"
    arena_mark_read "$task" "$me" "$id"
    return 0
  done
  return 2
}
