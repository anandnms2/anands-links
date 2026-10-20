#!/usr/bin/env bash
# Sync Anands Links with the latest STABLE Linkwarden release (vX.Y.Z tags only)
# without losing the Anands customizations.
#
# How: 3-way tree merge  (base = upstream commit recorded in UPSTREAM_BASE,
#                         ours = HEAD, theirs = new upstream stable tag),
# then branding-owned files are restored and generated files are re-derived.
# Never pushes unless every check passes.
#
# Env: NO_PUSH=1 (dry run), TARGET_TAG=vX.Y.Z (force a tag), UPSTREAM_URL
# Exit: 0 updated/up-to-date | 2 dirty tree | 3 no stable tag | 4 diverged
#       5 merge conflicts | 6 branding check failed | 7 push failed
set -euo pipefail
UPSTREAM_URL=${UPSTREAM_URL:-https://github.com/linkwarden/linkwarden.git}
cd "$(git rev-parse --show-toplevel)"

# Paths that belong to Anands and are never taken from upstream.
PROTECTED=(docker-compose.yml .env.anands.example ANANDS.md scripts .github UPSTREAM_BASE UPSTREAM_VERSION
  apps/web/public/android-chrome-192x192.png apps/web/public/android-chrome-512x512.png
  apps/web/public/apple-touch-icon.png apps/web/public/favicon-16x16.png apps/web/public/favicon-32x32.png
  apps/web/public/favicon.ico apps/web/public/icon-small-150x150.png apps/web/public/icon.png
  apps/web/public/linkwarden_dark.png apps/web/public/linkwarden_light.png apps/web/public/logo_maskable.png
  apps/web/public/brand apps/web/pages/sso.tsx)

[ -z "$(git status --porcelain)" ] || { echo "RESULT=dirty-tree"; exit 2; }
BASE=$(tr -d '[:space:]' < UPSTREAM_BASE)

TAG=${TARGET_TAG:-$(git ls-remote --tags "$UPSTREAM_URL" 'v*' | awk '{print $2}' | sed 's#refs/tags/##' \
  | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)}
[ -n "$TAG" ] || { echo "RESULT=no-stable-tag"; exit 3; }
TAG_SHA=$(git ls-remote "$UPSTREAM_URL" "refs/tags/$TAG^{}" "refs/tags/$TAG" | awk '{print $1}' | tail -1)
echo "latest stable: $TAG ($TAG_SHA) | recorded base: $BASE"

# Ancestry check on a throwaway blobless clone (history only, small).
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
git clone --quiet --bare --filter=blob:none "$UPSTREAM_URL" "$TMP/up.git"
if [ "$BASE" = "$TAG_SHA" ] || git -C "$TMP/up.git" merge-base --is-ancestor "$TAG_SHA" "$BASE"; then
  echo "RESULT=up-to-date (base already contains $TAG)"; exit 0
fi
git -C "$TMP/up.git" merge-base --is-ancestor "$BASE" "$TAG_SHA" || { echo "RESULT=diverged"; exit 4; }
echo "update available: $(git -C "$TMP/up.git" rev-list --count "$BASE..$TAG_SHA") upstream commits"

git remote get-url upstream >/dev/null 2>&1 || git remote add upstream "$UPSTREAM_URL"
git fetch --quiet --no-tags --depth=1 upstream "$BASE"
git fetch --quiet --no-tags --depth=1 upstream "$TAG_SHA"

undo() { git reset -q --hard HEAD; git clean -qfd; }

# 3-way merge of trees: base / ours / theirs.
git read-tree -m -u --aggressive "$BASE" HEAD "$TAG_SHA"
git merge-index -o git-merge-one-file -a >/dev/null 2>&1 || true

# Branding-owned files always stay ours.
for p in "${PROTECTED[@]}"; do
  git rm -rfq --cached --ignore-unmatch -- "$p"   # drop any merge stages for it
  rm -rf -- "$p"
  if git cat-file -e "HEAD:$p" 2>/dev/null; then git checkout -q HEAD -- "$p"; fi
done

# Generated customizations: re-derive from the new upstream files.
for f in $(git ls-tree -r --name-only "$TAG_SHA" apps/web/public/locales | grep 'common.json$'); do
  mkdir -p "$(dirname "$f")"
  git show "$TAG_SHA:$f" | sed 's/Linkwarden/Anands Links/g' > "$f"; git add "$f"
done
for f in $(git ls-tree -r --name-only "$TAG_SHA" apps/web/templates | grep '\.html$'); do
  git show "$TAG_SHA:$f" | sed -E 's#https://raw.githubusercontent.com/linkwarden/linkwarden/[^"]*logo_small.png#https://links.anands.xyz/icon-small-150x150.png#; s/bgcolor="#00335a"/bgcolor="#f68712"/; s/#105f9c/#f68712/; s/Linkwarden/Anands Links/g' > "$f"
  git add "$f"
done

CONFLICTS=$(git ls-files -u | cut -f2 | sort -u || true)
if [ -n "$CONFLICTS" ]; then
  echo "RESULT=conflicts"; echo "$CONFLICTS"; undo; exit 5
fi

echo "$TAG_SHA" > UPSTREAM_BASE
echo "$TAG" > UPSTREAM_VERSION
git add -A
if ! bash scripts/verify-branding.sh; then echo "RESULT=branding-check-failed"; undo; exit 6; fi

git -c user.name="Anands Sync" -c user.email="anandnms100@gmail.com" commit -q -m "Sync upstream Linkwarden $TAG (stable)"
echo "committed: $(git rev-parse --short HEAD)"
if [ "${NO_PUSH:-0}" = "1" ]; then echo "RESULT=updated-local-only to $TAG"; exit 0; fi
git push origin HEAD:main || { echo "RESULT=push-failed"; exit 7; }
echo "RESULT=updated to $TAG"
