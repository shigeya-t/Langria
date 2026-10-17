#!/bin/sh
# Builds the GitHub Pages site in _site/: the project page and privacy policy
# from docs/ (with the favicons and screenshots they use), plus the web app under app/ (only the files it loads, in the same
# layout, with lib/version.js written for the current commit).
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"

out="$root/_site"
rm -rf "$out"
mkdir -p "$out"
cp -R docs/. "$out/"
# The favicons and screenshots the pages use are copied from their sources
# instead of being kept twice in docs/.
cp extension/icons/icon.svg "$out/favicon.svg"
cp extension/icons/icon-32.png "$out/favicon-32.png"
mkdir -p "$out/images"
for locale in en ja; do
  for shot in 2-selection 3-layout; do cp "store/images/$locale-$shot.png" "$out/images/"; done
done
cp assets/langria-screenshot.png "$out/images/en-web-app.png"
cp assets/langria-screenshot-ja.png "$out/images/ja-web-app.png"

app="$out/app"
mkdir -p "$app/extension/lib" "$app/extension/icons"
cp styles.css app.js "$app/"
# Show the demo notice, which stays hidden when the app is served from the repository.
sed 's/<div class="demo-notice" id="demoNotice" hidden>/<div class="demo-notice" id="demoNotice">/' index.html > "$app/index.html"
grep -q '<div class="demo-notice" id="demoNotice">' "$app/index.html" || { echo "build-pages: demo notice not found in index.html" >&2; exit 1; }
cp extension/lib/i18n.js extension/lib/vault.js extension/lib/languages.js "$app/extension/lib/"
cp extension/icons/icon.svg "$app/extension/icons/"
printf "globalThis.LANGRIA_COMMIT = '%s';\n" "$(git rev-parse --short HEAD)" > "$app/extension/lib/version.js"
find "$out" \( -name '.DS_Store' -o -name '*~' \) -delete
echo "$out"
