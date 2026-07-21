import { AppColors } from './AppColors';

export class MarkdownLine {
  text: string = '';
  type: string = 'text';
  indent: number = 0;
  calloutType: string = '';
  calloutTitle: string = '';
  calloutBody: string = '';
  codeContent: string = '';
  codeLang: string = '';
  cells: string[] = [];
  tableRowIndex: number = -1;
  anchorId: string = '';
}

function isTableSepLine(text: string): boolean {
  const trimmed = text.trim();
  return trimmed.length > 0 && trimmed.match(/^\|[\s\-:|]+\|?$/) !== null;
}

function classifyTableLine(afterGt: string, ml: MarkdownLine): boolean {
  const trimmed = afterGt.trim();
  if (!trimmed.startsWith('|')) {
    return false;
  }
  if (isTableSepLine(trimmed)) {
    ml.type = 'tableSep';
  } else {
    ml.type = 'table';
    ml.cells = parseTableCells(trimmed);
  }
  ml.text = trimmed;
  return true;
}

export class TocEntry {
  text: string = '';
  level: number = 0;
  anchor: string = '';
}

const ANNOTATION_KEYWORDS: string[] = ['重新审视', '新增', '沿用', 'Carryover', 'Revisited', 'New'];

function isAnnotationQuote(text: string): boolean {
  const boldMatch = text.match(/^\*\*([^*]+)\*\*/);
  if (boldMatch !== null && boldMatch.length > 1) {
    const keyword = boldMatch[1];
    for (const kw of ANNOTATION_KEYWORDS) {
      if (keyword.indexOf(kw) >= 0) {
        return true;
      }
    }
    if (text.length < 40) {
      return true;
    }
  }
  return false;
}

function isKvQuote(text: string): boolean {
  const boldMatch = text.match(/^\*\*([^*]+)\*\*\s*([：:]\s*|\s)/);
  return boldMatch !== null && boldMatch.length > 1 && text.length >= 40;
}

function isTagLine(text: string): boolean {
  const trimmed = text.trim();
  if (trimmed.length === 0) {
    return false;
  }
  const parts = trimmed.split(/\s+/);
  if (parts.length < 2) {
    return false;
  }
  for (const part of parts) {
    if (!part.startsWith('#') || part.length <= 1) {
      return false;
    }
  }
  return true;
}

function stripEmojiPrefix(text: string): string {
  let result = text;
  const emojiPrefixes: string[] = [
    '📋', '📐', '🔗', '🏷️', '🔑', '⚠️', '💡', '📊', '🎯', '📌',
    '❗', '✅', '⭐', '🏠', '📖', '🧠', '💊', '🫀', '🫁', '🩺',
    '🔬', '📈', '📉', '🗂️', '📝', '🔢', '⚖️', '🛡️', '🔍', '⚕️',
    '❓', '❌', '➡️', '⏱️', '🚨', '🆕', '🆗', '🔴', '🟡', '🟢',
    '⚕', '⚡', '🔥', '💎', '🏆', '📎', '🔖', '📱', '💾', '🧪'
  ];
  for (const prefix of emojiPrefixes) {
    if (result.startsWith(prefix)) {
      result = result.substring(prefix.length).trimStart();
      break;
    }
  }
  return result;
}

