/**
 * Lumen GDD to Executive PDF Generator
 * Uses Marked for Markdown parsing, custom DOM/HTML post-processing for
 * executive Soft Liquid Glass styling, and Headless Chrome via CDP for
 * pixel-perfect PDF rendering with page numbers and running headers.
 */

const fs = require('fs');
const path = require('path');
const { spawn, execSync } = require('child_process');

async function main() {
  console.log('🚀 Starting Lumen GDD PDF Generation...');

  const rootDir = path.resolve(__dirname, '..');
  const gddMdPath = path.join(rootDir, 'docs', 'GDD.md');
  const outputHtmlPath = path.join(rootDir, 'docs', 'GDD.html');
  const outputPdfPath = path.join(rootDir, 'docs', 'Lumen_GDD.pdf');
  const copyPdfPath = path.join(rootDir, 'docs', 'GDD.pdf');

  if (!fs.existsSync(gddMdPath)) {
    console.error(`Error: File ${gddMdPath} not found.`);
    process.exit(1);
  }

  // 1. Convert Markdown to HTML using npx marked
  console.log('📄 Converting Markdown to HTML via marked...');
  const rawHtmlPath = '/tmp/gdd_raw_content.html';
  execSync(`npx --yes marked "${gddMdPath}" -o "${rawHtmlPath}"`);
  let contentHtml = fs.readFileSync(rawHtmlPath, 'utf8');

  // 2. Post-process HTML
  console.log('✨ Enhancing HTML structure, typography and badges...');

  // Remove the initial # Lumen — Game Design Document (GDD) and metadata blockquote from the content body
  // because we render a dedicated, beautiful executive cover page and TOC.
  contentHtml = contentHtml.replace(/<h1>Lumen\s*—\s*Game Design Document \(GDD\)<\/h1>[\s\S]*?<\/blockquote>[\s\S]*?<hr>/i, '');

  // Replace status emojis in tables with rich badge spans
  contentHtml = contentHtml.replace(/<td>\s*✅\s*<\/td>/g, '<td><span class="badge badge-done"><span class="badge-icon">✓</span> Feito</span></td>');
  contentHtml = contentHtml.replace(/<td>\s*🟡\s*<\/td>/g, '<td><span class="badge badge-partial"><span class="badge-icon">◐</span> Parcial</span></td>');
  contentHtml = contentHtml.replace(/<td>\s*❌\s*<\/td>/g, '<td><span class="badge badge-missing"><span class="badge-icon">✕</span> Ausente</span></td>');
  contentHtml = contentHtml.replace(/<td>\s*🔮\s*<\/td>/g, '<td><span class="badge badge-future"><span class="badge-icon">✦</span> Futuro</span></td>');

  // Also replace any standalone emojis in text
  contentHtml = contentHtml.replace(/✅/g, '<span class="status-symbol done">✓</span>');
  contentHtml = contentHtml.replace(/🟡/g, '<span class="status-symbol partial">◐</span>');
  contentHtml = contentHtml.replace(/❌/g, '<span class="status-symbol missing">✕</span>');
  contentHtml = contentHtml.replace(/🔮/g, '<span class="status-symbol future">✦</span>');

  // Style Feature IDs in tables like H01, C01, R01, M01, S01, SM01, HS01, T01, U01, P01, FUT-01, A1, B1, etc.
  contentHtml = contentHtml.replace(/<td>([A-Z]{1,3}\d{1,2}|FUT-\d{2})<\/td>/g, '<td><span class="id-tag">$1</span></td>');

  // Enhance task list checkboxes
  contentHtml = contentHtml.replace(/<li><input checked="" disabled="" type="checkbox">\s*(.*?)<\/li>/g,
    '<li class="task-item completed"><span class="custom-checkbox checked">✓</span><span class="task-text">$1</span></li>');
  contentHtml = contentHtml.replace(/<li><input disabled="" type="checkbox">\s*(.*?)<\/li>/g,
    '<li class="task-item pending"><span class="custom-checkbox"></span><span class="task-text">$1</span></li>');

  // Style priority badges P0, P1, P2
  contentHtml = contentHtml.replace(/<td>P0<\/td>/g, '<td><span class="priority-badge p0">P0 · Crítico</span></td>');
  contentHtml = contentHtml.replace(/<td>P1<\/td>/g, '<td><span class="priority-badge p1">P1 · Alto</span></td>');
  contentHtml = contentHtml.replace(/<td>P2<\/td>/g, '<td><span class="priority-badge p2">P2 · Médio</span></td>');

  // Style personas headers
  contentHtml = contentHtml.replace(/<h3>Persona A — “Marcelo” \(usuário primário atual\)<\/h3>/g,
    '<div class="persona-header"><span class="persona-tag persona-primary">Persona A · Usuário Primário</span><h3>“Marcelo” (Adulto com TDAH, iPhone + Apple Watch)</h3></div>');
  contentHtml = contentHtml.replace(/<h3>Persona B — Terapeuta \/ psiquiatra \(indireto\)<\/h3>/g,
    '<div class="persona-header"><span class="persona-tag persona-clinical">Persona B · Profissional Clínico</span><h3>Terapeuta & Psiquiatra (Consumidor de Dados / Relatórios)</h3></div>');
  contentHtml = contentHtml.replace(/<h3>Persona C — Usuário Android \(secundário\)<\/h3>/g,
    '<div class="persona-header"><span class="persona-tag persona-secondary">Persona C · Usuário Secundário</span><h3>Usuário Android (Health Connect / Standalone)</h3></div>');

  // Style user flows (F1 to F6)
  contentHtml = contentHtml.replace(/<h3>(F\d\s*—\s*.*?)<\/h3>/g, '<div class="flow-header"><span class="flow-badge">Fluxo</span><h3>$1</h3></div>');

  // Wrap Table of Contents in a card
  contentHtml = contentHtml.replace(/<h2>Índice<\/h2>\s*<ol>([\s\S]*?)<\/ol>/i, `
    <div class="toc-container">
      <div class="section-title-wrapper">
        <h2 style="break-before: avoid; margin-top: 0;">Índice do Documento</h2>
      </div>
      <div class="toc-grid">
        <ol class="toc-list">
          $1
        </ol>
      </div>
    </div>
  `);

  // Section numbering / icons for h2
  contentHtml = contentHtml.replace(/<h2>(\d+\.\s*.*?)<\/h2>/g, (match, title) => {
    return `<div class="chapter-header"><h2><span class="chapter-num">${title.split('.')[0]}</span><span class="chapter-title">${title.substring(title.indexOf('.') + 1).trim()}</span></h2></div>`;
  });

  // Construct complete HTML document
  const fullHtml = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<title>Lumen — Game Design Document (GDD)</title>
<style>
/* ==========================================================================
   PAGE SETUP & GEOMETRY
   ========================================================================== */
@page {
  size: A4;
  margin: 22mm 16mm 22mm 16mm;
}
@page :first {
  margin: 0;
}

* {
  box-sizing: border-box;
  -webkit-print-color-adjust: exact;
  print-color-adjust: exact;
}

body {
  margin: 0;
  padding: 0;
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  color: #1E293B;
  background: #FFFFFF;
  line-height: 1.55;
  font-size: 9.5pt;
  letter-spacing: -0.01em;
}

/* ==========================================================================
   COVER PAGE (Full Bleed A4)
   ========================================================================== */
.cover-page {
  box-sizing: border-box;
  padding: 8mm 4mm 4mm 4mm;
  height: 246mm;
  background: linear-gradient(165deg, #FAFDFB 0%, #F0F9F6 50%, #FAF8FE 100%);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  page-break-after: always;
  position: relative;
  overflow: hidden;
}

.cover-page::before {
  content: "";
  position: absolute;
  top: -100px;
  right: -100px;
  width: 400px;
  height: 400px;
  background: radial-gradient(circle, rgba(31, 175, 138, 0.12) 0%, rgba(139, 123, 200, 0.05) 50%, transparent 70%);
  border-radius: 50%;
  pointer-events: none;
}

.cover-top {
  position: relative;
  z-index: 2;
}

.brand-badge-row {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 24px;
}

.brand-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: #E6F7F3;
  color: #147A60;
  border: 1px solid #B4E8DC;
  padding: 6px 14px;
  border-radius: 999px;
  font-size: 8.5pt;
  font-weight: 700;
  letter-spacing: 0.6px;
  text-transform: uppercase;
}

.brand-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #1FAF8A;
  box-shadow: 0 0 6px rgba(31, 175, 138, 0.6);
}

