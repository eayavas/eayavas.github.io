#!/usr/bin/env bash
set -u

tmp_list=$(mktemp)
tmp_idx=$(mktemp)
trap 'rm -f "$tmp_list" "$tmp_idx"' EXIT

git -c core.quotepath=false ls-files | grep -E '~$' | while IFS= read -r f; do
  git update-index --force-remove -- "$f"
done
find . -name '*~' -not -path './.git/*' -delete
grep -qxF '*~' .gitignore 2>/dev/null || echo '*~' >> .gitignore

git -c core.quotepath=false ls-files -s > "$tmp_idx"
cut -f2- "$tmp_idx" > "$tmp_list"

while IFS= read -r f; do
  ext="${f##*.}"
  [ "$ext" = "$f" ] && continue
  lext=$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')
  case "$lext" in jpg|jpeg) ;; *) continue ;; esac

  target="${f%.*}.jpg"
  [ "$f" = "$target" ] && continue

  info=$(awk -F'\t' -v p="$f" '$2==p {print $1; exit}' "$tmp_idx")
  mode=$(echo "$info" | cut -d' ' -f1)
  sha=$(echo "$info" | cut -d' ' -f2)

  if grep -qxF -- "$target" "$tmp_list"; then
    tinfo=$(awk -F'\t' -v p="$target" '$2==p {print $1; exit}' "$tmp_idx")
    tsha=$(echo "$tinfo" | cut -d' ' -f2)
    if [ "$sha" != "$tsha" ]; then
      echo "CONFLICT, skipped: $f <-> $target"
      continue
    fi
    git update-index --force-remove -- "$f"
  else
    git update-index --add --cacheinfo "$mode,$sha,$target"
    git update-index --force-remove -- "$f"
  fi

  if [ -e "$f" ]; then
    mv -- "$f" "$f.casefix" && mv -- "$f.casefix" "$target"
  fi
done < "$tmp_list"
