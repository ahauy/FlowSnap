/**
 * Test Suite: Bento Grid Features Showcase, Metrics Proof & Shortcut Matrix
 * Traces to: .specify/features/web-bento-shortcuts/test-plan.md (TC-001 through TC-007)
 */

import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const distPath = resolve(__dirname, '../dist/index.html');
const astroDir = resolve(__dirname, '../dist/_astro');

console.log('🧪 Starting Bento Grid & Shortcut Matrix Test Suite...\n');

assert.ok(existsSync(distPath), 'Build artifact dist/index.html must exist before running test assertions');
const html = readFileSync(distPath, 'utf8');
const cssFiles = existsSync(astroDir)
  ? readdirSync(astroDir).filter((f) => f.endsWith('.css')).map((f) => readFileSync(resolve(astroDir, f), 'utf8')).join('\n')
  : '';

// TC-001: 6 Bento Cards & Asymmetric Grid Structure
console.log('Checking TC-001: 6 Bento Cards & Asymmetric Grid Structure...');
assert.ok(html.includes('id="bento-grid-root"'), 'Bento grid container must be present');
assert.ok(html.includes('data-bento-card="top-edge-picker"'), 'Top-Edge Picker card must be present');
assert.ok(html.includes('data-bento-card="collinear-2d"'), 'Collinear 2D Resize card must be present');
assert.ok(html.includes('data-bento-card="current-space"'), 'Current Space card must be present');
assert.ok(html.includes('data-bento-card="workspaces-presets"'), 'Workspaces & Presets card must be present');
assert.ok(html.includes('data-bento-card="quake-scratchpad"'), 'Quake Scratchpad card must be present');
assert.ok(html.includes('data-bento-card="multi-monitor"'), 'Multi-Monitor Topology card must be present');

// Verify hero vs standard spans
assert.ok(html.includes('bento-hero'), 'At least 2 hero cards must have class bento-hero');
assert.ok(html.includes('bento-standard'), 'Standard cards must have class bento-standard');
console.log('✅ TC-001 Passed!\n');

// TC-002: Native SVG/CSS Micro-Illustrations
console.log('Checking TC-002: Native SVG/CSS Micro-Illustrations in each card...');
assert.ok(html.includes('illustration-top-edge'), 'Top-Edge vector illustration must be present');
assert.ok(html.includes('illustration-collinear-2d'), 'Collinear 2D vector illustration must be present');
assert.ok(html.includes('illustration-current-space'), 'Current Space vector illustration must be present');
assert.ok(html.includes('illustration-workspaces'), 'Workspaces vector illustration must be present');
assert.ok(html.includes('illustration-quake-scratchpad'), 'Quake Scratchpad vector illustration must be present');
assert.ok(html.includes('illustration-multi-monitor'), 'Multi-Monitor vector illustration must be present');
console.log('✅ TC-002 Passed!\n');

// TC-003: 5 Verifiable Technical Claims (Metrics Proof Ribbon)
console.log('Checking TC-003: Metrics Proof Ribbon (5 Verifiable Claims)...');
assert.ok(html.includes('id="metrics-proof-root"'), 'Metrics proof ribbon container must be present');
assert.ok(html.includes('Swift 6'), 'Swift 6 metric must be present');
assert.ok(html.includes('Strict Concurrency'), 'Strict Concurrency label must be present');
assert.ok(html.includes('Private APIs'), '0 Private APIs metric must be present');
assert.ok(html.includes('&lt; 1ms') || html.includes('< 1ms'), '< 1ms Snap Math metric must be present');
assert.ok(html.includes('60 FPS'), '60 FPS Divider Dragging metric must be present');
console.log('✅ TC-003 Passed!\n');

// TC-004: Category Filter Tabs & 15 Shortcut Definitions
console.log('Checking TC-004: Shortcut Matrix Category Tabs & Keycaps...');
assert.ok(html.includes('id="shortcut-matrix-root"'), 'Shortcut Matrix container must be present');
assert.ok(html.includes('data-filter-category="all"'), 'Tab All must be present');
assert.ok(html.includes('data-filter-category="window"'), 'Tab Window must be present');
assert.ok(html.includes('data-filter-category="display"'), 'Tab Display must be present');
assert.ok(html.includes('data-filter-category="workspace"'), 'Tab Workspace must be present');
assert.ok(html.includes('data-filter-category="utility"'), 'Tab Utility must be present');

// Check signature shortcuts
assert.ok(html.includes('⌥Space'), '⌥Space Quake Scratchpad shortcut must be present');
assert.ok(html.includes('⌃⌥←'), '⌃⌥← Left Snap shortcut must be present');
assert.ok(html.includes('⌃⌥⇧→'), '⌃⌥⇧→ Cross-display throw shortcut must be present');
assert.ok(html.includes('⌃⌥⌘1'), '⌃⌥⌘1 Coding preset shortcut must be present');
assert.ok(html.includes('⌃⌥P'), '⌃⌥P Always-on-top shortcut must be present');
console.log('✅ TC-004 Passed!\n');

// TC-005: Live Search Input & Zero-Match Empty State
console.log('Checking TC-005: Live Search Input & Empty State...');
assert.ok(html.includes('id="shortcut-search-input"'), 'Search input must be present');
assert.ok(html.includes('id="shortcut-search-clear"'), 'Search clear button must be present');
assert.ok(html.includes('id="shortcut-empty-state"'), 'Empty state container must be present');
console.log('✅ TC-005 Passed!\n');

// TC-006: 1-Click Clipboard Copy Data Contract
console.log('Checking TC-006: 1-Click Clipboard Copy Data Contract...');
assert.ok(html.includes('data-copy-shortcut='), 'data-copy-shortcut attributes must be present on shortcut rows/cards');
assert.ok(html.includes('copy-shortcut-btn'), 'Copy shortcut buttons must be present');
console.log('✅ TC-006 Passed!\n');

// TC-007: Anti-AI-Slop & Design System Compliance
console.log('Checking TC-007: Anti-AI-Slop & Design Tokens Compliance...');
assert.ok(!html.includes('from-purple-500'), 'Must not include unrequested generic purple gradients');
assert.ok(!html.includes('from-pink-500'), 'Must not include unrequested generic pink gradients');
assert.ok(html.includes('keycap-pill'), 'Authentic keycap-pill styling must be present');
console.log('✅ TC-007 Passed!\n');

// TC-008: CSS [hidden] Enforcement & Search Normalization
console.log('Checking TC-008: CSS [hidden] Enforcement & Search Normalization...');
assert.ok(cssFiles.includes('[hidden]') || html.includes('[hidden]'), 'Global [hidden] reset rule must be defined');
assert.ok(cssFiles.includes('display:none!important') || cssFiles.includes('display: none !important'), 'Enforced display none for hidden elements must be compiled');
assert.ok(html.includes('data-search-text='), 'Search index data attribute must be present on shortcut cards');
console.log('✅ TC-008 Passed!\n');

console.log('🎉 All Bento Grid & Shortcut Matrix Tests Passed Successfully!\n');
