#!/bin/bash
# Takes the Google Play screenshots on an emulator: the translation screen and
# the settings screen, in English and Japanese, light and dark.
# Japanese shots translate an English sample into Japanese; English shots the reverse.
# With --video it records the first-run flow instead (the key typed in the
# settings, then text entered and translated), in English and Japanese, each
# translating the other language. adb can only type ASCII, so the Japanese
# text in the English video goes in at once, as if pasted.
#
#   GEMINI_API_KEY=... store/android/capture.sh [--build] [--video] [--lang en|ja]
#
# Each UI language makes its own files ({en,ja}-…); --lang takes just one.
# Needs adb, a running emulator (or ANDROID_SERIAL) and the debug build
# (android/app/build/outputs/apk/debug/app-debug.apk; --build makes it first).
# The key is asked for when GEMINI_API_KEY is not set. The app's data on the
# device is cleared; the debug build hides the test ads while
# `langria-screenshots` is set. Images go to store/android/images/.
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
out="$root/store/android/images"
apk="$root/android/app/build/outputs/apk/debug/app-debug.apk"
pkg=net.langria.app

build=false video=false langs=(en ja)
while (($#)); do
  case $1 in
    --build) build=true ;;
    --video) video=true ;;
    --lang) shift; [[ "${1:-}" == en || "${1:-}" == ja ]] || { echo "--lang takes en or ja" >&2; exit 1; }; langs=("$1") ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done
if $build; then (cd "$root/android" && ./gradlew assembleDebug); fi
[[ -f "$apk" ]] || { echo "No debug build at $apk (run with --build)" >&2; exit 1; }
if [[ -z "${ANDROID_SERIAL:-}" ]]; then
  ANDROID_SERIAL=$(adb devices | awk '/^emulator-[0-9]+\tdevice/ { print $1; exit }')
  [[ -n "$ANDROID_SERIAL" ]] || { echo "No emulator running (or set ANDROID_SERIAL)" >&2; exit 1; }
  export ANDROID_SERIAL
fi
if [[ -z "${GEMINI_API_KEY:-}" ]]; then
  read -rsp 'Gemini API key: ' GEMINI_API_KEY; echo
fi
mkdir -p "$out"

ja_sample='Good morning! The train to Kyoto leaves from platform 3 at 9:15. Could you tell me where I can buy a ticket, and whether there are any reserved seats left?'
en_sample='おはようございます。京都行きの電車は3番線から9時15分に発車します。切符はどこで買えますか？指定席はまだ空いていますか？'
ja_video_sample='Good morning! Where can I buy a ticket for the train to Kyoto?'
en_video_sample='おはようございます。京都行きの電車の切符はどこで買えますか？'

# The UI's own strings, read from i18n.js so the taps follow the wording there.
label() {
  node -e '
    globalThis.navigator = { language: "en" };
    require(process.argv[1]);
    console.log(globalThis.LangriaI18n.messages[process.argv[2]][process.argv[3]]);
  ' "$root/extension/lib/i18n.js" "$1" "$2"
}

# uiautomator waits for the screen to settle, so a spinner can hold it forever: give up after 10 s.
dump() {
  if ! perl -e 'alarm shift; exec @ARGV' 10 adb shell uiautomator dump /sdcard/langria-ui.xml >/dev/null 2>&1; then
    adb shell pkill uiautomator >/dev/null 2>&1 || true
    return 1
  fi
  adb exec-out cat /sdcard/langria-ui.xml
}

