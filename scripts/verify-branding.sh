#!/usr/bin/env bash
# Fails if any Anands customization is missing. Run after every upstream sync.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
W=apps/web; fail=0
chk() { if ! eval "$2"; then echo "BRANDING MISSING: $1"; fail=1; fi; }
chk "tailwind dark primary"    "grep -q 'primary: \"#f68712\"' $W/tailwind.config.js"
chk "tailwind light primary"   "grep -q 'primary: \"#c25a0a\"' $W/tailwind.config.js"
chk "tailwind config syntax"   "node --check $W/tailwind.config.js"
chk "orange collection color"  "grep -q '#f68712' $W/pages/dashboard.tsx"
chk "page title"               "grep -q '<title>Anands Links</title>' $W/pages/_app.tsx"
chk "sidebar brand header"     "grep -q 'Anands <span' $W/components/SidebarShell.tsx"
chk "card gradient placeholder" "grep -q 'linear-gradient(135deg, #f68712' $W/components/LinkViews/LinkComponents/LinkCard.tsx"
chk "card tag pills"           "grep -q 'bg-primary/15 text-primary' $W/components/LinkViews/LinkComponents/LinkCard.tsx"
chk "/sso route"               "test -f $W/pages/sso.tsx && grep -q 'signIn(\"authentik\"' $W/pages/sso.tsx"
chk "authentik provider"       "grep -q 'id: \"authentik\"' $W/lib/api/authProviders.ts"
chk "manifest name"            "grep -q 'Anands Links' $W/public/site.webmanifest"
chk "no Linkwarden in locales" "! grep -rq 'Linkwarden' $W/public/locales"
chk "locales are valid JSON"   "python3 -c \"import glob,json;[json.load(open(f,encoding='utf8')) for f in glob.glob('$W/public/locales/*/common.json')]\""
chk "icon files unchanged"     "(cd $W/public && sha256sum -c --quiet ../../../scripts/branding.sha256)"
chk "compose healthchecks"     "python3 -c \"import yaml;d=yaml.safe_load(open('docker-compose.yml'));assert all('healthcheck' in v for v in d['services'].values())\""
[ $fail -eq 0 ] && echo "branding OK"
exit $fail