export function parseKbMarkdown(content: string): MarkdownLine[] {
  const firstPass: MarkdownLine[] = [];
  const lines = content.split('\n');
  let inYaml = false;
  let yamlCount = 0;
  let inCodeBlock = false;
  let codeLang = '';
  let codeLines: string[] = [];
  let inCallout = false;

  for (const line of lines) {
    if (yamlCount < 2 && line.trim() === '---') {
      inYaml = !inYaml;
      yamlCount++;
      continue;
    }
    if (inYaml) {
      continue;
    }

    const trimmedLine = line;

    if (inCodeBlock) {
      if (trimmedLine.trim() === '```') {
        const ml = new MarkdownLine();
        ml.type = 'codeBlock';
        ml.codeContent = codeLines.join('\n');
        ml.codeLang = codeLang;
        firstPass.push(ml);
        inCodeBlock = false;
        codeLang = '';
        codeLines = [];
      } else {
        codeLines.push(trimmedLine);
      }
      continue;
    }

    if (trimmedLine.trim().startsWith('```')) {
      inCodeBlock = true;
      codeLang = trimmedLine.trim().substring(3).trim();
      codeLines = [];
      continue;
    }

    let indent = 0;
    let scanLine = trimmedLine;
    while (scanLine.startsWith('  ') || scanLine.startsWith('\t')) {
      indent++;
      scanLine = scanLine.startsWith('\t') ? scanLine.substring(1) : scanLine.substring(2);
    }

    const ml = new MarkdownLine();
    ml.indent = indent;

    if (scanLine.startsWith('# ')) {
      ml.type = 'h1';
      ml.text = stripEmojiPrefix(scanLine.substring(2));
      inCallout = false;
    } else if (scanLine.startsWith('## ')) {
      ml.type = 'h2';
      ml.text = stripEmojiPrefix(scanLine.substring(3));
      inCallout = false;
    } else if (scanLine.startsWith('### ')) {
      ml.type = 'h3';
      ml.text = stripEmojiPrefix(scanLine.substring(4));
      inCallout = false;
    } else if (scanLine.startsWith('#### ')) {
      ml.type = 'h4';
      ml.text = stripEmojiPrefix(scanLine.substring(5));
      inCallout = false;
    } else if (scanLine.startsWith('> ')) {
      const afterGt = scanLine.substring(2);
      const calloutMatch = afterGt.match(/^\[!(\w+)\]([+-]?)\s*(.*)/);
      if (calloutMatch !== null && calloutMatch.length > 3) {
        ml.type = 'callout-header';
        ml.calloutType = calloutMatch[1].toLowerCase();
        ml.calloutTitle = calloutMatch[3];
        inCallout = true;
      } else if (!inCallout && classifyTableLine(afterGt, ml)) {
        inCallout = false;
      } else if (inCallout) {
        ml.type = 'callout-body';
        ml.text = afterGt;
      } else if (isAnnotationQuote(afterGt)) {
        ml.type = 'annotation';
        ml.text = afterGt;
      } else if (isKvQuote(afterGt)) {
        ml.type = 'kvQuote';
        ml.text = afterGt;
      } else {
        ml.type = 'quote';
        ml.text = afterGt;
      }
    } else if (scanLine.startsWith('>') && scanLine.length > 1 && !scanLine.startsWith('> [')) {
      const afterGt = scanLine.substring(1).trim();
      if (afterGt.startsWith('[!')) {
        const calloutMatch = scanLine.match(/^>\s*\[!(\w+)\]([+-]?)\s*(.*)/);
        if (calloutMatch !== null && calloutMatch.length > 3) {
          ml.type = 'callout-header';
          ml.calloutType = calloutMatch[1].toLowerCase();
          ml.calloutTitle = calloutMatch[3];
          inCallout = true;
        } else {
          ml.type = 'quote';
          ml.text = afterGt;
        }
      } else if (inCallout) {
        ml.type = 'callout-body';
        ml.text = afterGt;
      } else if (isAnnotationQuote(afterGt)) {
        ml.type = 'annotation';
        ml.text = afterGt;
      } else if (isKvQuote(afterGt)) {
        ml.type = 'kvQuote';
        ml.text = afterGt;
      } else {
        ml.type = 'callout-body';
        ml.text = afterGt;
      }
    } else if (scanLine === '>') {
      if (inCallout) {
        ml.type = 'callout-body';
        ml.text = '';
      } else {
        ml.type = 'blank';
      }
    } else if (scanLine.startsWith('- ') || scanLine.startsWith('* ')) {
      ml.type = 'li';
      ml.text = scanLine.substring(2);
      inCallout = false;
    } else if (scanLine.startsWith('---') || scanLine.startsWith('***')) {
      ml.type = 'hr';
      inCallout = false;
    } else if (scanLine.trim().length === 0) {
      ml.type = 'blank';
      inCallout = false;
    } else if (isTagLine(scanLine)) {
      ml.type = 'tagLine';
      ml.text = scanLine;
      inCallout = false;
    } else if (scanLine.startsWith('|')) {
      classifyTableLine(scanLine, ml);
      inCallout = false;
    } else {
      ml.type = 'text';
      ml.text = scanLine;
      inCallout = false;
    }
    firstPass.push(ml);
  }

  if (inCodeBlock && codeLines.length > 0) {
    const ml = new MarkdownLine();
    ml.type = 'codeBlock';
    ml.codeContent = codeLines.join('\n');
    ml.codeLang = codeLang;
    firstPass.push(ml);
  }

  const result: MarkdownLine[] = [];
  let i = 0;
  while (i < firstPass.length) {
    const current = firstPass[i];

    if (current.type === 'callout-header') {
      const merged = new MarkdownLine();
      merged.type = 'callout';
      merged.calloutType = current.calloutType;
      merged.calloutTitle = current.calloutTitle;
      merged.calloutBody = '';
      i++;
      while (i < firstPass.length && firstPass[i].type === 'callout-body') {
        if (merged.calloutBody.length > 0) {
          merged.calloutBody += '\n';
        }
        merged.calloutBody += firstPass[i].text;
        i++;
      }
      result.push(merged);
      continue;
    }

    if (current.type === 'callout-body') {
      const merged = new MarkdownLine();
      merged.type = 'callout';
      merged.calloutType = 'note';
      merged.calloutTitle = '';
      merged.calloutBody = current.text;
      i++;
      while (i < firstPass.length && firstPass[i].type === 'callout-body') {
        if (merged.calloutBody.length > 0) {
          merged.calloutBody += '\n';
        }
        merged.calloutBody += firstPass[i].text;
        i++;
      }
      result.push(merged);
      continue;
    }

    if (current.type === 'table') {
      if (i + 1 < firstPass.length && firstPass[i + 1].type === 'tableSep') {
        const header = new MarkdownLine();
        header.type = 'tableHeader';
        header.text = current.text;
        header.cells = current.cells;
        result.push(header);
        i += 2;
        let rowIdx = 0;
        while (i < firstPass.length && firstPass[i].type === 'table') {
          const row = new MarkdownLine();
          row.type = 'table';
          row.text = firstPass[i].text;
          row.cells = firstPass[i].cells;
          row.tableRowIndex = rowIdx;
          rowIdx++;
          result.push(row);
          i++;
        }
        continue;
      } else {
        const row = new MarkdownLine();
        row.type = 'table';
        row.text = current.text;
        row.cells = current.cells;
        result.push(row);
        i++;
        continue;
      }
    }

    result.push(current);
    i++;
  }

  return result;
}

