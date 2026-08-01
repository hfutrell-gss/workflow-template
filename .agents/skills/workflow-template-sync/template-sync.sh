#!/usr/bin/env bash
# workflow-template-sync — the composition machinery of a workflow repo.
#
# A workflow repo is assembled from PACKS. One pack is special — the CORE (this
# template): it defines the shapes everything else plugs into, and every workflow repo
# has exactly one, recorded in .template.lock. Every other pack is optional, declared in
# packs.yaml, and provides paths the same way the core does. A repo with no extra packs
# is complete, not degraded.
#
# Usage:
#   template-sync.sh derive [--upstream PATH]   # in a fresh copy/clone of the core:
#                                               # turn it into a derivation
#   template-sync.sh update [<pack>]            # pull the core and every pack forward
#   template-sync.sh add <url-or-path> [--name N] [--reviewed]  # install a pack
#   template-sync.sh scan <url-or-path>         # what would this pack install, and
#                                               # does anything in it look wrong
#   template-sync.sh remove <pack>              # uninstall a pack and its paths
#   template-sync.sh list                       # what is installed, from where, what version
#   template-sync.sh --check                    # report versions; exit 1 if anything is behind
#
# Upstream resolution for `derive`, by precedence: --upstream PATH >
# $WORKFLOW_TEMPLATE_UPSTREAM > this checkout's own 'origin' remote > hardcoded fallback
# $HOME/workbench/workflow-template. Any upstream (core or pack) is a local path or a
# git URL (https://, git@..., ssh://, file://); a URL is fetched into a cached shallow
# clone under ${XDG_CACHE_HOME:-$HOME/.cache}/workflow-template-sync/.
#
# Files:
#   .template.lock  the core: template_version, upstream, derived, pinned
#   packs.yaml      declared packs (derivation-owned, committed)
#   packs.lock      installed packs: version + the exact paths each one owns
#
# Invariants:
#   - one owner per path. A path claimed by two packs is an ERROR, never a silent merge.
#   - a path a pack stops providing is REMOVED, not left behind.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
LOCK="$ROOT/.template.lock"
PACKS="$ROOT/packs.yaml"
PACKS_LOCK="$ROOT/packs.lock"
CORE_NAME="workflow-core"
GIT=/usr/bin/git

command -v yq >/dev/null || { echo "error: yq (mikefarah v4) is required — run /workflow-init first" >&2; exit 1; }

default_upstream() { # default_upstream <root-dir>
  local root="$1" origin
  if [ -n "${WORKFLOW_TEMPLATE_UPSTREAM:-}" ]; then
    printf '%s\n' "$WORKFLOW_TEMPLATE_UPSTREAM"
    return
  fi
  origin="$("$GIT" -C "$root" remote get-url origin 2>/dev/null || true)"
  if [ -n "$origin" ]; then
    echo "derive: no --upstream given and WORKFLOW_TEMPLATE_UPSTREAM unset — inferring upstream from this checkout's 'origin' remote: $origin" >&2
    printf '%s\n' "$origin"
    return
  fi
  printf '%s\n' "$HOME/workbench/workflow-template"
}

lock_get() { # lock_get <key> [file]
  local key="$1" file="${2:-$LOCK}"
  [ -f "$file" ] && yq -r ".$key" "$file" 2>/dev/null | grep -v '^null$' || true
}

# --- remote upstream support -------------------------------------------------
# An upstream is either a local path or a git URL. These helpers resolve either kind to
# a local directory the manifest and its paths are read from — callers never branch on
# the kind beyond this point.

is_url_upstream() {
  case "$1" in
    https://*|http://*|git@*|ssh://*|file://*) return 0 ;;
    *) return 1 ;;
  esac
}

cache_dir_for() { # cache_dir_for <url>
  local url="$1" base sha
  base="${XDG_CACHE_HOME:-$HOME/.cache}/workflow-template-sync"
  if command -v sha1sum >/dev/null; then
    sha="$(printf '%s' "$url" | sha1sum | cut -d' ' -f1)"
  else
    sha="$(printf '%s' "$url" | shasum -a 1 | cut -d' ' -f1)"
  fi
  printf '%s/%s\n' "$base" "$sha"
}

resolve_default_branch() { # resolve_default_branch <cache-dir>
  local cache="$1" ref
  ref="$("$GIT" -C "$cache" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [ -z "$ref" ]; then
    "$GIT" -C "$cache" remote set-head origin -a >/dev/null 2>&1 || true
    ref="$("$GIT" -C "$cache" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  fi
  printf '%s\n' "${ref#origin/}"
}