.brand-version-pill {
  background: #FFFFFF;
  color: #64748B;
  border: 1px solid #E2E8F0;
  padding: 6px 12px;
  border-radius: 999px;
  font-size: 8.5pt;
  font-weight: 600;
}

.brand-logo-title {
  display: flex;
  align-items: center;
  gap: 16px;
  margin: 10px 0 14px 0;
}

.brand-icon-svg {
  width: 52px;
  height: 52px;
  flex-shrink: 0;
}

.brand-title {
  font-size: 36pt;
  font-weight: 800;
  color: #0F172A;
  letter-spacing: -2px;
  line-height: 1.05;
}

.brand-subtitle {
  font-size: 13pt;
  font-weight: 700;
  color: #1FAF8A;
  margin: 0 0 16px 0;
  letter-spacing: -0.3px;
  line-height: 1.35;
}

.brand-desc {
  font-size: 10.5pt;
  color: #475569;
  max-width: 620px;
  line-height: 1.65;
  margin: 0 0 16px 0;
}

/* Glass card metadata box */
.executive-card {
  background: rgba(255, 255, 255, 0.85);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(226, 232, 240, 0.9);
  border-radius: 16px;
  padding: 16px 20px;
  box-shadow: 0 4px 12px rgba(15, 23, 42, 0.03);
  margin-bottom: 16px;
}

