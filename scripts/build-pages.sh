#!/bin/sh
# Builds the GitHub Pages site in _site/: the project page and privacy policy
# from docs/, plus the web app under app/ (only the files it loads, in the same
# layout, with lib/version.js written for the current commit).
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"

out="$root/_site"
rm -rf "$out"
mkdir -p "$out"
cp -R docs/. "$out/"

app="$out/app"
mkdir -p "$app/extension/lib" "$app/extension/icons"
cp styles.css app.js "$app/"
# Show the demo notice, which stays hidden when the app is served from the repository.
sed 's/<p class="demo-notice" \(.*\) hidden>/<p class="demo-notice" \1>/' index.html > "$app/index.html"
grep -q 'class="demo-notice" data-i18n-html="web.demoNotice">' "$app/index.html" || { echo "build-pages: demo notice not found in index.html" >&2; exit 1; }
cp extension/lib/i18n.js extension/lib/vault.js extension/lib/languages.js "$app/extension/lib/"
cp extension/icons/icon.svg "$app/extension/icons/"
printf "globalThis.LANGRIA_COMMIT = '%s';\n" "$(git rev-parse --short HEAD)" > "$app/extension/lib/version.js"
find "$out" \( -name '.DS_Store' -o -name '*~' \) -delete
echo "$out"