# Taps the centre of the first node whose text or content-desc starts with $1.
tap() {
  local xml point
  for _ in $(seq 20); do
    xml=$(dump) || { sleep 0.5; continue; }
    point=$(python3 -I -c '
import re, sys, xml.etree.ElementTree as ET
for node in ET.fromstring(sys.stdin.read()).iter("node"):
    if any(node.get(a, "").startswith(sys.argv[1]) for a in ("text", "content-desc")) and node.get("bounds"):
        x1, y1, x2, y2 = map(int, re.findall(r"\d+", node.get("bounds")))
        print((x1 + x2) // 2, (y1 + y2) // 2); break
' "$1" <<<"$xml")
    if [[ -n "$point" ]]; then adb shell input tap $point; return; fi
    sleep 0.5
  done
  echo "Could not find \"$1\" on screen" >&2; exit 1
}

# Waits until a node shows $1.
wait_for() {
  for _ in $(seq 60); do
    if dump | grep -qF "$1"; then return; fi
    sleep 0.5
  done
  echo "Timed out waiting for \"$1\"" >&2; exit 1
}

# Settings under the web app's localStorage names (see Settings.kt), written while the app is stopped.
write_prefs() {
  adb shell am force-stop $pkg
  adb shell run-as $pkg mkdir -p shared_prefs
  local xml="<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
  <string name=\"langria-ui-language\">$1</string>
  <string name=\"langria-theme\">$2</string>
  <string name=\"langria-target\">$3</string>
  <string name=\"langria-provider\">gemini</string>
  <string name=\"langria-mode\">natural</string>
  <boolean name=\"langria-screenshots\" value=\"true\" />
</map>"
  # Sent as base64 so the redirect runs inside run-as, which can write the app's files.
  adb shell "run-as $pkg sh -c 'echo $(base64 <<<"$xml" | tr -d '\n') | base64 -d > shared_prefs/langria.xml'"
  adb shell run-as $pkg cat shared_prefs/langria.xml | grep -q "\"langria-theme\">$2<" || { echo "Could not write the settings" >&2; exit 1; }
}

shot() { sleep 1; adb exec-out screencap -p > "$out/$1.png"; echo "Wrote store/android/images/$1.png"; }

adb install -r "$apk" >/dev/null
adb shell pm clear $pkg >/dev/null

# A tidy status bar (demo mode): fixed clock, full battery and signal, no notifications.
demo() { adb shell am broadcast -a com.android.systemui.demo -e command "$@" >/dev/null; }
adb shell settings put global sysui_demo_allowed 1
demo enter
demo clock -e hhmm 0941
demo battery -e level 100 -e plugged false
demo network -e wifi show -e level 4 -e fully true
demo network -e mobile hide
demo notifications -e visible false
# Demo mode leaves some system icons (the "no screen lock" shield), so snooze every notification for an hour.
adb shell dumpsys notification --noredact | sed -n 's/.*NotificationRecord(.* key=\([^:]*\): Notification.*/\1/p' | sort -u |
  while read -r key; do adb shell cmd notification snooze --for 3600000 "'$key'" >/dev/null; done
# Settings changed for the run, as name=value (namespace/name), put back at the end.
saved=()
change() {
  saved+=("$1/$2=$(adb shell settings get $1 $2)")
  adb shell settings put $1 $2 $3
}
restore() {
  demo exit
  adb shell wm size reset
  for entry in ${saved[@]+"${saved[@]}"}; do
    value=${entry#*=}
    setting=${entry%%=*}
    if [[ $value == null ]]; then adb shell settings delete ${setting%/*} ${setting#*/} >/dev/null; else adb shell settings put ${setting%/*} ${setting#*/} "$value"; fi
  done
}
trap restore EXIT

# Types like a person: a word at a time (input text has no spaces), or $2 characters at a time.
type_slowly() {
  if [[ -n "${2:-}" ]]; then
    local i
    for ((i = 0; i < ${#1}; i += $2)); do adb shell input text "'${1:i:$2}'"; done
    return
  fi
  local word first=true
  for word in $1; do
    $first || adb shell input keyevent KEYCODE_SPACE
    first=false
    adb shell input text "'$word'"
  done
}

# Saves the key from the settings screen, starting on the translation screen.
enter_key() {
  tap "$(label $1 web.openSettings)"
  sleep 1
  tap "$(label $1 settings.apiKey) Gemini"
  type_slowly "$GEMINI_API_KEY" ${2:-${#GEMINI_API_KEY}}
  adb shell input keyevent KEYCODE_BACK  # closes the keyboard
  tap "$(label $1 settings.save)"
  wait_for "$(label $1 web.savedProvider | sed 's/{name}/Gemini/')"
}

if $video; then
  # Bullets only while the key is typed, not the last character.
  change system show_password 0
  # Otherwise the keyboard may open its "Try out your stylus" sheet over the text field.
  change secure stylus_handwriting_enabled 0
  # 1080 x 1920 (9:16), as the screenshots.
  adb shell wm size 1080x1920
  for ui in "${langs[@]}"; do
    adb shell pm clear $pkg >/dev/null
    if [[ $ui == ja ]]; then write_prefs ja light Japanese; else write_prefs en light English; fi
    adb shell am start -W -n $pkg/.MainActivity >/dev/null
    sleep 2
    adb shell rm -f /sdcard/langria-demo.mp4
    adb shell screenrecord --bit-rate 8000000 /sdcard/langria-demo.mp4 &
    recorder=$!
    sleep 2
    enter_key $ui 6
    sleep 1
    tap "$(label $ui ios.done)"
    sleep 1
    tap "$(label $ui web.sourcePlaceholder)"
    if [[ $ui == ja ]]; then
      type_slowly "$ja_video_sample"
    else
      # adb cannot type Japanese, so it arrives at once, as if pasted: shared into
      # the activity already on screen (single top), which puts it in the text field.
      sleep 1.5
      adb shell "am start -f 0x20000000 -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT '$en_video_sample' -n $pkg/.MainActivity" >/dev/null
      sleep 1.5
    fi
    adb shell input keyevent KEYCODE_BACK  # closes the keyboard
    sleep 1.5
    # Done once neither the empty pane nor the spinner shows. The status under it is off screen at this size.
    for _ in $(seq 60); do
      xml=$(dump) || { sleep 0.5; continue; }
      grep -qF "$(label $ui web.empty)" <<<"$xml" || grep -q 'ProgressBar' <<<"$xml" || break
      sleep 0.5
    done
    sleep 3
    adb shell pkill -INT screenrecord
    wait $recorder || true
    sleep 1
    adb pull /sdcard/langria-demo.mp4 "$out/$ui-demo.mp4" >/dev/null
    echo "Wrote store/android/images/$ui-demo.mp4"
  done
  adb shell am force-stop $pkg
  exit
fi

# No animations, so the spinner stops and uiautomator sees a settled screen.
for scale in window_animation_scale transition_animation_scale animator_duration_scale; do change global $scale 0; done

# Save the key once; it stays in the app's key store across the runs below.
write_prefs en light English
adb shell am start -W -n $pkg/.MainActivity >/dev/null
enter_key en

for ui in "${langs[@]}"; do
  if [[ $ui == ja ]]; then target=Japanese; sample=$ja_sample; else target=English; sample=$en_sample; fi
  for theme in light dark; do
    write_prefs $ui $theme $target
    # uiautomator only lists what is on screen, so wait at the full height, where the status under the translation shows.
    adb shell wm size reset
    # The sample comes in as text shared from another app.
    adb shell "am start -W -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT '$sample' -n $pkg/.MainActivity" >/dev/null
    wait_for "$(label $ui status.done)"
    # 1080 x 1920 (9:16): Play takes at most 2:1, and 9:16 is what it uses to feature apps.
    adb shell wm size 1080x1920
    sleep 2
    shot "$ui-$theme-1-translate"
    tap "$(label $ui web.openSettings)"
    wait_for "$(label $ui settings.save)"
    shot "$ui-$theme-2-settings"
  done
done
adb shell am force-stop $pkg
