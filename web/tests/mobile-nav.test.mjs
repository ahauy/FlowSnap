/**
 * mobile-nav.test.mjs: regression guard for the header drawer.
 *
 * The drawer exists because the header row needs 833.69px (EN) / 843.48px (VI)
 * of intrinsic width and 886px / 896px with touch-sized controls, so any
 * viewport below that breaks if the controls stop collapsing together.
 * These assertions fail if a control is left outside the panel, if the toggle
 * moves inside it, or if the close handlers disappear from the bundle.
 */
import { readFileSync, readdirSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';

const __dirname = fileURLToPath(new URL('.', import.meta.url));
const distDir = resolve(__dirname, '../dist');
const astroDir = join(distDir, '_astro');
const html = readFileSync(join(distDir, 'index.html'), 'utf8');
const viHtml = readFileSync(join(distDir, 'vi/index.html'), 'utf8');

// Astro inlines a small component script into <script type="module"> in the
// page, so the drawer handlers live in index.html, not in a _astro chunk.
const js = [html, viHtml, ...readdirSync(astroDir).filter((f) => f.endsWith('.js')).map((f) => readFileSync(join(astroDir, f), 'utf8'))].join('\n');
const css = readdirSync(astroDir)
  .filter((f) => f.endsWith('.css'))
  .map((f) => readFileSync(join(astroDir, f), 'utf8'))
  .join('\n');

console.log('Checking TC-NAV-001: links and actions share one drawer container...');
const menu = html.match(/<div class="header-menu"[^>]*id="site-nav"[^>]*>([\s\S]*?)<\/div>\s*<button/);
assert.ok(menu, 'header-menu#site-nav must wrap the block that precedes the toggle');
assert.ok(/<nav class="nav-links"/.test(menu[1]), 'the four nav links must live inside the drawer');
assert.ok(/class="header-actions"/.test(menu[1]), 'the language switcher, GitHub and theme controls must live inside the drawer');
for (const label of ['lang-switcher', 'github-btn', 'theme-toggle']) {
  assert.ok(menu[1].includes(label), `${label} would be unreachable on a phone if left outside the panel`);
}
console.log('✅ TC-NAV-001 Passed!\n');

console.log('Checking TC-NAV-002: the toggle stays outside the panel it opens...');
assert.ok(/id="site-nav-toggle"[^>]*aria-controls="site-nav"/.test(html), 'toggle must control #site-nav');
assert.ok(/aria-expanded="false"/.test(html), 'toggle must ship a closed state');
const toggleIndex = html.indexOf('id="site-nav-toggle"');
const menuIndex = html.indexOf('class="header-menu"');
assert.ok(menuIndex >= 0 && toggleIndex > menuIndex, 'toggle must not be nested inside the collapsed panel');
assert.equal((html.match(/id="site-nav"/g) || []).length, 1, 'exactly one #site-nav, or aria-controls is ambiguous');
console.log('✅ TC-NAV-002 Passed!\n');

console.log('Checking TC-NAV-003: close handlers and the drawer breakpoint shipped...');
// Astro's minifier rewrites (max-width: 860px) to (width<=860px); accept both.
assert.ok(/width<=860px|max-width:\s*860px/.test(css), 'drawer breakpoint must cover the fine-pointer band where the row stops fitting');
assert.ok(/pointer:\s*coarse\)\s*and\s*\(width<=900px|pointer:\s*coarse\)\s*and\s*\(max-width:\s*900px/.test(css), 'touch viewports must get the drawer up to 900px');
assert.ok(/is-open/.test(html) || /is-open/.test(js), 'the open class the CSS keys off must exist');
assert.ok(/Escape/.test(js), 'Escape must close the drawer and return focus');
assert.ok(/addEventListener\([`"']click[`"']/.test(js), 'click handlers must be wired (the minifier rewrites quotes to backticks)');
assert.ok(/matchMedia/.test(js), 'leaving the drawer breakpoint must close an open panel');
console.log('✅ TC-NAV-003 Passed!\n');

console.log('Checking TC-NAV-004: Vietnamese locale collapses identically...');
assert.ok(/<div class="header-menu"[^>]*id="site-nav"/.test(viHtml), 'the VI page must use the same drawer, not a copy of the desktop row');
assert.ok(/class="header-actions"/.test(viHtml.split('id="site-nav-toggle"')[0]), 'VI actions must also be inside the panel');
assert.equal((viHtml.match(/id="site-nav"/g) || []).length, 1, 'VI must keep a single #site-nav');
console.log('✅ TC-NAV-004 Passed!\n');

console.log('🎉 All Mobile Navigation Tests Passed Successfully! (4/4 Test Cases)');
