/**
 * export-pdf.js
 * Converts all KasetHaul mockup HTML files to PDF
 * 1 screen per page, phone frame centered on each page
 *
 * Usage: node export-pdf.js
 */

const puppeteer = require('puppeteer-core');
const path = require('path');
const fs = require('fs');

const CHROME_PATH = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const MOCKUP_DIR = path.resolve(__dirname);
const OUTPUT_DIR = path.join(MOCKUP_DIR, 'pdf');

// Phone frame: 375 x 812px → page with 28px margin each side = 431 x 900px
const PAGE_WIDTH  = '431px';
const PAGE_HEIGHT = '900px';

const PRINT_CSS = `
  @page { size: ${PAGE_WIDTH} ${PAGE_HEIGHT}; margin: 0; }

  body {
    margin: 0 !important;
    padding: 0 !important;
    background: #f0f0f0 !important;
  }

  .mockup-container {
    display: block !important;
    padding: 0 !important;
    gap: 0 !important;
    background: #f0f0f0 !important;
  }

  .mobile-wrapper {
    page-break-after: always !important;
    break-after: page !important;
    display: flex !important;
    flex-direction: column !important;
    align-items: center !important;
    justify-content: center !important;
    width: 100% !important;
    min-height: ${PAGE_HEIGHT} !important;
    margin: 0 !important;
    padding: 0 !important;
    box-sizing: border-box !important;
    background: #f0f0f0 !important;
  }

  .mobile-wrapper:last-child {
    page-break-after: avoid !important;
    break-after: avoid !important;
  }

  .mockup-label {
    margin-top: 8px !important;
    font-size: 13px !important;
    font-family: 'Sarabun', sans-serif !important;
    color: #555 !important;
  }
`;

const HTML_FILES = [
  '01-auth.html',
  '02-client-jobs.html',
  '03-client-bidding.html',
  '04-client-tracking.html',
  '05-client-wallet.html',
  '06-driver-jobs.html',
  '07-driver-myjobs.html',
  '08-driver-truck-earnings.html',
  '09-admin.html',
  '10-client-profile.html',
  '11-driver-profile.html',
];

async function convertFile(browser, htmlFile) {
  const page = await browser.newPage();

  // Wide viewport so layout renders normally before we inject print CSS
  await page.setViewport({ width: 1920, height: 900 });

  const filePath = path.join(MOCKUP_DIR, htmlFile).replace(/\\/g, '/');
  await page.goto(`file:///${filePath}`, {
    waitUntil: 'networkidle2',
    timeout: 30000,
  });

  // Wait for Google Fonts to load
  await new Promise(r => setTimeout(r, 1500));

  // Inject print CSS (transforms horizontal layout → 1 screen per page)
  await page.addStyleTag({ content: PRINT_CSS });

  const outputPath = path.join(OUTPUT_DIR, htmlFile.replace('.html', '.pdf'));

  await page.pdf({
    path: outputPath,
    width: PAGE_WIDTH,
    height: PAGE_HEIGHT,
    printBackground: true,
  });

  await page.close();

  const stats = fs.statSync(outputPath);
  const sizeKB = (stats.size / 1024).toFixed(0);
  console.log(`  ✓  ${htmlFile.padEnd(30)} →  ${path.basename(outputPath)}  (${sizeKB} KB)`);
}

async function main() {
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  console.log('KasetHaul Mockup PDF Exporter');
  console.log('================================');
  console.log(`Output folder: ${OUTPUT_DIR}\n`);

  const browser = await puppeteer.launch({
    executablePath: CHROME_PATH,
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-gpu',
      '--disable-dev-shm-usage',
    ],
  });

  const startTime = Date.now();

  for (const file of HTML_FILES) {
    await convertFile(browser, file);
  }

  await browser.close();

  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log(`\nDone! ${HTML_FILES.length} files exported in ${elapsed}s`);
  console.log(`Saved to: ${OUTPUT_DIR}`);
}

main().catch(err => {
  console.error('\nError:', err.message);
  process.exit(1);
});