# Refreshes (cloning if absent, else fetch+hard-reset) the cache checkout for a remote
# upstream. Never half-updates: on failure with no cache present it is a hard error; on
# failure with a cache present it is a loud warning and the stale cache stays as-is.
refresh_remote_cache() { # refresh_remote_cache <url> <cache-dir>
  local url="$1" cache="$2"
  mkdir -p "$(dirname "$cache")"

  if [ ! -d "$cache" ]; then
    echo "workflow-template-sync: cloning remote upstream '$url' into cache ($cache)..."
    if ! "$GIT" clone --depth 1 "$url" "$cache"; then
      rm -rf "$cache"
      echo "error: failed to clone remote upstream '$url' and no cache exists — cannot proceed offline" >&2
      exit 1
    fi
    "$GIT" -C "$cache" remote set-head origin -a >/dev/null 2>&1 || true
    return 0
  fi

  if ! "$GIT" -C "$cache" fetch --depth 1 origin; then
    local last_refresh
    last_refresh="$(date -r "$cache/.git/FETCH_HEAD" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo unknown)"
    echo "WARNING: fetch failed for remote upstream '$url' — proceeding with STALE cache at $cache (last refreshed: $last_refresh)" >&2
    return 0
  fi

  local default_branch
  default_branch="$(resolve_default_branch "$cache")"
  [ -n "$default_branch" ] || { echo "error: could not resolve default branch for remote upstream '$url'" >&2; exit 1; }
  "$GIT" -C "$cache" reset --hard "origin/$default_branch"
}

