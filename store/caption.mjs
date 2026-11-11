// Makes the store screenshots with a caption above them, from the plain ones
// taken by store/ios/capture.sh and store/android/capture.sh: a headline and
// a line under it, then the screen in a rounded frame. Listings whose first
// screenshots say what the app does convert better than bare screens.
//
//   node store/caption.mjs [ios] [android]
//
// Writes store/{ios,android}/images/captioned/, each image the size of the
// plain one, as the stores want. Slides whose plain screenshot is missing are
// skipped (the share sheet is taken by hand, see store/ios/README.md).
// Needs Playwright with Chromium (the global install is used when the repo
// has none). The captions use the system's fonts (Hiragino Sans on a Mac).
// No other company's name goes in a caption (the stores reject trademarks there).
import { createRequire } from 'node:module';
import { execSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdir, readFile } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
let playwright;
try { playwright = require('playwright'); } catch { playwright = require(join(execSync('npm root -g').toString().trim(), 'playwright')); }
const { chromium } = playwright;

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

// By slide: [headline, line under it] in English and Japanese.
const captions = {
  translate: {
    en: ['Translate with the AI you choose', 'Type or paste, and the translation appears as you pause'],
    ja: ['選んだAIで、自然な翻訳', '入力の手を止めると、すぐに訳文が出ます']
  },
  photo: {
    en: ['Snap a sign or a menu', 'The text is read on your device. The photo is never sent'],
    ja: ['看板やメニューを撮って翻訳', '文字は端末の中で読み取り、画像は送りません']
  },
  share: {
    en: ['Translate from any app', 'Share text or a web page and read it right in the sheet'],
    ja: ['ほかのアプリから、そのまま翻訳', '文章やWebページを共有すると、その場で訳文を読めます']
  },
  watch: {
    en: ['On Apple Watch too', 'Speak a sentence and read or hear it on your wrist'],
    ja: ['Apple Watch でも翻訳', '話した言葉を、手元で訳して読み上げます']
  },
  settings: {
    en: ['No account, no server', 'Use your own API key. A free one is enough to start'],
    ja: ['登録なし・サーバーなし', '自分のAPIキーで使えます。無料のキーでも始められます']
  },
  dark: {
    en: ['Five ways to translate', 'Faithful, natural, business, casual or technical'],
    ja: ['場面に合わせた5つの翻訳モード', '忠実・自然・ビジネス・会話・技術文書から選べます']
  }
};

// By store and device: the slides in the order they are uploaded, as
// [caption, plain screenshot]. `canvas` is the screenshot that gives a slide
// its size when its own is another device's (the watch on the iPhone's slide).
const sets = {
  ios: {
    iphone: [['translate', 'iphone-1-translate'], ['photo', 'iphone-2-photo'], ['share', 'iphone-5-share'], ['watch', 'watch-1-translate', 'iphone-1-translate'], ['settings', 'iphone-4-settings'], ['dark', 'iphone-3-dark']],
    duo: [['translate', 'duo-1-translate'], ['photo', 'duo-2-photo'], ['share', 'duo-5-share'], ['settings', 'duo-4-settings'], ['dark', 'duo-3-dark']],
    ipad: [['translate', 'ipad-1-translate'], ['photo', 'ipad-2-photo'], ['share', 'ipad-5-share'], ['settings', 'ipad-4-settings'], ['dark', 'ipad-3-dark']]
  },
  android: {
    phone: [['translate', 'light-1-translate'], ['photo', 'light-3-photo'], ['settings', 'light-2-settings'], ['dark', 'dark-1-translate']]
  }
};

// The width and height in a PNG's header.
async function size(path) {
  const header = await readFile(path);
  return { width: header.readUInt32BE(16), height: header.readUInt32BE(20) };
}

