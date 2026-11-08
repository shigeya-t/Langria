// Captures the web app screenshots used by the project page (docs/) into
// assets/site/: {en,ja}-web-app-{light,dark}.png, 1280 wide.
//
//   node scripts/capture-site.mjs
//
// Needs Playwright with Chromium (the global install is used when the repo has
// none). No API key is needed: the OpenAI request is answered with a stub.
// The extension slides for the page are made by store/chrome/capture.mjs.
import { createRequire } from 'node:module';
import { execSync } from 'node:child_process';
import { createServer } from 'node:http';
import { readFile, mkdir } from 'node:fs/promises';
import { join, dirname, extname, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
let playwright;
try { playwright = require('playwright'); } catch { playwright = require(join(execSync('npm root -g').toString().trim(), 'playwright')); }
const { chromium } = playwright;

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = join(root, 'assets', 'site');

const english = 'Every morning, I wake up at seven o’clock and prepare breakfast for myself. After breakfast, I usually spend thirty minutes studying English because I want to improve my communication skills. Although learning a new language can be challenging, I believe that practicing a little every day is the key to success. On weekends, I sometimes watch English movies or read books to learn new words and expressions. I hope that one day I will be able to speak English fluently and communicate with people from all over the world.';
const japanese = '毎朝7時に起きて、自分の朝食を用意します。朝食の後は、コミュニケーション能力を高めたいので、たいてい30分ほど英語の勉強をします。新しい言語を学ぶのは大変なこともありますが、毎日少しずつ練習することが成功への鍵だと思います。週末には、英語の映画を見たり本を読んだりして、新しい単語や表現を学ぶこともあります。いつか英語を流暢に話し、世界中の人々とコミュニケーションを取れるようになりたいです。';

// Each page shows the direction its readers care about: English readers see
// Japanese translated into English, Japanese readers the reverse.
const shots = {
  en: { source: japanese, translation: english, target: 'English' },
  ja: { source: english, translation: japanese, target: 'Japanese' }
};

const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.css': 'text/css', '.svg': 'image/svg+xml', '.png': 'image/png' };

async function main() {
  await mkdir(out, { recursive: true });
  const server = createServer(async (req, res) => {
    const path = normalize(decodeURIComponent(new URL(req.url, 'http://x').pathname)).replace(/^(\.\.[/\\])+/, '');
    try {
      const body = await readFile(join(root, path.endsWith('/') ? `${path}index.html` : path));
      res.writeHead(200, { 'Content-Type': types[extname(path) || '.html'] || 'application/octet-stream' });
      res.end(body);
    } catch { res.writeHead(404); res.end(); }
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const base = `http://localhost:${server.address().port}/`;

  // Full Chromium in headless mode, as store/chrome/capture.mjs uses (no separate headless shell needed).
  const browser = await chromium.launch({ headless: false, args: ['--headless=new'] });
  for (const [locale, shot] of Object.entries(shots)) {
    for (const theme of ['light', 'dark']) {
      const context = await browser.newContext({ viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1, locale: locale === 'ja' ? 'ja-JP' : 'en-US', colorScheme: theme });
      await context.addInitScript((settings) => { for (const [key, value] of Object.entries(settings)) localStorage.setItem(key, value); }, {
        'langria-ui-language': locale, 'langria-theme': theme, 'langria-provider': 'openai', 'langria-openai-key': 'sk-demo',
        'langria-target': shot.target, 'langria-mode': 'natural'
      });
      await context.route('https://api.openai.com/**', (route) => route.fulfill({ contentType: 'application/json', body: JSON.stringify({ output_text: shot.translation }) }));
      const page = await context.newPage();
      await page.goto(base);
      await page.evaluate(() => document.fonts.ready);
      await page.fill('#sourceText', shot.source);
      await page.waitForFunction((text) => document.querySelector('#translation').textContent.trim() === text, shot.translation);
      // The field scrolls its text instead of growing; make it tall enough to show all of it.
      await page.evaluate(() => { const source = document.querySelector('#sourceText'); source.blur(); source.style.flex = `0 0 ${source.scrollHeight}px`; source.scrollTop = 0; });
      await page.waitForTimeout(400);
      await page.screenshot({ path: join(out, `${locale}-web-app-${theme}.png`), fullPage: true });
      await context.close();
    }
  }
  await browser.close();
  server.close();
  console.log(`Wrote images to ${out}`);
}

main().catch((error) => { console.error(error); process.exit(1); });