export function extractTocFromLines(lines: MarkdownLine[]): TocEntry[] {
  const entries: TocEntry[] = [];
  let k = 0;
  for (const ml of lines) {
    if (ml.type === 'h2' || ml.type === 'h3') {
      ml.anchorId = 'kb_toc_' + k.toString();
      const entry = new TocEntry();
      entry.text = stripMarkdownInline(ml.text);
      entry.level = ml.type === 'h2' ? 2 : 3;
      entry.anchor = ml.anchorId;
      entries.push(entry);
      k++;
    }
  }
  return entries;
}

export function stripMarkdownInline(text: string): string {
  let result = text;
  result = result.replace(/==([^=]+)==/g, '$1');
  result = result.replace(/\[\[([^\]|]+)\|([^\]]+)\]\]/g, '$2');
  result = result.replace(/\[\[([^\]]+)\]\]/g, (_match: string, p1: string): string => {
    const name = p1.split('/').pop() || p1;
    return name.replace(/\.md$/, '');
  });
  result = result.replace(/\*\*([^*]+)\*\*/g, '$1');
  result = result.replace(/\*([^*]+)\*/g, '$1');
  result = result.replace(/\[([^\]]+)\]\([^)]+\)/g, '$1');
  result = result.replace(/`([^`]+)`/g, '$1');
  result = result.replace(/~~([^~]+)~~/g, '$1');
  return result;
}

export function stripTableMarkdown(line: string): string {
  return line.replace(/^\|/, '').replace(/\|$/, '').replace(/\|/g, ' \u2502 ');
}

export function parseTableCells(line: string): string[] {
  let stripped = line.replace(/^\|/, '').replace(/\|$/, '');
  const cells: string[] = [];
  const parts = stripped.split('|');
  for (const part of parts) {
    cells.push(stripMarkdownInline(part.trim()));
  }
  return cells;
}

export function getAnnotationBadgeInfo(text: string): AnnotationBadge {
  const boldMatch = text.match(/^\*\*([^*]+)\*\*(.*)/);
  if (boldMatch !== null && boldMatch.length > 2) {
    const keyword = boldMatch[1];
    let color = AppColors.textSecondary;
    if (keyword.indexOf('新增') >= 0 || keyword.indexOf('New') >= 0) {
      color = AppColors.tierOk;
    } else if (keyword.indexOf('重新审视') >= 0 || keyword.indexOf('Revisited') >= 0) {
      color = AppColors.warning;
    } else if (keyword.indexOf('沿用') >= 0 || keyword.indexOf('Carryover') >= 0) {
      color = AppColors.primary;
    }
    const badge = new AnnotationBadge();
    badge.keyword = keyword;
    badge.detail = boldMatch[2].replace(/^[（(]|[）)]$/g, '').replace(/[。.]$/g, '');
    badge.color = color;
    return badge;
  }
  const badge = new AnnotationBadge();
  badge.keyword = text.replace(/\*\*/g, '');
  badge.detail = '';
  badge.color = AppColors.textSecondary;
  return badge;
}

export class AnnotationBadge {
  keyword: string = '';
  detail: string = '';
  color: ResourceStr = AppColors.textSecondary;
}

export function getCalloutStyle(calloutType: string): CalloutStyle {
  switch (calloutType) {
    case 'warning':
      return new CalloutStyle(AppColors.warning, AppColors.tierWarnBg, '\u26A0');
    case 'danger':
      return new CalloutStyle(AppColors.danger, AppColors.tierDangerBg, '\u274C');
    case 'important':
      return new CalloutStyle(AppColors.primary, AppColors.background, '\u2757');
    case 'tip':
      return new CalloutStyle(AppColors.tierOk, AppColors.tierOkBg, '\uD83D\uDCA1');
    case 'note':
      return new CalloutStyle(AppColors.primary, AppColors.background, '\uD83D\uDCDD');
    case 'info':
      return new CalloutStyle(AppColors.primary, AppColors.background, '\u2139');
    case 'abstract':
      return new CalloutStyle(AppColors.primary, AppColors.background, '\uD83D\uDCCB');
    case 'example':
      return new CalloutStyle(AppColors.tierWarn, AppColors.tierWarnBg, '\uD83D\uDCD6');
    case 'success':
      return new CalloutStyle(AppColors.tierOk, AppColors.tierOkBg, '\u2705');
    case 'quote':
      return new CalloutStyle(AppColors.tierWarn, AppColors.tierWarnBg, '\uD83D\uDCAC');
    case 'faq':
      return new CalloutStyle(AppColors.primary, AppColors.background, '\u2753');
    default:
      return new CalloutStyle(AppColors.textSecondary, AppColors.surfaceMuted, '\uD83D\uDCC4');
  }
}

export class CalloutStyle {
  borderColor: ResourceStr = '';
  bgColor: ResourceStr = '';
  icon: string = '';

  constructor(borderColor: ResourceStr, bgColor: ResourceStr, icon: string) {
    this.borderColor = borderColor;
    this.bgColor = bgColor;
    this.icon = icon;
  }
}
