// KbTextUtils.ets
// 知识库相关的纯字符串工具。被 KnowledgeIndex（建索引抽取）、KnowledgeSearch（相关页推断）
// 以及 KnowledgeService 门面（getPage、listAllPagesInCategory 解析）共用。
// 沉淀到 utils 层避免两侧互相依赖。

/**
 * 从 Markdown 正文提取 [[wikilink]] 形式的双链目标。
 * 行为与原 KnowledgeService.extractWikilinks 完全一致。
 */
export function extractWikilinks(content: string): string[] {
  const regex = /\[\[([^\]]+)\]\]/g;
  const links: string[] = [];
  let match: RegExpExecArray | null;
  while ((match = regex.exec(content)) !== null) {
    if (match.length > 1) {
      links.push(match[1]);
    }
  }
  return links;
}

/**
 * 从 Markdown frontmatter 提取 title；缺失时回退到首个 H1。
 * 行为与原 KnowledgeService.extractTitle 完全一致。
 */
export function extractTitle(content: string): string {
  const yamlEnd = content.indexOf('---', 3);
  if (yamlEnd > 0) {
    const yaml = content.substring(3, yamlEnd);
    const lines = yaml.split('\n');
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed.startsWith('title:')) {
        return trimmed.substring(6).trim().replace(/^['"]|['"]$/g, '');
      }
    }
  }
  const h1Match = content.match(/^#\s+(.+)$/m);
  if (h1Match !== null && h1Match.length > 1) {
    return h1Match[1];
  }
  return '';
}

/**
 * 从 Markdown frontmatter 拼接 source + date 作为来源信息。
 * 行为与原 KnowledgeService.extractSourceInfo 完全一致。
 */
export function extractSourceInfo(content: string): string {
  const yamlEnd = content.indexOf('---', 3);
  if (yamlEnd <= 0) {
    return '';
  }
  const yaml = content.substring(3, yamlEnd);
  const lines = yaml.split('\n');
  const parts: string[] = [];
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('source:')) {
      parts.push(trimmed.substring(7).trim().replace(/^['"]|['"]$/g, ''));
    } else if (trimmed.startsWith('date:')) {
      parts.push(trimmed.substring(5).trim().replace(/^['"]|['"]$/g, ''));
    }
  }
  return parts.join(' ');
}

/**
 * 从 Markdown frontmatter 提取 tags 数组。
 * 行为与原 KnowledgeService.extractTags 完全一致。
 */
export function extractTags(content: string): string[] {
  const yamlEnd = content.indexOf('---', 3);
  if (yamlEnd <= 0) {
    return [];
  }
  const yaml = content.substring(3, yamlEnd);
  const lines = yaml.split('\n');
  let inTags = false;
  const tags: string[] = [];
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed === 'tags:') {
      inTags = true;
      continue;
    }
    if (inTags) {
      if (trimmed.startsWith('- ')) {
        const tag = trimmed.substring(2).trim().replace(/^['"]|['"]$/g, '');
        if (tag.length > 0) {
          tags.push(tag);
        }
      } else if (!trimmed.startsWith('-') && trimmed.length > 0) {
        break;
      }
    }
  }
  return tags;
}

/**
 * 从 Markdown frontmatter 提取 summary；缺失时回退到首段正文。
 * 行为与原 KnowledgeService.extractSummary 完全一致。
 */
export function extractSummary(content: string): string {
  const yamlEnd = content.indexOf('---', 3);
  if (yamlEnd <= 0) {
    const bodyStart = content.indexOf('\n\n');
    if (bodyStart > 0 && bodyStart + 2 < content.length) {
      const firstPara = content.substring(bodyStart + 2, Math.min(bodyStart + 302, content.length));
      const nextBreak = firstPara.indexOf('\n\n');
      return nextBreak > 0 ? firstPara.substring(0, nextBreak) : firstPara;
    }
    return content.substring(0, Math.min(300, content.length));
  }
  const yaml = content.substring(3, yamlEnd);
  const lines = yaml.split('\n');
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('summary:')) {
      return trimmed.substring(8).trim().replace(/^['"]|['"]$/g, '');
    }
  }
  const bodyStart = content.indexOf('\n\n', yamlEnd + 3);
  if (bodyStart > 0 && bodyStart + 2 < content.length) {
    const firstPara = content.substring(bodyStart + 2, Math.min(bodyStart + 302, content.length));
    const nextBreak = firstPara.indexOf('\n\n');
    return nextBreak > 0 ? firstPara.substring(0, nextBreak) : firstPara;
  }
  return '';
}

/**
 * 从知识库内部路径（kb 根目录之后）拆出关键词，忽略文件名末段与黑名单目录。
 * 行为与原 KnowledgeService.extractPathKeywords 完全一致。
 */
export function extractPathKeywords(path: string): string[] {
  const keywords: string[] = [];
  const parts = path.split('/');
  for (let i = 0; i < parts.length - 1; i++) {
    const part = parts[i];
    if (part.length > 0 && part !== 'NICE' && part !== '机制' && part !== '笔记') {
      keywords.push(part);
    }
  }
  return keywords;
}

/**
 * 根据关键词抽取段落片段用于上下文裁剪。
 * 行为与原 KnowledgeService.excerptContent 完全一致：保留首两段 + 命中段及其邻段，
 * 命中段不足 500 字时退回前 5000 字；总长超 maxChars 时从尾部开始裁段。
 */
export function excerptContent(content: string, keywords: string[], maxChars: number): string {
  const paragraphs: string[] = content.split(/\n\n+/);
  if (paragraphs.length === 0) {
    return content.substring(0, maxChars);
  }
  const mandatoryIndices = new Set<number>();
  if (paragraphs.length > 0) {
    mandatoryIndices.add(0);
  }
  if (paragraphs.length > 1) {
    mandatoryIndices.add(1);
  }
  const hitIndices = new Set<number>();
  for (let i = 0; i < paragraphs.length; i++) {
    for (const kw of keywords) {
      if (kw.length > 0 && paragraphs[i].includes(kw)) {
        hitIndices.add(i);
        if (i > 0) {
          hitIndices.add(i - 1);
        }
        if (i < paragraphs.length - 1) {
          hitIndices.add(i + 1);
        }
        break;
      }
    }
  }
  const selectedIndices = new Set<number>();
  for (const idx of mandatoryIndices) {
    selectedIndices.add(idx);
  }
  for (const idx of hitIndices) {
    selectedIndices.add(idx);
  }
  const sorted: number[] = Array.from(selectedIndices).sort((a: number, b: number): number => a - b);
  const result: string[] = [];
  for (const idx of sorted) {
    result.push(paragraphs[idx]);
  }
  let joined = result.join('\n\n');
  if (joined.length < 500) {
    return content.substring(0, Math.min(5000, content.length));
  }
  while (joined.length > maxChars && result.length > 2) {
    result.pop();
    joined = result.join('\n\n');
  }
  return joined.substring(0, maxChars);
}
