# Local WebUI Deployment

Run from the repository root, or use the script's absolute path from another directory:

```sh
./script/webui-deploy.sh
```

The script uses the existing Bun and rsync installations and `packages/app/.env.local`.
It builds the prod channel with `VITE_OPENCODE_SERVER_MODE=none` to enable preset
backends, then publishes `dist/` to `/opt/homebrew/var/www/opencode`. Assets are
published first, followed by `index.html` and `sw.js`.
Old hashed assets are retained for open browsers. Nginx is neither modified nor
reloaded. The script stops on any failure. Publishing is not atomic and does not
roll back automatically; resolve the failure and run the script again.

## Prerequisites

- Project dependencies are already installed.
- `packages/app/.env.local` defines `VITE_OPENCODE_PRESET_SERVERS`. Git ignores this
  file. Do not commit it or print its passwords. The build loads it automatically;
  do not source it in the shell.
- The existing Nginx site provides HTTPS, Basic Auth, and SPA fallback, with its
  root set to the deployment directory above. Preset passwords are embedded in
  the frontend build: **protect the entire site, including JavaScript assets**.
- The existing OpenCode backends are running and allow the WebUI origin through CORS.

The script does not install dependencies, create the site, change credentials or
CORS, reload Nginx, or start or restart OpenCode backends.
The existing site URL is `https://opencode.boysgame.fun:19860`. If a browser connects
directly to `http://127.0.0.1:4096`, that address refers to the browser's machine,
not the machine hosting the static site.

To use a different deployment directory:

```sh
OPENCODE_WEBUI_WEBROOT=/absolute/dedicated/webroot ./script/webui-deploy.sh
```

**The destination must be a dedicated static-site directory.** Publishing
overwrites files with matching names but retains old assets so open pages can
still load their build's lazy chunks. Update the Nginx root separately if you
change the deployment directory.

After publishing, verify that unauthenticated requests return 401 and the site
loads after authentication. In a browser, verify preset backend connections,
streaming output, attachment uploads, and PTY terminals. Script success proves
only that the build and file synchronization completed, not that end-to-end
verification passed. The Service Worker does not forcibly take over old pages.
Once the new version has downloaded, close all tabs and standalone PWA windows
for the site, then reopen it to activate the new version.
