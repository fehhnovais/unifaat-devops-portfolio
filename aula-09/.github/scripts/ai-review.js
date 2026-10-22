#!/usr/bin/env node
/**
 * ai-review.js — Análise estática orientada a IA/regras para revisão de PRs.
 *
 * Lê um diff unificado (git diff) pela entrada padrão OU de um arquivo passado
 * como primeiro argumento, examina apenas as LINHAS ADICIONADAS e reporta
 * problemas categorizados por severidade.
 *
 * Severidades:
 *   CRITICAL -> bloqueia o PR (exit 1)
 *   WARNING  -> apenas alerta
 *   INFO     -> informativo
 *
 * Saída:
 *   - Imprime no stdout um comentário em Markdown (tabela) pronto para postar no PR.
 *   - Grava o mesmo conteúdo em `ai-review-comment.md`.
 *   - Exit code 1 se houver ao menos 1 achado CRITICAL (quality gate).
 *
 * Uso:
 *   node ai-review.js diff.patch
 *   git diff origin/main...HEAD | node ai-review.js
 */

'use strict';

const fs = require('fs');

// ── Catálogo de padrões detectados ───────────────────────────────
// Cada regra inspeciona uma linha adicionada do diff.
const RULES = [
  {
    id: 'secret-hardcoded',
    severity: 'CRITICAL',
    description: 'Possível credencial/secret hardcoded',
    test: (line) =>
      /(aws_secret_access_key|aws_access_key_id|api[_-]?key|secret|password|passwd|token)\s*[:=]\s*['"][^'"]{6,}['"]/i.test(line) ||
      /AKIA[0-9A-Z]{16}/.test(line)
  },
  {
    id: 'eval-usage',
    severity: 'CRITICAL',
    description: 'Uso de eval() — risco de execução de código arbitrário',
    test: (line) => /\beval\s*\(/.test(line)
  },
  {
    id: 'sql-injection',
    severity: 'CRITICAL',
    description: 'Possível SQL injection (concatenação de query com variável)',
    test: (line) =>
      /(select|insert|update|delete)\s+.*(\+\s*\w+|\$\{.*\}|`.*\$\{)/i.test(line) ||
      /query\s*\(\s*['"`].*(\+|\$\{)/i.test(line)
  },
  {
    id: 'child-process',
    severity: 'CRITICAL',
    description: 'Execução de comando do SO (child_process/exec) — validar entrada',
    test: (line) => /\b(exec|execSync|spawn)\s*\(/.test(line) && /child_process|require\(['"]child_process/.test(line) === false && /\bexec\s*\(/.test(line)
  },
  {
    id: 'console-log',
    severity: 'WARNING',
    description: 'console.log em código — remover antes de produção',
    test: (line) => /console\.(log|debug)\s*\(/.test(line)
  },
  {
    id: 'empty-catch',
    severity: 'WARNING',
    description: 'Bloco catch vazio — erros silenciados',
    test: (line) => /catch\s*\([^)]*\)\s*\{\s*\}/.test(line)
  },
  {
    id: 'http-insecure',
    severity: 'WARNING',
    description: 'URL http:// (sem TLS) — preferir https://',
    test: (line) => /['"`]http:\/\/(?!localhost|127\.0\.0\.1)/.test(line)
  },
  {
    id: 'todo-fixme',
    severity: 'INFO',
    description: 'Comentário TODO/FIXME pendente',
    test: (line) => /\/\/\s*(TODO|FIXME|XXX)/i.test(line)
  },
  {
    id: 'var-usage',
    severity: 'INFO',
    description: "Uso de 'var' — preferir const/let",
    test: (line) => /(^|[^.\w])var\s+\w+/.test(line)
  },
  {
    id: 'debugger',
    severity: 'WARNING',
    description: "Instrução 'debugger' esquecida no código",
    test: (line) => /\bdebugger\b\s*;?/.test(line)
  }
];

// ── Parser de diff unificado ─────────────────────────────────────
// Retorna lista de { file, line, content } apenas para linhas adicionadas.
function parseDiff(diff) {
  const added = [];
  let currentFile = null;
  let newLineNo = 0;

  for (const raw of diff.split(/\r?\n/)) {
    if (raw.startsWith('+++ ')) {
      const m = raw.match(/^\+\+\+ b\/(.+)$/);
      currentFile = m ? m[1] : raw.slice(4);
      continue;
    }
    if (raw.startsWith('@@')) {
      // @@ -a,b +c,d @@  -> captura a linha inicial do lado novo
      const m = raw.match(/\+([0-9]+)/);
      newLineNo = m ? parseInt(m[1], 10) : 0;
      continue;
    }
    if (raw.startsWith('+') && !raw.startsWith('+++')) {
      added.push({ file: currentFile, line: newLineNo, content: raw.slice(1) });
      newLineNo++;
    } else if (!raw.startsWith('-')) {
      // linha de contexto avança o contador do lado novo
      newLineNo++;
    }
  }
  return added;
}

// ── Execução das regras ──────────────────────────────────────────
function analyze(addedLines) {
  const findings = [];
  for (const { file, line, content } of addedLines) {
    // ignora arquivos que não são código-fonte
    if (file && /\.(md|lock|json|png|jpg|svg)$/i.test(file)) continue;
    for (const rule of RULES) {
      try {
        if (rule.test(content)) {
          findings.push({
            severity: rule.severity,
            rule: rule.id,
            description: rule.description,
            file: file || '(desconhecido)',
            line,
            snippet: content.trim().slice(0, 80)
          });
        }
      } catch (_) {
        // uma regex ruim não deve derrubar a análise inteira
      }
    }
  }
  return findings;
}

// ── Formatação do comentário ─────────────────────────────────────
function buildComment(findings) {
  const counts = { CRITICAL: 0, WARNING: 0, INFO: 0 };
  findings.forEach((f) => (counts[f.severity] += 1));

  const icon = { CRITICAL: '🔴', WARNING: '🟡', INFO: '🔵' };
  let md = '## 🤖 AI Review — TechNova\n\n';

  if (findings.length === 0) {
    md += '✅ Nenhum problema detectado nas linhas adicionadas. Bom trabalho!\n';
    return md;
  }

  md += `**Resumo:** ${icon.CRITICAL} ${counts.CRITICAL} CRITICAL · `;
  md += `${icon.WARNING} ${counts.WARNING} WARNING · ${icon.INFO} ${counts.INFO} INFO\n\n`;
  md += '| Severidade | Regra | Arquivo:Linha | Descrição |\n';
  md += '|------------|-------|---------------|-----------|\n';

  const order = { CRITICAL: 0, WARNING: 1, INFO: 2 };
  findings
    .sort((a, b) => order[a.severity] - order[b.severity])
    .forEach((f) => {
      md += `| ${icon[f.severity]} ${f.severity} | \`${f.rule}\` | \`${f.file}:${f.line}\` | ${f.description} |\n`;
    });

  md += '\n';
  if (counts.CRITICAL > 0) {
    md += '> ⛔ **Quality gate: BLOQUEADO.** Há achados CRITICAL que precisam ser resolvidos antes do merge.\n';
  } else {
    md += '> ✅ **Quality gate: liberado.** Apenas WARNING/INFO — revise, mas o merge não está bloqueado.\n';
  }
  return md;
}

// ── Main ─────────────────────────────────────────────────────────
function main() {
  const file = process.argv[2];
  let diff = '';
  try {
    diff = file ? fs.readFileSync(file, 'utf8') : fs.readFileSync(0, 'utf8');
  } catch (err) {
    console.error('Não foi possível ler o diff:', err.message);
    process.exit(0); // sem diff, não bloqueia
  }

  const added = parseDiff(diff);
  const findings = analyze(added);
  const comment = buildComment(findings);

  // grava o comentário para o workflow postar no PR
  fs.writeFileSync('ai-review-comment.md', comment);
  console.log(comment);

  const critical = findings.filter((f) => f.severity === 'CRITICAL').length;
  if (critical > 0) {
    console.error(`\nQuality gate falhou: ${critical} achado(s) CRITICAL.`);
    process.exit(1);
  }
  process.exit(0);
}

main();
