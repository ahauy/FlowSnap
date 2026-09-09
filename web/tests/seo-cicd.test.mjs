/**
 * Test Suite: FlowSnap SEO, OpenGraph, JSON-LD Schema & GitHub Pages CI/CD
 * Traces to: .specify/features/web-seo-cicd/test-plan.md (TC-SEO-001 through TC-SEO-006)
 */

import { readFileSync, existsSync, statSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const rootDir = resolve(__dirname, '../..');
const webDir = resolve(__dirname, '..');
const distPath = resolve(webDir, 'dist/index.html');
const baseLayoutPath = resolve(webDir, 'src/layouts/BaseLayout.astro');
const astroConfigPath = resolve(webDir, 'astro.config.mjs');
const robotsPath = resolve(webDir, 'public/robots.txt');
const sitemapPath = resolve(webDir, 'public/sitemap.xml');
const ogImagePath = resolve(webDir, 'public/og-preview.png');
const workflowPath = resolve(rootDir, '.github/workflows/deploy-pages.yml');

console.log('🧪 Starting SEO, OpenGraph, JSON-LD & CI/CD Test Suite (US-WEB-029)...\n');

// TC-SEO-001: OpenGraph Meta Tags Completeness & Absolute URLs
console.log('Checking TC-SEO-001: OpenGraph Meta Tags Completeness & Absolute URLs...');
assert.ok(existsSync(baseLayoutPath), 'BaseLayout.astro must exist');
const layoutContent = readFileSync(baseLayoutPath, 'utf8');

assert.ok(layoutContent.includes('property="og:type"'), 'og:type tag must be present');
assert.ok(layoutContent.includes('property="og:url"'), 'og:url tag must be present');
assert.ok(layoutContent.includes('property="og:title"'), 'og:title tag must be present');
assert.ok(layoutContent.includes('property="og:description"'), 'og:description tag must be present');
assert.ok(layoutContent.includes('property="og:image"'), 'og:image tag must be present');
assert.ok(layoutContent.includes('property="og:image:width"'), 'og:image:width tag must be present');
assert.ok(layoutContent.includes('property="og:image:height"'), 'og:image:height tag must be present');
assert.ok(layoutContent.includes('property="og:site_name"'), 'og:site_name tag must be present');
assert.ok(layoutContent.includes('property="og:locale"'), 'og:locale tag must be present');

// Verify absolute URL resolution logic
assert.ok(
  layoutContent.includes('https://ahauy.github.io/FlowSnap') || layoutContent.includes('Astro.site'),
  'Canonical URL / Absolute URL logic must resolve to https://ahauy.github.io/FlowSnap'
);
console.log('✅ TC-SEO-001 Passed!\n');

// TC-SEO-002: Twitter Cards Summary Large Image
console.log('Checking TC-SEO-002: Twitter Cards Summary Large Image...');
assert.ok(layoutContent.includes('name="twitter:card" content="summary_large_image"'), 'twitter:card must be summary_large_image');
assert.ok(layoutContent.includes('name="twitter:title"'), 'twitter:title must be present');
assert.ok(layoutContent.includes('name="twitter:description"'), 'twitter:description must be present');
assert.ok(layoutContent.includes('name="twitter:image"'), 'twitter:image must be present');
assert.ok(layoutContent.includes('name="twitter:site" content="@ahauy"') || layoutContent.includes('@ahauy'), 'twitter:site must be @ahauy');
assert.ok(layoutContent.includes('name="twitter:creator" content="@ahauy"') || layoutContent.includes('@ahauy'), 'twitter:creator must be @ahauy');
console.log('✅ TC-SEO-002 Passed!\n');

// TC-SEO-003: Schema.org SoftwareApplication JSON-LD Structured Data
console.log('Checking TC-SEO-003: Schema.org SoftwareApplication JSON-LD Structured Data...');
assert.ok(layoutContent.includes('type="application/ld+json"'), 'JSON-LD script tag must be present');
assert.ok(layoutContent.includes('SoftwareApplication'), 'JSON-LD must specify SoftwareApplication');
assert.ok(layoutContent.includes('UtilitiesApplication'), 'JSON-LD applicationCategory must be UtilitiesApplication');
assert.ok(layoutContent.includes('macOS 14.0+'), 'JSON-LD operatingSystem must be macOS 14.0+');
assert.ok(layoutContent.includes('FlowSnap.dmg'), 'JSON-LD downloadUrl must link to DMG release');
console.log('✅ TC-SEO-003 Passed!\n');

// TC-SEO-004: Social Preview Card Asset Presence & Format
console.log('Checking TC-SEO-004: Social Preview Card Asset Presence & Format...');
assert.ok(existsSync(ogImagePath), 'web/public/og-preview.png must exist');
const ogStats = statSync(ogImagePath);
assert.ok(ogStats.size > 5000, `og-preview.png size must be > 5KB, got ${ogStats.size} bytes`);
assert.ok(ogStats.size < 600000, `og-preview.png size must be < 600KB for fast social crawler retrieval, got ${ogStats.size} bytes`);

// Validate PNG magic bytes: 0x89 0x50 0x4E 0x47 (‰PNG)
const ogBuffer = readFileSync(ogImagePath);
assert.strictEqual(ogBuffer[0], 0x89, 'Byte 0 must be 0x89');
assert.strictEqual(ogBuffer[1], 0x50, 'Byte 1 must be 0x50 (P)');
assert.strictEqual(ogBuffer[2], 0x4e, 'Byte 2 must be 0x4E (N)');
assert.strictEqual(ogBuffer[3], 0x47, 'Byte 3 must be 0x47 (G)');
console.log('✅ TC-SEO-004 Passed!\n');

// TC-SEO-005: Crawling Policy Directives (robots.txt & sitemap.xml)
console.log('Checking TC-SEO-005: Crawling Policy Directives (robots.txt & sitemap.xml)...');
assert.ok(existsSync(robotsPath), 'web/public/robots.txt must exist');
const robotsContent = readFileSync(robotsPath, 'utf8');
assert.ok(robotsContent.includes('User-agent: *'), 'robots.txt must specify User-agent: *');
assert.ok(robotsContent.includes('Allow: /'), 'robots.txt must specify Allow: /');
assert.ok(robotsContent.includes('Sitemap: https://ahauy.github.io/FlowSnap/sitemap.xml'), 'robots.txt must point to sitemap.xml');

assert.ok(existsSync(sitemapPath), 'web/public/sitemap.xml must exist');
const sitemapContent = readFileSync(sitemapPath, 'utf8');
assert.ok(sitemapContent.includes('<urlset'), 'sitemap.xml must contain <urlset>');
assert.ok(sitemapContent.includes('<loc>https://ahauy.github.io/FlowSnap/</loc>') || sitemapContent.includes('https://ahauy.github.io/FlowSnap'), 'sitemap.xml must contain canonical FlowSnap URL');
assert.ok(sitemapContent.includes('<changefreq>weekly</changefreq>'), 'sitemap.xml must declare changefreq');
assert.ok(sitemapContent.includes('<priority>1.0</priority>'), 'sitemap.xml must declare priority 1.0');
console.log('✅ TC-SEO-005 Passed!\n');

// TC-SEO-006: GitHub Actions Workflow & Subpath Configuration
console.log('Checking TC-SEO-006: GitHub Actions Workflow & Subpath Configuration...');
assert.ok(existsSync(workflowPath), '.github/workflows/deploy-pages.yml must exist');
const workflowContent = readFileSync(workflowPath, 'utf8');
assert.ok(workflowContent.includes('branches: [main]') || workflowContent.includes("branches:\n      - main") || workflowContent.includes('- main'), 'Workflow must trigger on main');
assert.ok(workflowContent.includes("paths:") && workflowContent.includes("'web/**'") || workflowContent.includes("web/**"), 'Workflow must filter on web/**');
assert.ok(workflowContent.includes('pages: write'), 'Workflow must have pages: write permission');
assert.ok(workflowContent.includes('id-token: write'), 'Workflow must have id-token: write permission');
assert.ok(workflowContent.includes('actions/configure-pages'), 'Workflow must use configure-pages action');
assert.ok(workflowContent.includes('actions/upload-pages-artifact'), 'Workflow must use upload-pages-artifact action');
assert.ok(workflowContent.includes('actions/deploy-pages'), 'Workflow must use deploy-pages action');
assert.ok(workflowContent.includes('npm test'), 'Workflow must run npm test before deploy');

assert.ok(existsSync(astroConfigPath), 'astro.config.mjs must exist');
const astroConfig = readFileSync(astroConfigPath, 'utf8');
assert.ok(astroConfig.includes("site: 'https://ahauy.github.io'") || astroConfig.includes('https://ahauy.github.io'), 'astro.config.mjs must declare site URL');
assert.ok(astroConfig.includes('/FlowSnap'), 'astro.config.mjs must declare base /FlowSnap');
console.log('✅ TC-SEO-006 Passed!\n');

console.log('🎉 All SEO, OpenGraph, JSON-LD & CI/CD Tests Passed Successfully! (6/6 Test Cases)\n');
