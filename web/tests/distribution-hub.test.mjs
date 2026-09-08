/**
 * Test Suite: Distribution Hub, 1-Click Terminal Copy, DMG & Privacy Manifesto
 * Traces to: .specify/features/web-distribution-hub/test-plan.md (TC-DIST-001 through TC-DIST-006)
 */

import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const distPath = resolve(__dirname, '../dist/index.html');

console.log('🧪 Starting Distribution Hub Test Suite (US-WEB-028)...\n');

assert.ok(existsSync(distPath), 'Build artifact dist/index.html must exist before running test assertions');
const html = readFileSync(distPath, 'utf8');

// TC-DIST-001: Direct DMG Link & Release Metadata
console.log('Checking TC-DIST-001: Direct DMG Link & Release Metadata...');
assert.ok(html.includes('https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg'), 'Direct DMG download URL must be present');
assert.ok(html.includes('v1.3.1'), 'Version v1.3.1 badge must be present');
assert.ok(html.includes('Universal Binary'), 'Universal Binary architecture badge must be present');
assert.ok(html.includes('macOS 14.0+'), 'macOS 14.0+ requirement must be present');
assert.ok(html.includes('~14.2 MB'), 'File size ~14.2 MB must be present');
assert.ok(html.includes('https://github.com/ahauy/FlowSnap/releases'), 'Link to releases archive must be present');
console.log('✅ TC-DIST-001 Passed!\n');

// TC-DIST-002: Tabbed Terminal Installer Box
console.log('Checking TC-DIST-002: Tabbed Terminal Installer Box...');
assert.ok(html.includes('id="terminal-installer-root"') || html.includes('class="terminal-box"'), 'Terminal installer container must be present');
assert.ok(html.includes('curl -fsSL https://raw.githubusercontent.com/ahauy/FlowSnap/main/install.sh | bash'), 'cURL command string must be present');
assert.ok(html.includes('brew install --cask ahauy/tap/flowsnap'), 'Homebrew command string must be present');
assert.ok(html.includes('data-install-tab="curl"'), 'cURL tab button must be present');
assert.ok(html.includes('data-install-tab="brew"'), 'Homebrew tab button must be present');
console.log('✅ TC-DIST-002 Passed!\n');

// TC-DIST-003: 1-Click Clipboard Copy & Feedback Behavior
console.log('Checking TC-DIST-003: 1-Click Clipboard Copy & Feedback Behavior...');
assert.ok(html.includes('data-copy-trigger'), 'Copy button with data-copy-trigger must be present');
assert.ok(html.includes('aria-live="polite"'), 'ARIA live region for copy feedback must be present');
assert.ok(html.includes('copyToClipboard') || html.includes('navigator.clipboard'), 'Clipboard handling logic must be present in output');
console.log('✅ TC-DIST-003 Passed!\n');

// TC-DIST-004: Privacy & Security Manifesto (3 Pillars)
console.log('Checking TC-DIST-004: Privacy & Security Manifesto (3 Pillars)...');
assert.ok(html.includes('id="privacy-manifesto-root"') || html.includes('class="privacy-manifesto"'), 'Privacy manifesto container must be present');
assert.ok(html.includes('100% Hoạt động Offline'), 'Pillar 1: 100% Offline must be present');
assert.ok(html.includes('Zero Telemetry &amp; Tracking') || html.includes('Zero Telemetry & Tracking'), 'Pillar 2: Zero Telemetry must be present');
assert.ok(html.includes('Quyền Trợ Năng Minh Bạch'), 'Pillar 3: Accessibility Transparency must be present');
assert.ok(html.includes('AXUIElement'), 'AXUIElement reference must be explicitly mentioned');
assert.ok(html.includes('Zero Keylogging'), 'Zero Keylogging guarantee must be present');
console.log('✅ TC-DIST-004 Passed!\n');

// TC-DIST-005: Gatekeeper Remediation Guide Accordion
console.log('Checking TC-DIST-005: Gatekeeper Remediation Guide Accordion...');
assert.ok(html.includes('<details') && html.includes('<summary'), 'Accessible details/summary accordion must be present');
assert.ok(html.includes('xattr -cr /Applications/FlowSnap.app'), 'Gatekeeper remediation command must be present');
assert.ok(html.includes('Gatekeeper') || html.includes('quarantine'), 'Gatekeeper/quarantine explanation must be present');
console.log('✅ TC-DIST-005 Passed!\n');

// TC-DIST-006: Integration into #download Section & Zero Placeholder
console.log('Checking TC-DIST-006: Integration into #download Section & Zero Placeholder...');
assert.ok(!html.includes('Terminal 1-Click &amp; DMG Hub arriving in <code>US-WEB-028</code>') && !html.includes('Terminal 1-Click & DMG Hub arriving in <code>US-WEB-028</code>'), 'Placeholder box from US-WEB-028 must be completely removed');
assert.ok(html.includes('id="distribution-hub-root"'), 'DistributionHub root container must be present');
console.log('✅ TC-DIST-006 Passed!\n');

console.log('🎉 All Distribution Hub Tests Passed Successfully! (6/6 Test Cases)\n');