.meta-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 18px 20px;
}

.meta-item {
  display: flex;
  flex-direction: column;
}

.meta-label {
  font-size: 7.5pt;
  text-transform: uppercase;
  letter-spacing: 0.6px;
  color: #94A3B8;
  font-weight: 700;
  margin-bottom: 4px;
}

.meta-val {
  font-size: 9.5pt;
  font-weight: 600;
  color: #1E293B;
  line-height: 1.3;
}

.meta-val code {
  background: #F1F5F9;
  padding: 1px 6px;
  border-radius: 4px;
  font-size: 8.5pt;
  color: #0F172A;
  border: 1px solid #E2E8F0;
}

.pillars-preview {
  margin-top: 20px;
  padding-top: 18px;
  border-top: 1px solid #EDF2F7;
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 8px;
}

.pillar-box {
  background: #F8FAFC;
  border: 1px solid #E2E8F0;
  border-radius: 10px;
  padding: 8px 10px;
  text-align: center;
}

.pillar-box-title {
  font-size: 8pt;
  font-weight: 700;
  color: #0F172A;
  margin-bottom: 2px;
}

.pillar-box-sub {
  font-size: 6.8pt;
  color: #64748B;
  line-height: 1.2;
}

.palette-section {
  display: flex;
  gap: 12px;
  margin-top: 20px;
}

.palette-swatch {
  flex: 1;
  padding: 10px 14px;
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  font-size: 8pt;
  font-weight: 600;
}