// Sizes are in vw, so one layout serves every screenshot size. The frame's
// corner follows the device's: wide on phones, tighter on the iPad, round on the watch.
function page(lang, [title, sub], image, shot, canvas) {
  const wide = shot.width / shot.height > 0.7;
  const watch = shot.width < 600;
  const radius = watch ? 9 : wide ? 2.4 : 6;
  // The screen takes what the caption leaves, keeping its proportions. On a
  // shorter canvas the line under the headline may wrap, so more is left.
  const tall = canvas.height / canvas.width;
  const box = { width: watch ? 64 : 84, height: tall * 100 - (wide && !watch ? 24 : tall < 2 ? 38 : 31) };
  const width = Math.min(box.width, box.height * shot.width / shot.height);
  return `<!doctype html><html lang="${lang}"><meta charset="utf-8"><style>
    * { box-sizing: border-box; margin: 0; }
    html, body { width: 100vw; height: 100vh; overflow: hidden; }
    body { background: radial-gradient(120vw 70vw at 50% -20vw, #2c3a18 0%, #151a1b 55%, #111516 100%); color: #edf0ea;
      font-family: "SF Pro Display", "Hiragino Sans", "Noto Sans JP", "Noto Sans CJK JP", system-ui, sans-serif;
      display: flex; flex-direction: column; align-items: center; text-align: center; }
    h1 { margin-top: ${wide && !watch ? 5 : 8}vw; padding: 0 5vw; font-size: ${wide && !watch ? 4.6 : 6.6}vw; line-height: 1.25; font-weight: 800; letter-spacing: -0.01em; text-wrap: balance; }
    h1 b { color: #c8f859; font-weight: inherit; }
    p { margin-top: ${wide && !watch ? 1.4 : 2.2}vw; padding: 0 7vw; font-size: ${wide && !watch ? 2.3 : 3.5}vw; line-height: 1.45; font-weight: 500; color: #cbd1cd; text-wrap: balance; }
    .shot { margin-top: auto; margin-bottom: ${watch ? 'auto' : wide ? '3.5vw' : '5vw'}; width: ${width}vw; border-radius: ${radius}vw; overflow: hidden;
      border: ${watch ? 1.6 : 0.45}vw solid #3a4445; box-shadow: 0 3vw 8vw #0009; background: #000; }
    .shot img { display: block; width: 100%; }
  </style><h1>${title}</h1><p>${sub}</p><div class="shot"><img src="${image}"></div></html>`;
}

const stores = process.argv.slice(2).length ? process.argv.slice(2) : Object.keys(sets);
for (const store of stores) if (!sets[store]) { console.error(`Unknown store: ${store} (ios or android)`); process.exit(1); }

const browser = await chromium.launch();
for (const store of stores) {
  const images = join(root, 'store', store, 'images');
  await mkdir(join(images, 'captioned'), { recursive: true });
  for (const lang of ['en', 'ja']) {
    for (const [device, slides] of Object.entries(sets[store])) {
      let number = 0;
      for (const [caption, plain, sized] of slides) {
        const image = join(images, `${lang}-${plain}.png`);
        if (!existsSync(image)) continue;
        number += 1;
        const shot = await size(image);
        const canvas = sized ? await size(join(images, `${lang}-${sized}.png`)) : shot;
        const tab = await browser.newPage({ viewport: canvas, deviceScaleFactor: 1 });
        const file = join(images, 'captioned', `${lang}-${device}-${number}-${caption}.png`);
        // The screenshot goes in as a data URL: a page set this way may not load files from disk.
        const data = `data:image/png;base64,${(await readFile(image)).toString('base64')}`;
        await tab.setContent(page(lang, captions[caption][lang], data, shot, canvas), { waitUntil: 'load' });
        await tab.evaluate(() => document.fonts.ready);
        await tab.screenshot({ path: file });
        await tab.close();
        console.log(`Wrote store/${store}/images/captioned/${lang}-${device}-${number}-${caption}.png`);
      }
    }
  }
}
await browser.close();
