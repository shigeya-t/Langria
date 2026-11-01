#!/bin/bash
# Takes the App Store screenshots on the simulators: iPhone 6.3", iPhone Duo,
# iPad 13" and Apple Watch, in English and Japanese. Japanese shots translate English into
# Japanese; English shots the reverse.
#
#   store/ios/capture.sh [--build] [--lang en|ja] [--device iphone|duo|duo-open|ipad|watch]
#
# The debug build's screenshot mode (ios/Langria/Screenshots.swift) does the
# work: no ads, a stand-in API key, and the text and its translation (written
# below; Gemini is the service shown) given as launch arguments, so no API key
# or typing is needed. The photo shot reads a notice rendered here, with the
# app's own text recognition.
# Needs Xcode, XcodeGen and node. --build makes the debug build first
# (ios/build/shots); without it the last one is used.
# Simulators by name: IPHONE, DUO, IPAD and WATCH override the defaults below.
# Images go to store/ios/images/.
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
out="$root/store/ios/images"
app="$root/ios/build/shots/Build/Products/Debug-iphonesimulator/Langria.app"
iphone=${IPHONE:-iPhone 18 Pro}
duo=${DUO:-iPhone Duo}
ipad=${IPAD:-iPad Pro 13-inch (M5)}
watch=${WATCH:-Apple Watch Ultra 4 (49mm)}

build=false langs=(en ja) devices=(iphone duo ipad watch)
while (($#)); do
  case $1 in
    --build) build=true ;;
    --lang) shift; [[ "${1:-}" == en || "${1:-}" == ja ]] || { echo "--lang takes en or ja" >&2; exit 1; }; langs=("$1") ;;
    --device) shift; [[ "${1:-}" =~ ^(iphone|duo|duo-open|ipad|watch)$ ]] || { echo "--device takes iphone, duo, duo-open, ipad or watch" >&2; exit 1; }; devices=("$1") ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done
if $build; then
  (cd "$root/ios" && xcodegen generate --quiet &&
    xcodebuild -quiet -project Langria.xcodeproj -scheme Langria -configuration Debug \
      -destination 'generic/platform=iOS Simulator' -derivedDataPath build/shots build)
fi
[[ -d "$app" ]] || { echo "No debug build at $app (run with --build)" >&2; exit 1; }
bundle=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app/Info.plist")
mkdir -p "$out"
work=$(mktemp -d)

# The text to translate and its translation, by UI language.
source_en='おはようございます。京都行きの電車は3番線から9時15分に発車します。切符はどこで買えますか？指定席はまだ空いていますか？'
translation_en='Good morning. The train to Kyoto leaves from platform 3 at 9:15. Where can I buy a ticket? Are there any reserved seats left?'
source_ja='Good morning! The train to Kyoto leaves from platform 3 at 9:15. Could you tell me where I can buy a ticket, and whether there are any reserved seats left?'
translation_ja='おはようございます！京都行きの電車は3番線から9時15分に発車します。切符はどこで買えるか、指定席がまだ残っているか教えていただけますか？'
# The notice in the photo (a line per paragraph, as wrapped lines may not join cleanly) and its translation.
notice_en=$'お知らせ\n\n本日は設備点検のため、17時で閉館いたします。\n\n明日は通常どおり9時から開館します。'
notice_translation_en=$'Notice\nToday we will close at 5 p.m. for an equipment inspection.\nTomorrow we will open at 9 a.m. as usual.'
notice_ja=$'NOTICE\n\nThe museum will close at 5 p.m. today for maintenance.\n\nWe will open as usual at 9 a.m. tomorrow.'
notice_translation_ja=$'お知らせ\n本日はメンテナンスのため、17時に閉館します。\n明日は通常どおり9時に開館します。'
# The watch's text, short enough for the translation to fit on the first screen.
watch_source_en='京都行きは何番線ですか？'
watch_translation_en='Which platform for Kyoto?'
watch_source_ja='Which platform for Kyoto?'
watch_translation_ja='京都行きは何番線ですか？'