.swatch-teal { background: #E6F7F3; color: #147A60; border: 1px solid #B4E8DC; }
.swatch-lavender { background: #F3F0FA; color: #6B57B2; border: 1px solid #D6CEEC; }
.swatch-coral { background: #FFF3ED; color: #C24D1E; border: 1px solid #FFD3C2; }

.cover-bottom {
  border-top: 1px solid #E2E8F0;
  padding-top: 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 8.5pt;
  color: #64748B;
}

/* ==========================================================================
   CONTENT TYPOGRAPHY & LAYOUT
   ========================================================================== */
.document-content {
  padding-top: 6px;
}

.chapter-header {
  break-before: page;
  margin-top: 0;
  padding-top: 0;
  margin-bottom: 18px;
}

.chapter-header h2 {
  font-size: 16pt;
  font-weight: 800;
  color: #0F172A;
  letter-spacing: -0.5px;
  display: flex;
  align-items: center;
  gap: 12px;
  margin: 0;
  padding-bottom: 10px;
  border-bottom: 2px solid #E2E8F0;
}

.chapter-num {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  background: #E6F7F3;
  color: #147A60;
  border: 1px solid #B4E8DC;
  border-radius: 8px;
  font-size: 11pt;
  font-weight: 800;
  flex-shrink: 0;
}

.chapter-title {
  flex: 1;
}

h3 {
  break-after: avoid;
  font-size: 11.5pt;
  font-weight: 700;
  color: #0F172A;
  margin: 20px 0 10px 0;
  letter-spacing: -0.2px;
}

h4 {
  break-after: avoid;
  font-size: 10pt;
  font-weight: 600;
  color: #334155;
  margin: 14px 0 6px 0;
}

p {
  margin: 0 0 10px 0;
  color: #334155;
}

p strong {
  color: #0F172A;
}

hr {
  border: none;
  border-top: 1px solid #E2E8F0;
  margin: 20px 0;
}

/* ==========================================================================
   TABLE OF CONTENTS (TOC)
   ========================================================================== */
.toc-container {
  background: #F8FAFC;
  border: 1px solid #E2E8F0;
  border-radius: 14px;
  padding: 22px 24px;
  margin-bottom: 28px;
  /* break-after: page; */
}

.toc-container h2 {
  margin-top: 0;
  font-size: 15pt;
  font-weight: 800;
  color: #0F172A;
  border-bottom: 1px solid #E2E8F0;
  padding-bottom: 10px;
  margin-bottom: 16px;
}

.toc-list {
  columns: 2;
  column-gap: 32px;
  padding-left: 20px;
  margin: 0;
}

.toc-list li {
  margin-bottom: 8px;
  font-size: 9pt;
  font-weight: 600;
  color: #334155;
  break-inside: avoid;
}

.toc-list li a {
  color: #147A60;
  text-decoration: none;
}

/* ==========================================================================
   TABLES
   ========================================================================== */
table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  margin: 12px 0 20px 0;
  border: 1px solid #E2E8F0;
  border-radius: 10px;
  overflow: hidden;
  font-size: 8.5pt;
  background: #FFFFFF;
  break-inside: auto;
}

tr {
  break-inside: avoid;
}

th {
  background: #F8FAFC;
  color: #0F172A;
  font-weight: 700;
  font-size: 7.8pt;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  padding: 8px 10px;
  border-bottom: 1.5px solid #CBD5E1;
  text-align: left;
}

td {
  padding: 7px 10px;
  border-bottom: 1px solid #F1F5F9;
  color: #334155;
  vertical-align: top;
  line-height: 1.45;
}

tbody tr:last-child td {
  border-bottom: none;
}

tbody tr:nth-child(even) {
  background-color: #FAFCFE;
}

/* ==========================================================================
   BADGES & LABELS
   ========================================================================== */
.badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2.5px 8px;
  border-radius: 999px;
  font-size: 7.5pt;
  font-weight: 700;
  letter-spacing: 0.2px;
  white-space: nowrap;
}

.badge-icon {
  font-size: 7.5pt;
  font-weight: 800;
}

.badge-done {
  background: #E6F7F3;
  color: #0E7058;
  border: 1px solid #B4E8DC;
}

.badge-partial {
  background: #FEF3C7;
  color: #92400E;
  border: 1px solid #FDE68A;
}

.badge-missing {
  background: #FFE4E6;
  color: #9F1239;
  border: 1px solid #FECDD3;
}

.badge-future {
  background: #F3F0FA;
  color: #6B57B2;
  border: 1px solid #D6CEEC;
}

.id-tag {
  display: inline-block;
  background: #F1F5F9;
  color: #0F172A;
  font-family: "SF Mono", Menlo, Consolas, Monaco, monospace;
  font-size: 8pt;
  font-weight: 700;
  padding: 1.5px 6px;
  border-radius: 5px;
  border: 1px solid #E2E8F0;
}

.priority-badge {
  display: inline-block;
  padding: 2px 7px;
  border-radius: 6px;
  font-size: 7.5pt;
  font-weight: 700;
}

.priority-badge.p0 { background: #FEE2E2; color: #991B1B; border: 1px solid #FCA5A5; }
.priority-badge.p1 { background: #FEF3C7; color: #92400E; border: 1px solid #FCD34D; }
.priority-badge.p2 { background: #E0F2FE; color: #075985; border: 1px solid #BAE6FD; }

.status-symbol {
  font-weight: 800;
}
.status-symbol.done { color: #1FAF8A; }
.status-symbol.partial { color: #D97706; }
.status-symbol.missing { color: #E11D48; }
.status-symbol.future { color: #8B7BC8; }

/* ==========================================================================
   BLOCKQUOTES & CALLOUTS
   ========================================================================== */
blockquote {
  background: #F8FAFC;
  border-left: 4px solid #1FAF8A;
  padding: 12px 16px;
  margin: 14px 0;
  border-radius: 0 10px 10px 0;
  color: #334155;
  font-size: 9pt;
  border-top: 1px solid #E2E8F0;
  border-right: 1px solid #E2E8F0;
  border-bottom: 1px solid #E2E8F0;
  break-inside: avoid;
}

blockquote p {
  margin: 0;
}

/* ==========================================================================
   CODE & PRE
   ========================================================================== */
pre {
  background: #0F172A;
  color: #E2E8F0;
  font-family: "SF Mono", Menlo, Consolas, Monaco, monospace;
  font-size: 8.2pt;
  line-height: 1.45;
  padding: 12px 16px;
  border-radius: 10px;
  margin: 12px 0;
  overflow-x: auto;
  border: 1px solid #1E293B;
  break-inside: avoid;
}

code {
  font-family: "SF Mono", Menlo, Consolas, Monaco, monospace;
  font-size: 8pt;
  background: #F1F5F9;
  color: #0F172A;
  padding: 1px 5px;
  border-radius: 4px;
  border: 1px solid #E2E8F0;
}

pre code {
  background: transparent;
  color: inherit;
  padding: 0;
  border: none;
  font-size: inherit;
}

/* ==========================================================================
   TASK LISTS & CHECKBOXES
   ========================================================================== */
ul {
  padding-left: 20px;
  margin: 8px 0;
}

li {
  margin-bottom: 4px;
}

.task-item {
  list-style: none;
  display: flex;
  align-items: flex-start;
  gap: 8px;
  margin-left: -20px;
  margin-bottom: 6px;
  font-size: 9pt;
}

.custom-checkbox {
  width: 14px;
  height: 14px;
  border-radius: 4px;
  border: 1.5px solid #CBD5E1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 9pt;
  margin-top: 2px;
  flex-shrink: 0;
  background: #FFFFFF;
}

.custom-checkbox.checked {
  background: #1FAF8A;
  border-color: #1FAF8A;
  color: #FFFFFF;
  font-weight: 800;
}

.task-item.completed .task-text {
  color: #334155;
}

.task-item.pending .task-text {
  color: #64748B;
}

/* ==========================================================================
   PERSONAS & USER FLOWS
   ========================================================================== */
.persona-header {
  margin-top: 18px;
  margin-bottom: 8px;
  break-after: avoid;
}

.persona-tag {
  display: inline-block;
  font-size: 7.5pt;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  padding: 2px 8px;
  border-radius: 999px;
  margin-bottom: 4px;
}

.persona-primary { background: #E6F7F3; color: #147A60; border: 1px solid #B4E8DC; }
.persona-clinical { background: #F3F0FA; color: #6B57B2; border: 1px solid #D6CEEC; }
.persona-secondary { background: #E0F2FE; color: #0369A1; border: 1px solid #BAE6FD; }

.persona-header h3 {
  margin-top: 2px;
  margin-bottom: 4px;
}

.flow-header {
  margin-top: 16px;
  margin-bottom: 4px;
  display: flex;
  align-items: center;
  gap: 8px;
  break-after: avoid;
}

.flow-badge {
  background: #0F172A;
  color: #FFFFFF;
  font-size: 7pt;
  font-weight: 700;
  text-transform: uppercase;
  padding: 2px 6px;
  border-radius: 4px;
  letter-spacing: 0.5px;
}

.flow-header h3 {
  margin: 0;
  font-size: 10.5pt;
}

</style>
</head>
<body>

<!-- COVER PAGE -->
<div class="cover-page">
  <div class="cover-top">
    <div class="brand-badge-row">
      <div class="brand-pill">
        <span class="brand-dot"></span> Game Design Document (GDD)
      </div>
      <div class="brand-version-pill">
        Documento de Produto & Engenharia · v1.0
      </div>
    </div>

    <div class="brand-logo-title">
      <!-- Custom SVG Logo: Glowing lens ring in Teal/Lavender -->
      <svg class="brand-icon-svg" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
        <circle cx="50" cy="50" r="46" stroke="url(#lumen_grad)" stroke-width="8" stroke-linecap="round" stroke-dasharray="210 40"/>
        <circle cx="50" cy="50" r="28" fill="url(#lumen_inner)" opacity="0.9"/>
        <circle cx="50" cy="50" r="12" fill="#FFFFFF"/>
        <defs>
          <linearGradient id="lumen_grad" x1="0" y1="0" x2="100" y2="100" gradientUnits="userSpaceOnUse">
            <stop stop-color="#1FAF8A"/>
            <stop offset="0.6" stop-color="#8B7BC8"/>
            <stop offset="1" stop-color="#FF8A5C"/>
          </linearGradient>
          <linearGradient id="lumen_inner" x1="20" y1="20" x2="80" y2="80" gradientUnits="userSpaceOnUse">
            <stop stop-color="#1FAF8A"/>
            <stop offset="1" stop-color="#8B7BC8"/>
          </linearGradient>
        </defs>
      </svg>
      <div>
        <div class="brand-title">Lumen</div>
      </div>
    </div>

    <div class="brand-subtitle">Companion Offline-First para TDAH & Saúde Integrada</div>
    <div class="brand-desc">
      Especificação técnica de produto, arquitetura de software Flutter, design system <em>Soft Liquid Glass</em>,
      fluxos cognitivos de baixa fricção, assistência Des-Trava anti-paralisia executiva e integração com Apple Health / Health Connect.
    </div>

    <!-- Metadata Grid Card -->
    <div class="executive-card">
      <div class="meta-grid">
        <div class="meta-item">
          <span class="meta-label">Versão do Documento</span>
          <span class="meta-val">1.0 — Oficial</span>
        </div>
        <div class="meta-item">
          <span class="meta-label">Data de Emissão</span>
          <span class="meta-val">24 de Setembro de 2026</span>
        </div>
        <div class="meta-item">
          <span class="meta-label">Stack Tecnológica</span>
          <span class="meta-val">Flutter · Riverpod · HealthKit</span>
        </div>
        <div class="meta-item">
          <span class="meta-label">App Identifier / Android</span>
          <span class="meta-val"><code>dev.prism.lumen</code> (package <code>noa</code>)</span>
        </div>
        <div class="meta-item">
          <span class="meta-label">Plataformas-Alvo</span>
          <span class="meta-val">iOS (primário), Android, Web</span>
        </div>
        <div class="meta-item">
          <span class="meta-label">Estado de Desenvolvimento</span>
          <span class="meta-val">Fase 0 Concluída (MVP Operacional)</span>
        </div>
      </div>

      <!-- 6 Pillars preview -->
      <div class="pillars-preview">
        <div class="pillar-box">
          <div class="pillar-box-title">Micro Check-in</div>
          <div class="pillar-box-sub">Humor & Foco ~10s</div>
        </div>
        <div class="pillar-box">
          <div class="pillar-box-title">Rotina do Dia</div>
          <div class="pillar-box-sub">Âncora & Hábitos</div>
        </div>
        <div class="pillar-box">
          <div class="pillar-box-title">Medicação</div>
          <div class="pillar-box-sub">Janela de Eficácia</div>
        </div>
        <div class="pillar-box">
          <div class="pillar-box-title">Des-Trava</div>
          <div class="pillar-box-sub">3 Micro-passos</div>
        </div>
        <div class="pillar-box">
          <div class="pillar-box-title">Sono & Biometria</div>
          <div class="pillar-box-sub">Apple HealthKit</div>
        </div>
        <div class="pillar-box">
          <div class="pillar-box-title">Hub Clínico</div>
          <div class="pillar-box-sub">Export p/ Terapia</div>
        </div>
      </div>

      <!-- Design Palette -->
      <div class="palette-section">
        <div class="palette-swatch swatch-teal">
          <span>Teal Primário (Identidade & Ações)</span>
          <code>#1FAF8A</code>
        </div>
        <div class="palette-swatch swatch-lavender">
          <span>Lavanda Acento (Sono & State of Mind)</span>
          <code>#8B7BC8</code>
        </div>
        <div class="palette-swatch swatch-coral">
          <span>Coral Ação (Des-Trava Anti-paralisia)</span>
          <code>#FF8A5C</code>
        </div>
      </div>
    </div>
  </div>

  <div class="cover-bottom">
    <span>Documento de Especificação de Produto & Engenharia · Lumen Health</span>
    <span>Sem gamificação punitiva · Baixa fricção cognitiva · Sem culpa</span>
  </div>
</div>

<!-- DOCUMENT BODY -->
<div class="document-content">
${contentHtml}
</div>

</body>
</html>
`;

  // 3. Write intermediate HTML
  fs.writeFileSync(outputHtmlPath, fullHtml, 'utf8');
  console.log(`💾 HTML saved to ${outputHtmlPath} (${(fullHtml.length / 1024).toFixed(1)} KB)`);

  // 4. Launch Headless Chrome with CDP for high-res PDF generation
  console.log('🖨️ Launching Headless Chrome via CDP...');
  const port = 9226;
  const chromePath = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--disable-gpu',
    `--remote-debugging-port=${port}`
  ]);

  let versionData = null;
  for (let i = 0; i < 25; i++) {
    try {
      const res = await fetch(`http://127.0.0.1:${port}/json/version`);
      versionData = await res.json();
      break;
    } catch (e) {
      await new Promise(r => setTimeout(r, 200));
    }
  }

  if (!versionData) {
    chrome.kill();
    throw new Error('Failed to connect to Headless Chrome remote debugging port.');
  }

  const ws = new WebSocket(versionData.webSocketDebuggerUrl);
  let msgId = 1;
  const callbacks = new Map();

  function send(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = msgId++;
      callbacks.set(id, { resolve, reject });
      ws.send(JSON.stringify({ id, method, params }));
    });
  }

  ws.onmessage = (event) => {
    const msg = JSON.parse(event.data);
    if (msg.id && callbacks.has(msg.id)) {
      const { resolve, reject } = callbacks.get(msg.id);
      callbacks.delete(msg.id);
      if (msg.error) reject(msg.error);
      else resolve(msg.result);
    }
  };

  await new Promise(r => ws.onopen = r);

  const { targetId } = await send('Target.createTarget', { url: 'about:blank' });
  const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });

  function sendSession(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = msgId++;
      callbacks.set(id, { resolve, reject });
      ws.send(JSON.stringify({ id, sessionId, method, params }));
    });
  }

  await sendSession('Page.enable');
  await sendSession('Page.navigate', { url: `file://${outputHtmlPath}` });

  await new Promise(resolve => {
    const orig = ws.onmessage;
    ws.onmessage = (e) => {
      orig(e);
      const m = JSON.parse(e.data);
      if (m.method === 'Page.loadEventFired') resolve();
    };
  });

  // Give fonts and styles a brief moment to stabilize
  await new Promise(r => setTimeout(r, 600));

  console.log('📑 Rendering print layout and PDF...');
  const headerTemplate = `
    <div style="font-size: 7.5pt; width: 100%; margin: 0 16mm; display: flex; justify-content: space-between; align-items: center; color: #94A3B8; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; border-bottom: 1px solid #E2E8F0; padding-bottom: 4px;">
      <span style="font-weight: 700; color: #1FAF8A; letter-spacing: 0.3px;">Lumen — Game Design Document (GDD)</span>
      <span>v1.0 · Setembro 2026</span>
    </div>
  `;

  const footerTemplate = `
    <div style="font-size: 7.5pt; width: 100%; margin: 0 16mm; display: flex; justify-content: space-between; align-items: center; color: #94A3B8; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; border-top: 1px solid #E2E8F0; padding-top: 4px;">
      <span>Companion TDAH Offline-First · Apple Health</span>
      <span>Página <span class="pageNumber"></span> de <span class="totalPages"></span></span>
    </div>
  `;

  const pdfResult = await sendSession('Page.printToPDF', {
    printBackground: true,
    preferCSSPageSize: true,
    displayHeaderFooter: true,
    headerTemplate,
    footerTemplate,
    marginTop: 0.75,
    marginBottom: 0.75,
    marginLeft: 0.65,
    marginRight: 0.65
  });

  const pdfBuffer = Buffer.from(pdfResult.data, 'base64');
  fs.writeFileSync(outputPdfPath, pdfBuffer);
  fs.copyFileSync(outputPdfPath, copyPdfPath);

  console.log(`✅ Success! Generated PDF:`);
  console.log(`   - ${outputPdfPath} (${(pdfBuffer.length / 1024).toFixed(1)} KB)`);
  console.log(`   - ${copyPdfPath}`);

  chrome.kill();
  process.exit(0);
}

main().catch(err => {
  console.error('❌ Error during PDF generation:', err);
  process.exit(1);
});