resolve_upstream_root() { # resolve_upstream_root <upstream-string>
  local upstream="$1"
  if is_url_upstream "$upstream"; then
    local cache
    cache="$(cache_dir_for "$upstream")"
    refresh_remote_cache "$upstream" "$cache" 1>&2
    printf '%s\n' "$cache"
  else
    # A relative path is resolved against the REPO ROOT, never the caller's working
    # directory: `upstream: workspace/pack-code-craft` in a committed packs.yaml must mean the
    # same thing from any cwd, and a lock file that only resolves from one directory is a
    # lock file that breaks the moment a script is invoked by absolute path.
    case "$upstream" in /*) ;; *) upstream="$ROOT/$upstream" ;; esac
    [ -d "$upstream" ] || { echo "error: upstream '$upstream' not found" >&2; exit 1; }
    printf '%s\n' "$upstream"
  fi
}

# --- pack manifests ----------------------------------------------------------
# A pack declares what it provides in `pack.yaml` at its root:
#
#   name: code-craft
#   version: 3
#   provides:
#     - .agents/skills/code-craft-tdd/**
#
# The core declares the same thing in `template-manifest.yaml` (`managed:`), and keeps
# its version in VERSION. Both forms are read here, so nothing below this point branches
# on which kind of pack it holds.

manifest_file() { # manifest_file <pack-root> -> path, or empty
  local root="$1"
  if [ -f "$root/pack.yaml" ]; then printf '%s\n' "$root/pack.yaml"
  elif [ -f "$root/template-manifest.yaml" ]; then printf '%s\n' "$root/template-manifest.yaml"
  fi
}

manifest_paths() { # manifest_paths <manifest-file>
  yq -r '(.provides // .managed // [])[]' "$1" 2>/dev/null | grep -v '^null$' || true
}

pack_version_at() { # pack_version_at <pack-root>
  local root="$1" mf
  if [ -f "$root/VERSION" ]; then tr -d '[:space:]' < "$root/VERSION"; return; fi
  mf="$(manifest_file "$root")"
  [ -n "$mf" ] && yq -r '.version // ""' "$mf" | grep -v '^null$' || true
}

pack_name_at() { # pack_name_at <pack-root>
  local mf; mf="$(manifest_file "$1")"
  [ -n "$mf" ] && yq -r '.name // ""' "$mf" | grep -v '^null$' || true
}

pack_requires_core() { # pack_requires_core <pack-root> -> minimum core version, or empty
  local mf; mf="$(manifest_file "$1")"
  [ -n "$mf" ] && yq -r '.requires_core // ""' "$mf" | grep -v '^null$' || true
}

# Packs do not depend on each other -- but every pack depends on the CORE, which is the
# platform, not a peer. A pack written against the overlay convention or the proxy rule
# half-works against a core that predates them, and half-working is worse than refused:
# nothing reports it.
assert_core_satisfies() { # assert_core_satisfies <pack-name> <pack-root>
  local name="$1" root="$2" need have
  need="$(pack_requires_core "$root")"
  [ -n "$need" ] || return 0
  have="$(lock_get template_version)"
  [ -n "$have" ] || return 0
  if [ "$(printf '%s\n%s\n' "$need" "$have" | sort -n | tail -1)" != "$have" ]; then
    echo "error: pack '$name' requires core version >= $need; this repo is on $have." >&2
    echo "       Run 'template-sync.sh update $CORE_NAME' first." >&2
    exit 1
  fi
}

# --- installed-path bookkeeping ----------------------------------------------
# packs.lock records, per pack, the exact path list installed. That record makes REMOVAL
# possible: a path in the lock but no longer in the pack's manifest is a path the pack
# gave up, and it is deleted rather than left as an orphan.
#
# The core needs no such record. Its manifest is itself a managed path, so a derivation
# always holds the previously-installed copy on disk to compare against.

locked_packs() {
  [ -f "$PACKS_LOCK" ] || return 0
  yq -r '(.packs // [])[].name' "$PACKS_LOCK" 2>/dev/null | grep -v '^null$' || true
}

locked_field() { # locked_field <pack> <field>
  [ -f "$PACKS_LOCK" ] || return 0
  yq -r "(.packs // [])[] | select(.name == \"$1\") | .$2 // \"\"" "$PACKS_LOCK" 2>/dev/null | grep -v '^null$' || true
}

locked_paths() { # locked_paths <pack>
  [ -f "$PACKS_LOCK" ] || return 0
  yq -r "(.packs // [])[] | select(.name == \"$1\") | (.paths // [])[]" "$PACKS_LOCK" 2>/dev/null | grep -v '^null$' || true
}

declared_packs() {
  [ -f "$PACKS" ] || return 0
  yq -r '(.packs // [])[].name' "$PACKS" 2>/dev/null | grep -v '^null$' || true
}

declared_field() { # declared_field <pack> <field>
  [ -f "$PACKS" ] || return 0
  yq -r "(.packs // [])[] | select(.name == \"$1\") | .$2 // \"\"" "$PACKS" 2>/dev/null | grep -v '^null$' || true
}

lock_write_pack() { # lock_write_pack <name> <upstream> <version> <paths-file>
  local name="$1" upstream="$2" version="$3" paths_file="$4" rest entry
  rest="$(mktemp)"; entry="$(mktemp)"
  if [ -f "$PACKS_LOCK" ]; then
    yq -r "del(.packs[] | select(.name == \"$name\"))" "$PACKS_LOCK" > "$rest"
  else
    printf 'packs: []\n' > "$rest"
  fi
  {
    printf 'packs:\n  - name: "%s"\n    upstream: "%s"\n    version: "%s"\n    paths:\n' "$name" "$upstream" "$version"
    while IFS= read -r p; do [ -n "$p" ] && printf '      - "%s"\n' "$p"; done < "$paths_file"
  } > "$entry"
  yq -n "load(\"$rest\") as \$a | load(\"$entry\") as \$b | {\"packs\": ((\$a.packs // []) + \$b.packs)}" > "$PACKS_LOCK"
  rm -f "$rest" "$entry"
}

lock_drop_pack() { # lock_drop_pack <name>
  [ -f "$PACKS_LOCK" ] || return 0
  local tmp; tmp="$(mktemp)"
  yq -r "del(.packs[] | select(.name == \"$1\"))" "$PACKS_LOCK" > "$tmp"
  mv "$tmp" "$PACKS_LOCK"
}

# yq rewrites drop comments, so the explanatory header is re-emitted on every write
# rather than kept in the file and lost. A packs.yaml nobody can read is a packs.yaml
# somebody hand-edits.
packs_header() {
  cat <<'EOF'
# packs.yaml — the packs composed into this workflow repo.
#
# The core (.template.lock) defines the shapes; a pack adds capability on top. Every
# pack here is optional: remove one and this repo still works. What each pack owns comes
# from its own pack.yaml — one owner per path, always.
#
# Edit through /workflow-template-sync (add | remove | update), not by hand.
EOF
}

declare_pack() { # declare_pack <name> <upstream>
  local name="$1" upstream="$2" rest entry body
  [ -f "$PACKS" ] || printf 'packs: []\n' > "$PACKS"
  rest="$(mktemp)"; entry="$(mktemp)"; body="$(mktemp)"
  yq -r "del(.packs[] | select(.name == \"$name\"))" "$PACKS" > "$rest"
  printf 'packs:\n  - name: "%s"\n    upstream: "%s"\n    pinned: false\n' "$name" "$upstream" > "$entry"
  yq -n "load(\"$rest\") as \$a | load(\"$entry\") as \$b | {\"packs\": ((\$a.packs // []) + \$b.packs)}" > "$body"
  { packs_header; cat "$body"; } > "$PACKS"
  rm -f "$rest" "$entry" "$body"
}

undeclare_pack() { # undeclare_pack <name>
  [ -f "$PACKS" ] || return 0
  local tmp; tmp="$(mktemp)"
  yq -r "del(.packs[] | select(.name == \"$1\"))" "$PACKS" > "$tmp"
  { packs_header; cat "$tmp"; } > "$PACKS"
  rm -f "$tmp"
}

# --- install / uninstall -----------------------------------------------------

# Copies every path in a path list from $1 (pack root) to $2 (repo root). A directory
# entry ends in "/**": the destination directory is replaced wholesale, so deletions
# inside it propagate too. Never merged.
copy_paths() { # copy_paths <src> <dst> <paths-file>
  local src="$1" dst="$2" paths_file="$3" path
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if [[ "$path" == *'/**' ]]; then
      local dirpath="${path%/**}"
      [ -d "$src/$dirpath" ] || { echo "error: manifest provides '$path' but '$src/$dirpath' does not exist" >&2; exit 1; }
      mkdir -p "$(dirname "$dst/$dirpath")"
      rm -rf "$dst/$dirpath"
      cp -r "$src/$dirpath" "$dst/$dirpath"
    else
      [ -f "$src/$path" ] || { echo "error: manifest provides '$path' but '$src/$path' does not exist" >&2; exit 1; }
      mkdir -p "$(dirname "$dst/$path")"
      cp "$src/$path" "$dst/$path"
    fi
    echo "  synced $path"
  done < "$paths_file"
}

# Deletes paths a pack no longer provides, then prunes parent directories that the
# deletion left empty — a retired skill must leave no empty shell behind.
remove_paths() { # remove_paths <dst> <paths-file>
  local dst="$1" paths_file="$2" path target parent
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    target="$dst/${path%/**}"
    [ -e "$target" ] || continue
    rm -rf "$target"
    echo "  removed $path"
    parent="$(dirname "$target")"
    while [ "$parent" != "$dst" ] && [ -d "$parent" ]; do
      rmdir "$parent" 2>/dev/null || break
      parent="$(dirname "$parent")"
    done
  done < "$paths_file"
}

# One owner per path. Checks a candidate pack's paths against the core's and against
# every other installed pack's, and refuses before anything is written — a collision
# resolved by copy order is a collision nobody can see.
assert_no_collision() { # assert_no_collision <candidate-name> <candidate-paths-file>
  local name="$1" paths_file="$2" other path clash=0 core_mf
  core_mf="$(manifest_file "$ROOT")"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if [ "$name" != "$CORE_NAME" ] && [ -n "$core_mf" ] \
       && manifest_paths "$core_mf" | grep -qxF "$path"; then
      echo "error: pack '$name' claims '$path', already owned by $CORE_NAME" >&2
      clash=1
    fi
    for other in $(locked_packs); do
      [ "$other" = "$name" ] && continue
      if locked_paths "$other" | grep -qxF "$path"; then
        echo "error: pack '$name' claims '$path', already owned by pack '$other'" >&2
        clash=1
      fi
    done
  done < "$paths_file"
  [ "$clash" -eq 0 ] || { echo "refusing to install: one owner per path" >&2; exit 1; }
}

# --- commands ----------------------------------------------------------------

cmd_derive() {
  local upstream=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --upstream) upstream="$2"; shift 2 ;;
      *) echo "error: unknown derive argument '$1'" >&2; exit 1 ;;
    esac
  done
  [ -n "$upstream" ] || upstream="$(default_upstream "$ROOT")"

  [ -f "$LOCK" ] && { echo "error: $LOCK already exists — this is already a derivation (delete it first to re-derive)" >&2; exit 1; }
  [ -f "$ROOT/VERSION" ] || { echo "error: no VERSION file at $ROOT — this doesn't look like a core checkout" >&2; exit 1; }

  local template_version
  template_version="$(tr -d '[:space:]' < "$ROOT/VERSION")"

  # Strip core-only identity: this workflow's own journal starts empty — any content
  # here at derive time is the core's own example/test material, not this derivation's.
  find "$ROOT/journal" -type f ! -name '.gitkeep' -delete 2>/dev/null || true

  # Orchestration run state is identity too, and it is COMMITTED (unlike workspace/), so
  # a derive-by-clone carries the core's own in-flight runs into the new workflow —
  # task lists and notes for work that has nothing to do with it. Clear it for the same
  # reason as journal/: a session belongs to the repo that performed it. Clear by level
  # (AGENTS.CORE.md "The shapes"): workflows/<workflow>/SKILL.md and its references/ are
  # TIMELESS and must survive derive, same as .agents/skills/ does. Everything else under
  # a workflow is an APPLICATION directory -- its profile, its carried work, its sessions
  # -- and all of that is the core's identity, not the new derivation's.
  for d in "$ROOT"/workflows/*/*/; do
    [ -d "$d" ] || continue
    [ "$(basename "$d")" = "references" ] && continue
    rm -rf "$d"
  done
  rm -rf "$ROOT/.workflow"/*/ 2>/dev/null || true

  # VERSION describes the CORE's own version, not a derivation's — the derivation's
  # relationship to it is tracked entirely in .template.lock instead.
  rm -f "$ROOT/VERSION"

  # The derivation's own ubiquitous language. GLOSSARY.md is managed and holds the
  # system's terms; this file is unmanaged and holds the derivation's. Scaffolded here
  # because an overlay slot nobody knows exists is an overlay slot nobody fills. The
  # asset ships with code-craft-ubiquitous-language, which is a pack, not the core — so a
  # derivation without that pack simply gets no stub.
  if [ ! -e "$ROOT/GLOSSARY.local.md" ] \
     && [ -f "$ROOT/.agents/skills/code-craft-ubiquitous-language/assets/GLOSSARY.local.template.md" ]; then
    cp "$ROOT/.agents/skills/code-craft-ubiquitous-language/assets/GLOSSARY.local.template.md" \
       "$ROOT/GLOSSARY.local.md"
  fi

  {
    echo "template_version: $template_version"
    echo "upstream: $upstream"
    echo "derived: $(date -I)"
    echo "pinned: false"
  } > "$LOCK"

  echo "derived: template_version=$template_version upstream=$upstream (see .template.lock)"
  echo "next: write this workflow's doctrine into AGENTS.md (the skeleton is untouched)"
  echo "next: add the packs this area of work needs — 'template-sync.sh add <url>'"
}

# Updates the core. The removal source is the derivation's OWN copy of the core
# manifest, read before it is overwritten: a path it lists that the new manifest does
# not is a path the core gave up.
update_core() {
  local pinned upstream upstream_root template_version upstream_version derived
  pinned="$(lock_get pinned)"
  upstream="$(lock_get upstream)"
  template_version="$(lock_get template_version)"
  derived="$(lock_get derived)"   # read BEFORE the lock file is rewritten below
  upstream_root="$(resolve_upstream_root "$upstream")"
  [ -f "$upstream_root/VERSION" ] || { echo "error: no VERSION file at upstream root '$upstream_root' (upstream: $upstream)" >&2; exit 1; }
  upstream_version="$(tr -d '[:space:]' < "$upstream_root/VERSION")"

  if [ "$pinned" = "true" ]; then
    echo "$CORE_NAME: pinned — not updating. installed=$template_version, available=$upstream_version"
    return 0
  fi
  if [ "$upstream_version" = "$template_version" ]; then
    echo "$CORE_NAME: up to date ($template_version)"
    return 0
  fi
  if [ "$(printf '%s\n%s\n' "$template_version" "$upstream_version" | sort -n | tail -1)" != "$upstream_version" ]; then
    echo "warning: $CORE_NAME installed ($template_version) is ahead of upstream ($upstream_version) — nothing to do"
    return 0
  fi

  echo "$CORE_NAME: $template_version -> $upstream_version"
  local old new gone local_mf upstream_mf
  old="$(mktemp)"; new="$(mktemp)"; gone="$(mktemp)"
  local_mf="$(manifest_file "$ROOT")"
  upstream_mf="$(manifest_file "$upstream_root")"
  [ -n "$upstream_mf" ] || { echo "error: upstream core has no manifest (pack.yaml or template-manifest.yaml)" >&2; exit 1; }
  if [ -n "$local_mf" ]; then manifest_paths "$local_mf" | sort > "$old"; else : > "$old"; fi
  manifest_paths "$upstream_mf" | sort > "$new"
  comm -23 "$old" "$new" > "$gone"
  remove_paths "$ROOT" "$gone"
  copy_paths "$upstream_root" "$ROOT" "$new"
  rm -f "$old" "$new" "$gone"

  {
    echo "template_version: $upstream_version"
    echo "upstream: $upstream"
    echo "derived: $derived"
    echo "pinned: $pinned"
  } > "$LOCK"
}

update_pack() { # update_pack <name>
  local name="$1" upstream pinned root version installed mf
  upstream="$(declared_field "$name" upstream)"
  [ -n "$upstream" ] || { echo "error: pack '$name' is not declared in packs.yaml" >&2; exit 1; }
  pinned="$(declared_field "$name" pinned)"
  installed="$(locked_field "$name" version)"
  root="$(resolve_upstream_root "$upstream")"
  mf="$(manifest_file "$root")"
  [ -n "$mf" ] || { echo "error: '$upstream' has no pack.yaml — not a pack" >&2; exit 1; }
  version="$(pack_version_at "$root")"
  assert_core_satisfies "$name" "$root"

  if [ "$pinned" = "true" ]; then
    echo "$name: pinned — not updating. installed=${installed:-<none>}, available=$version"
    return 0
  fi
  if [ -n "$installed" ] && [ "$installed" = "$version" ]; then
    echo "$name: up to date ($version)"
    return 0
  fi

  echo "$name: ${installed:-<not installed>} -> $version"
  local old new gone
  old="$(mktemp)"; new="$(mktemp)"; gone="$(mktemp)"
  locked_paths "$name" | sort > "$old"
  manifest_paths "$mf" | sort > "$new"
  assert_no_collision "$name" "$new"
  comm -23 "$old" "$new" > "$gone"
  remove_paths "$ROOT" "$gone"
  copy_paths "$root" "$ROOT" "$new"
  lock_write_pack "$name" "$upstream" "$version" "$new"
  rm -f "$old" "$new" "$gone"
}

cmd_update() {
  [ -f "$LOCK" ] || { echo "error: no $LOCK — this doesn't look like a derivation (run 'derive' first, in a core checkout)" >&2; exit 1; }
  local target="${1:-}" p
  if [ -n "$target" ]; then
    if [ "$target" = "$CORE_NAME" ]; then update_core; else update_pack "$target"; fi
    return 0
  fi
  update_core
  for p in $(declared_packs); do update_pack "$p"; done
  # A pack recorded as installed but no longer declared was dropped from packs.yaml by
  # hand. Surface it; never silently delete files on a plain `update`.
  for p in $(locked_packs); do
    declared_packs | grep -qxF "$p" && continue
    echo "WARNING: pack '$p' is installed (packs.lock) but not declared in packs.yaml — run 'remove $p' to uninstall it" >&2
  done
}

cmd_add() {
  local upstream="" name="" root reviewed=0
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --name) name="$2"; shift 2 ;;
      --reviewed) reviewed=1; shift ;;
      -*) echo "error: unknown add argument '$1'" >&2; exit 1 ;;
      *) upstream="$1"; shift ;;
    esac
  done
  [ -n "$upstream" ] || { echo "usage: template-sync.sh add <url-or-path> [--name N]" >&2; exit 1; }
  [ -f "$LOCK" ] || { echo "error: no $LOCK — packs are added to a derivation, not to the core itself" >&2; exit 1; }

  root="$(resolve_upstream_root "$upstream")"
  [ -f "$root/pack.yaml" ] || { echo "error: '$upstream' has no pack.yaml at its root — not a pack" >&2; exit 1; }
  [ -n "$name" ] || name="$(pack_name_at "$root")"
  [ -n "$name" ] || { echo "error: pack.yaml has no 'name:' and --name was not given" >&2; exit 1; }
  [ "$name" = "$CORE_NAME" ] && { echo "error: '$CORE_NAME' is the core — tracked in .template.lock, not packs.yaml" >&2; exit 1; }
  declared_packs | grep -qxF "$name" && { echo "error: pack '$name' is already declared — use 'update $name'" >&2; exit 1; }

  assert_core_satisfies "$name" "$root"

  # Check the collision BEFORE declaring, and undo the declaration if anything later
  # fails: a refused `add` must leave packs.yaml exactly as it found it, or the next
  # command reads a pack that was never installed.
  local paths; paths="$(mktemp)"
  manifest_paths "$(manifest_file "$root")" | sort > "$paths"
  # Scan BEFORE the collision check: a pack claiming CLAUDE.md collides with the core,
  # but "already owned by workflow-core" is the wrong lesson. The scan says what is
  # actually wrong with the shape of the claim. Installing copies executable scripts and
  # always-loaded doctrine into a repo agents then run inside; --reviewed is how a human
  # takes responsibility for what a heuristic could not decide.
  echo "scanning pack '$name'..."
  if ! bash "$HERE/pack-scan.sh" "$root" "$paths"; then
    if [ "$reviewed" -eq 1 ]; then
      echo "proceeding: --reviewed given. You own this decision." >&2
    else
      rm -f "$paths"
      echo "refusing to install '$name' — inspect the findings above, then re-run with --reviewed." >&2
      exit 1
    fi
  fi

  # Collision is checked after, and is NOT waivable by --reviewed: two owners for one
  # path is broken whoever reviewed it.
  assert_no_collision "$name" "$paths"
  rm -f "$paths"

  declare_pack "$name" "$upstream"
  trap 'undeclare_pack "'"$name"'"; echo "add failed — packs.yaml left unchanged" >&2' ERR EXIT
  update_pack "$name"
  trap - ERR EXIT
  echo "added pack '$name' from $upstream"
}

# Runs the scan against a pack without installing anything. Use it to read a pack before
# deciding, and to re-read an installed one after it changes upstream.
cmd_scan() {
  local upstream="${1:-}" root
  [ -n "$upstream" ] || { echo "usage: template-sync.sh scan <url-or-path>" >&2; exit 1; }
  # An already-declared pack may be named instead of located.
  if declared_packs | grep -qxF "$upstream"; then
    upstream="$(declared_field "$upstream" upstream)"
  fi
  root="$(resolve_upstream_root "$upstream")"
  [ -f "$root/pack.yaml" ] || { echo "error: '$upstream' has no pack.yaml at its root — not a pack" >&2; exit 1; }
  bash "$HERE/pack-scan.sh" "$root"
}

cmd_remove() {
  local name="${1:-}" paths
  [ -n "$name" ] || { echo "usage: template-sync.sh remove <pack>" >&2; exit 1; }
  [ "$name" = "$CORE_NAME" ] && { echo "error: the core cannot be removed — eject instead, by deleting .template.lock" >&2; exit 1; }
  if ! locked_packs | grep -qxF "$name" && ! declared_packs | grep -qxF "$name"; then
    echo "error: no pack '$name' installed or declared" >&2; exit 1
  fi

  paths="$(mktemp)"
  locked_paths "$name" > "$paths"
  remove_paths "$ROOT" "$paths"
  rm -f "$paths"
  lock_drop_pack "$name"
  undeclare_pack "$name"
  echo "removed pack '$name'"

  # An overlay is the repo's answer to a pack, not the pack's property -- so removing the
  # pack never deletes it. Say so, because a silent leftover is indistinguishable from a
  # bug the next time somebody reads the tree.
  local orphan
  for orphan in "$ROOT/.agents/$name"; do
    [ -d "$orphan" ] || continue
    echo "note: ${orphan#"$ROOT"/} still holds this repo's overlays for '$name'. They are yours, so"
    echo "      nothing deleted them. Remove the directory if the pack is gone for good."
  done
}

cmd_list() {
  [ -f "$LOCK" ] || { echo "error: no $LOCK — this doesn't look like a derivation" >&2; exit 1; }
  local p
  printf '%-26s %-9s %s\n' PACK VERSION UPSTREAM
  printf '%-26s %-9s %s\n' "$CORE_NAME (core)" "$(lock_get template_version)" "$(lock_get upstream)"
  for p in $(declared_packs); do
    printf '%-26s %-9s %s\n' "$p" "$(locked_field "$p" version)" "$(declared_field "$p" upstream)"
  done
}

# --check reports installed vs available for the core and every pack. Exit 1 if anything
# is behind — a constraint result, consumed by /workflow-check.
cmd_check() {
  [ -f "$LOCK" ] || { echo "error: no $LOCK — this doesn't look like a derivation" >&2; exit 1; }
  local behind=0 pinned upstream upstream_root template_version upstream_version
  pinned="$(lock_get pinned)"
  upstream="$(lock_get upstream)"
  template_version="$(lock_get template_version)"
  upstream_root="$(resolve_upstream_root "$upstream")"
  [ -f "$upstream_root/VERSION" ] || { echo "error: no VERSION file at upstream root '$upstream_root' (upstream: $upstream)" >&2; exit 1; }
  upstream_version="$(tr -d '[:space:]' < "$upstream_root/VERSION")"
  if [ "$template_version" = "$upstream_version" ]; then
    echo "$CORE_NAME: up to date ($template_version)$( [ "$pinned" = "true" ] && echo " [pinned]" )"
  else
    echo "$CORE_NAME: behind — installed $template_version, available $upstream_version$( [ "$pinned" = "true" ] && echo " [pinned: update only reports]" )"
    behind=1
  fi

  local p p_up p_root p_ver p_inst p_pin
  for p in $(declared_packs); do
    p_up="$(declared_field "$p" upstream)"
    p_pin="$(declared_field "$p" pinned)"
    p_inst="$(locked_field "$p" version)"
    p_root="$(resolve_upstream_root "$p_up")"
    p_ver="$(pack_version_at "$p_root")"
    if [ "$p_inst" = "$p_ver" ]; then
      echo "$p: up to date ($p_ver)$( [ "$p_pin" = "true" ] && echo " [pinned]" )"
    else
      echo "$p: behind — installed ${p_inst:-<none>}, available $p_ver$( [ "$p_pin" = "true" ] && echo " [pinned]" )"
      behind=1
    fi
  done

  [ "$behind" -eq 0 ] || { echo "status: behind (run 'update')"; exit 1; }
  echo "status: up to date"
}

# --audit checks the composition itself, offline: no upstream is contacted and no
# version is compared (that is --check / TEMPLATE-001). Reports on stdout in the
# DRIFT/MISSING form /workflow-check consumes, and always exits 0 — an unmet constraint
# is a result, not a tool failure.
cmd_audit() {
  [ -f "$LOCK" ] || { echo "MISSING PACK-000: no .template.lock — this repo has no core"; return 0; }
  local core_mf p q path seen owners

  # PACK-001 -- one owner per path.
  seen="$(mktemp)"; owners="$(mktemp)"
  core_mf="$(manifest_file "$ROOT")"
  if [ -n "$core_mf" ]; then
    manifest_paths "$core_mf" | while IFS= read -r path; do
      [ -n "$path" ] && printf '%s\t%s\n' "$path" "$CORE_NAME"
    done >> "$owners"
  fi
  for p in $(locked_packs); do
    locked_paths "$p" | while IFS= read -r path; do
      [ -n "$path" ] && printf '%s\t%s\n' "$path" "$p"
    done >> "$owners"
  done
  cut -f1 "$owners" | sort | uniq -d > "$seen"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    echo "DRIFT   PACK-001: '$path' is claimed by more than one pack: $(awk -F'\t' -v p="$path" '$1==p{printf "%s ", $2}' "$owners")"
  done < "$seen"
  rm -f "$seen" "$owners"

  # PACK-002 -- every path a pack claims is actually on disk.
  for p in $(locked_packs); do
    while IFS= read -r path; do
      [ -n "$path" ] || continue
      [ -e "$ROOT/${path%/**}" ] || echo "MISSING PACK-002: pack '$p' claims '$path' but it is not in this repo — run 'update $p'"
    done < <(locked_paths "$p")
  done

  # PACK-004 -- every installed pack's requires_core is still satisfied. Offline: the
  # requirement is read from the pack's manifest as recorded, not from upstream. A core
  # pinned or rolled back after a pack was installed breaks this silently otherwise.
  local need have; have="$(lock_get template_version)"
  for p in $(declared_packs); do
    local p_up p_root
    p_up="$(declared_field "$p" upstream)"
    [ -n "$p_up" ] || continue
    case "$p_up" in /*) p_root="$p_up" ;; *) p_root="$ROOT/$p_up" ;; esac
    [ -d "$p_root" ] || continue          # remote-only: --check contacts it, --audit does not
    need="$(pack_requires_core "$p_root")"
    [ -n "$need" ] && [ -n "$have" ] || continue
    [ "$(printf '%s\n%s\n' "$need" "$have" | sort -n | tail -1)" = "$have" ] \
      || echo "DRIFT   PACK-004: pack '$p' requires core >= $need but this repo is on $have — update the core, or pin the pack"
  done

  # PACK-003 -- declaration and installation agree.
  for p in $(locked_packs); do
    declared_packs | grep -qxF "$p" \
      || echo "DRIFT   PACK-003: pack '$p' is installed (packs.lock) but not declared in packs.yaml — run 'remove $p' or re-declare it"
  done
  for q in $(declared_packs); do
    locked_packs | grep -qxF "$q" \
      || echo "MISSING PACK-003: pack '$q' is declared in packs.yaml but never installed — run 'update $q'"
  done
}

MODE="${1:---check}"; [ "$#" -gt 0 ] && shift || true
case "$MODE" in
  derive)   cmd_derive "$@" ;;
  update)   cmd_update "$@" ;;
  add)      cmd_add "$@" ;;
  scan)     cmd_scan "$@" ;;
  remove)   cmd_remove "$@" ;;
  list)     cmd_list "$@" ;;
  --audit)  cmd_audit "$@" ;;
  --check)  cmd_check "$@" ;;
  *) echo "usage: template-sync.sh derive [--upstream PATH] | update [<pack>] | add <url> [--name N] [--reviewed] | scan <url> | remove <pack> | list | --audit | --check" >&2; exit 1 ;;
esac