# Renders the notice as a photo of a printed sheet on a table: $1 the text, $2 the PNG.
render_notice() {
  cat > "$work/notice.swift" <<'EOF'
import AppKit
let lines = CommandLine.arguments[1].components(separatedBy: "\n")
let size = CGSize(width: 1400, height: 900)
let image = NSImage(size: size, flipped: true) { _ in
  NSColor(red: 0.55, green: 0.42, blue: 0.3, alpha: 1).setFill()
  NSRect(origin: .zero, size: size).fill()
  let sheet = NSRect(x: 70, y: 90, width: 1260, height: 720)
  let shadow = NSShadow()
  shadow.shadowBlurRadius = 24
  shadow.shadowOffset = NSSize(width: 0, height: -8)
  shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
  NSGraphicsContext.saveGraphicsState()
  shadow.set()
  NSColor(red: 0.98, green: 0.97, blue: 0.93, alpha: 1).setFill()
  sheet.fill()
  NSGraphicsContext.restoreGraphicsState()
  var y: CGFloat = 200
  for (index, line) in lines.enumerated() {
    if line.isEmpty { y += 60; continue }
    let font = index == 0 ? NSFont.boldSystemFont(ofSize: 72) : NSFont.systemFont(ofSize: 44)
    let text = NSAttributedString(string: line, attributes: [.font: font, .foregroundColor: NSColor(white: 0.12, alpha: 1)])
    text.draw(at: CGPoint(x: (size.width - text.size().width) / 2, y: y))
    y += text.size().height + 14
  }
  return true
}
let bitmap = NSBitmapImageRep(cgImage: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
try! bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
EOF
  swift "$work/notice.swift" "$1" "$2"
}

# What the iPhone sends the watch (WatchSettings.swift), from i18n.js and languages.js: $1 the UI language, $2 the target.
watch_settings() {
  node -e '
    globalThis.navigator = { language: "en" };
    require(process.argv[1]);
    require(process.argv[2]);
    const i18n = globalThis.LangriaI18n, targets = globalThis.LangriaLanguages.targets;
    const language = i18n.setLanguage(process.argv[3]);
    const names = Object.keys(targets);
    console.log(JSON.stringify({
      enabled: true, provider: "gemini", models: {}, mode: "natural", target: process.argv[4],
      targets: names,
      labels: Object.fromEntries(names.map((name) => [name, i18n.languageLabel(name)])),
      locales: Object.fromEntries(names.map((name) => [name, targets[name].locale])),
      messages: Object.fromEntries(Object.keys(i18n.messages.en).map((key) => [key, i18n.t(key)])),
      language
    }));
  ' "$root/extension/lib/i18n.js" "$root/extension/lib/languages.js" "$1" "$2"
}

# Boots a simulator by name and prints its UDID.
boot() {
  local udid
  udid=$(xcrun simctl list devices available -j | node -e '
    const devices = Object.values(JSON.parse(require("fs").readFileSync(0, "utf8")).devices).flat();
    const device = devices.find((d) => d.name === process.argv[1] && d.state === "Booted") ?? devices.find((d) => d.name === process.argv[1]);
    if (device) console.log(device.udid);
  ' "$1")
  [[ -n "$udid" ]] || { echo "No simulator named \"$1\" (Xcode → Window → Devices and Simulators)" >&2; exit 1; }
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" >/dev/null
  echo "$udid"
}

# The simulators used, as UDID=appearance before the run, and those with their status bar overridden.
booted=() bars=()
restore() {
  for udid in ${bars[@]+"${bars[@]}"}; do xcrun simctl status_bar "$udid" clear 2>/dev/null || true; done
  for entry in ${booted[@]+"${booted[@]}"}; do
    xcrun simctl ui "${entry%%=*}" appearance "${entry#*=}" 2>/dev/null || true
  done
  rm -rf "$work"
}
trap restore EXIT

# Installs the app afresh on a simulator and tidies its status bar.
prepare() {
  local udid=$1 path=$2 id=$3
  booted+=("$udid=$(xcrun simctl ui "$udid" appearance 2>/dev/null || echo light)")
  # On watchOS the override never returns, so the watch keeps its own clock.
  if [[ $id != *.watchkitapp ]]; then
    bars+=("$udid")
    xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 \
      --cellularMode active --cellularBars 4 --wifiBars 3 --dataNetwork wifi 2>/dev/null || true
  fi
  xcrun simctl uninstall "$udid" "$id" 2>/dev/null || true
  xcrun simctl install "$udid" "$path"
}

# Launches the app in the screenshot mode: $1 the UDID, $2 the bundle ID, $3 the UI language, $4 the theme, then more arguments.
launch() {
  local udid=$1 id=$2 ui=$3 theme=$4
  shift 4
  local region=US
  [[ $ui == ja ]] && region=JP
  ready="$(xcrun simctl get_app_container "$udid" "$id" data)/tmp/langria-ready"
  rm -f "$ready"
  xcrun simctl ui "$udid" appearance "$theme" 2>/dev/null || true
  xcrun simctl launch --terminate-running-process "$udid" "$id" \
    -AppleLanguages "($ui)" -AppleLocale "${ui}_$region" \
    -langria-screenshots YES \
    -langria-ui-language "$ui" -langria-theme "$theme" \
    -langria-provider gemini -langria-mode natural "$@" >/dev/null
}

# Waits for the translation or the settings on screen (the app's marker file, see launch), up to 60 s
# (the first launch on a freshly booted simulator can take over 30 s).
wait_ready() {
  for _ in $(seq 120); do
    [[ -f "$ready" ]] && return
    sleep 0.5
  done
  echo "Timed out waiting for the app" >&2; exit 1
}

# The iPhone Duo has two displays: duo takes the outer one (folded), duo-open the inner one. Nothing here
# can unfold the simulator, so duo-open is left out of the defaults and needs it unfolded by hand first.
display=() shots=()
shot() {
  sleep "$2"
  xcrun simctl io "$1" screenshot --type png ${display[@]+"${display[@]}"} "$out/$3.png" >/dev/null 2>&1
  shots+=("$out/$3.png")
  echo "Wrote store/ios/images/$3.png"
}

# Drops the alpha channel the simulator's PNGs have, which App Store Connect does not accept: the PNGs given.
flatten() {
  cat > "$work/flatten.swift" <<'EOF'
import AppKit
for path in CommandLine.arguments.dropFirst() {
  let url = URL(fileURLWithPath: path)
  let image = NSBitmapImageRep(data: try! Data(contentsOf: url))!.cgImage!
  let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
    space: image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
  context.setFillColor(.black)
  context.fill(CGRect(x: 0, y: 0, width: image.width, height: image.height))
  context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
  try! NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!.write(to: url)
}
EOF
  swift "$work/flatten.swift" "$@"
}

for device in "${devices[@]}"; do
  if [[ $device == watch ]]; then
    udid=$(boot "$watch")
    prepare "$udid" "$app/Watch/Langria.app" "$bundle.watchkitapp"
    for ui in "${langs[@]}"; do
      if [[ $ui == ja ]]; then target=Japanese; else target=English; fi
      text=watch_source_$ui translation=watch_translation_$ui
      launch "$udid" "$bundle.watchkitapp" $ui light \
        -langria-screenshot-source "${!text}" -langria-screenshot-translation "${!translation}" \
        -langria-screenshot-watch-settings "$(watch_settings $ui $target | base64)"
      wait_ready
      shot "$udid" 1 "$ui-watch-1-translate"
    done
    continue
  fi
  case $device in ipad) udid=$(boot "$ipad") ;; duo|duo-open) udid=$(boot "$duo") ;; *) udid=$(boot "$iphone") ;; esac
  display=()
  [[ $device == duo ]] && display=(--display=primary)
  [[ $device == duo-open ]] && display=(--display=primary-1)
  prepare "$udid" "$app" "$bundle"
  photo="$(xcrun simctl get_app_container "$udid" "$bundle" data)/tmp/notice.png"
  for ui in "${langs[@]}"; do
    if [[ $ui == ja ]]; then target=Japanese; else target=English; fi
    text=source_$ui translation=translation_$ui notice=notice_$ui notice_translation=notice_translation_$ui
    render_notice "${!notice}" "$photo"
    launch "$udid" "$bundle" $ui light -langria-target $target \
      -langria-screenshot-source "${!text}" -langria-screenshot-translation "${!translation}"
    wait_ready
    shot "$udid" 1 "$ui-$device-1-translate"
    launch "$udid" "$bundle" $ui light -langria-target $target \
      -langria-screenshot-image "$photo" -langria-screenshot-translation "${!notice_translation}"
    wait_ready
    shot "$udid" 1 "$ui-$device-2-photo"
    launch "$udid" "$bundle" $ui dark -langria-target $target \
      -langria-screenshot-source "${!text}" -langria-screenshot-translation "${!translation}"
    wait_ready
    shot "$udid" 1 "$ui-$device-3-dark"
    # The translation stays behind the sheet (on the iPad, around it).
    launch "$udid" "$bundle" $ui light -langria-target $target -langria-screenshot-screen settings \
      -langria-screenshot-source "${!text}" -langria-screenshot-translation "${!translation}"
    wait_ready
    # Ready once the sheet appears, before it has slid up and the translation (700 ms later) is in.
    shot "$udid" 2 "$ui-$device-4-settings"
  done
  xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
done
flatten "${shots[@]}"
