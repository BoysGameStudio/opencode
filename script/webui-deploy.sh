#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
webroot="${OPENCODE_WEBUI_WEBROOT:-/opt/homebrew/var/www/opencode}"

if [[ "${1:-}" == "--help" ]]; then
  printf '%s\n' \
    'Usage: script/webui-deploy.sh' \
    'Build packages/app and publish static files without reloading Nginx.' \
    'Requires packages/app/.env.local and an existing authenticated Nginx site.' \
    'OPENCODE_WEBUI_WEBROOT overrides /opt/homebrew/var/www/opencode.' \
    'Old assets are retained for open browsers; entrypoints are published last.'
  exit 0
fi

if [[ $# -ne 0 ]]; then
  printf 'Unknown argument; use --help.\n' >&2
  exit 1
fi

for command in bun rsync; do
  command -v "$command" >/dev/null || { printf 'Missing command: %s\n' "$command" >&2; exit 1; }
done

if [[ ! -f "$root/packages/app/.env.local" ]]; then
  printf 'Missing packages/app/.env.local; configure preset servers before deploying.\n' >&2
  exit 1
fi

# Publishing must never target the filesystem root or the source checkout.
if [[ "$webroot" != /* || "$webroot" == *'/../'* || "$webroot" == */.. ]]; then
  printf 'Webroot must be an absolute path without .. components.\n' >&2
  exit 1
fi
mkdir -p "$webroot"
webroot="$(cd "$webroot" && pwd -P)"
if [[ "$webroot" == / || "$root/" == "$webroot/"* || "$webroot/" == "$root/"* ]]; then
  printf 'Webroot must be outside the source checkout and cannot be /.\n' >&2
  exit 1
fi

(cd "$root/packages/app" && OPENCODE_CHANNEL=prod VITE_OPENCODE_SERVER_MODE=none bun run build)
test -s "$root/packages/app/dist/index.html"
test -s "$root/packages/app/dist/sw.js"
rsync -a --exclude=/index.html --exclude=/sw.js "$root/packages/app/dist/" "$webroot/"
rsync -a "$root/packages/app/dist/index.html" "$webroot/index.html"
rsync -a "$root/packages/app/dist/sw.js" "$webroot/sw.js"
printf 'WebUI deployed to %s\n' "$webroot"
