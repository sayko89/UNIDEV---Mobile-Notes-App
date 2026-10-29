// Takes the README screenshots from the real web build of the app, using its `?demo=1`
// sample data. Usage (with the web build served on port 8080):
//
//   flutter build web --release && python3 -m http.server 8080 -d build/web &
//   npm install playwright@1.49.1 && npx playwright install chromium
//   node tool/screenshots.mjs http://localhost:8080 docs/screenshots
//
// Flutter draws the UI on a canvas, so elements are found through Flutter's accessibility
// (semantics) tree, which the script switches on.
import { chromium } from 'playwright';
import { mkdirSync, writeFileSync } from 'node:fs';

const base = process.argv[2] ?? 'http://localhost:8080';
const out = process.argv[3] ?? 'docs/screenshots';
mkdirSync(out, { recursive: true });

const log = [];
const note = (msg) => { console.log(msg); log.push(msg); };

const browser = await chromium.launch();

async function open(query, { theme = 'light', video = false } = {}) {
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 3,
    colorScheme: theme,
    locale: 'tr-TR',
    ...(video ? { recordVideo: { dir: `${out}/_video`, size: { width: 390, height: 844 } } } : {}),
  });
  const page = await context.newPage();
  page.on('pageerror', (e) => note(`pageerror: ${e.message}`));
  await page.goto(`${base}/?theme=${theme}${query}`, { waitUntil: 'networkidle', timeout: 90_000 });
  await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60_000 });
  await page.waitForTimeout(2500);
  // Flutter's "Enable accessibility" button sits off-screen; trigger it directly.
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForTimeout(800);
  return { context, page };
}

/** Finds a semantics node by its visible text or accessible name. */
async function find(page, name) {
  const candidates = [
    page.getByRole('button', { name, exact: false }),
    page.getByLabel(name, { exact: false }),
    page.getByText(name, { exact: false }),
  ];
  for (const locator of candidates) {
    if (await locator.count()) return locator.first();
  }
  throw new Error(`not found: ${name}`);
}

async function tap(page, name, wait = 900) {
  const el = await find(page, name);
  const box = await el.boundingBox();
  if (!box) throw new Error(`no box for: ${name}`);
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  await page.waitForTimeout(wait);
}

async function longPress(page, name) {
  const el = await find(page, name);
  const box = await el.boundingBox();
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  await page.mouse.down();
  await page.waitForTimeout(900);
  await page.mouse.up();
  await page.waitForTimeout(900);
}

async function shot(page, file) {
  await page.screenshot({ path: `${out}/${file}` });
  note(`saved ${file}`);
}

async function step(name, fn) {
  try {
    await fn();
  } catch (e) {
    note(`FAILED ${name}: ${e.message}`);
  }
}

await step('home', async () => {
  const { context, page } = await open('&demo=1');
  await shot(page, '01-home.png');
  const labels = await page.$$eval('flt-semantics', (nodes) =>
    nodes.map((n) => n.getAttribute('aria-label') || n.textContent).filter(Boolean).slice(0, 40));
  note(`semantics labels: ${JSON.stringify(labels)}`);
  await context.close();
});

await step('detail', async () => {
  const { context, page } = await open('&demo=1');
  await tap(page, 'Haftalık toplantı');
  await shot(page, '02-detail.png');
  await context.close();
});

await step('editor', async () => {
  const { context, page } = await open('&demo=1');
  await tap(page, 'Yeni not');
  await page.keyboard.type('Proje teslimi', { delay: 30 });
  await page.keyboard.press('Tab');
  await page.keyboard.type('Ekran görüntülerini ekle\nREADME’yi güncelle\nCuma 17:00’ye kadar gönder', { delay: 15 });
  await tap(page, 'İş', 500);
  await shot(page, '03-editor.png');
  await context.close();
});

await step('menu', async () => {
  const { context, page } = await open('&demo=1');
  await longPress(page, 'Market listesi');
  await shot(page, '04-menu.png');
  await context.close();
});

await step('filter', async () => {
  const { context, page } = await open('&demo=1');
  await tap(page, 'Okul');
  await shot(page, '05-filter.png');
  await context.close();
});

await step('dark', async () => {
  const { context, page } = await open('&demo=1', { theme: 'dark' });
  await shot(page, '06-dark.png');
  await context.close();
});

await step('empty', async () => {
  const { context, page } = await open('');
  await shot(page, '07-empty.png');
  await context.close();
});

// A short screen recording of the main flow, converted to a GIF by the workflow.
await step('flow video', async () => {
  const { context, page } = await open('&demo=1', { video: true });
  await page.waitForTimeout(800);
  await tap(page, 'Haftalık toplantı', 1400);
  await tap(page, 'Geri', 1000);
  await tap(page, 'Yeni not', 800);
  await page.keyboard.type('Kahve molası', { delay: 60 });
  await page.keyboard.press('Tab');
  await page.keyboard.type('Saat 15:00, kampüs kafe', { delay: 45 });
  await tap(page, 'Kişisel', 600);
  await tap(page, 'Kaydet', 1400);
  await longPress(page, 'Kahve molası');
  await tap(page, 'Sil', 1400);
  await tap(page, 'Geri al', 1600);
  const video = page.video();
  await context.close();
  if (video) note(`video: ${await video.path()}`);
});

await browser.close();
writeFileSync(`${out}/_log.txt`, log.join('\n'));
