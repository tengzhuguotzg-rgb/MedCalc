import { KnowledgeService, SearchResult, KnowledgePage, KnowledgeDirEntry, GroupedPageEntry } from '../services/KnowledgeService';
import {
  MarkdownLine, TocEntry, CalloutStyle, AnnotationBadge,
  parseKbMarkdown, extractToc, extractTocFromLines, stripMarkdownInline, stripTableMarkdown, getCalloutStyle, getAnnotationBadgeInfo, parseTableCells
} from '../utils/KbMarkdownParser';
import { AppColors } from '../utils/AppColors';
import { AppDimens } from '../utils/AppDimens';
import { componentUtils } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

interface CrumbItem {
  label: string;
  targetPath: string;
  clickable: boolean;
}

@Component
export struct KnowledgeSearchPage {
  onNavDepthChanged: (depth: number) => void = () => {};
  @Watch('onBackAction') @Prop backAction: number = 0;
  private lastBackAction: number = 0;
  @Watch('onKbNavigate') @StorageProp('kbNavigatePath') kbNavigatePath: string = '';
  @State searchKeyword: string = '';
  @State searchResults: SearchResult[] = [];
  @State dirEntries: KnowledgeDirEntry[] = [];
  @State groupedPages: GroupedPageEntry[] = [];
  @State currentCategoryName: string = '';
  @Watch('notifyNavDepth') @State readingPage: KnowledgePage | null = null;
  @State readingPath: string = '';
  @State pageNavStack: string[] = [];
  @State relatedPages: SearchResult[] = [];
  @State isSearching: boolean = false;
  @State isPageLoading: boolean = false;
  @State isLoadingCategory: boolean = false;
  @State isKbIniting: boolean = true;
  @Watch('notifyNavDepth') @State browseMode: string = 'root';
  @State markdownLines: MarkdownLine[] = [];
  @State wikilinks: string[] = [];
  @State tocEntries: TocEntry[] = [];
  @State showToc: boolean = false;

  private kbService: KnowledgeService = KnowledgeService.getInstance();
  private pageScroller: Scroller = new Scroller();

  aboutToAppear() {
    this.waitForInit();
  }

  getNavDepth(): number {
    let depth = 0;
    if (this.browseMode === 'category') {
      depth = 1;
    }
    if (this.readingPage !== null) {
      depth = 2;
    }
    return depth;
  }

  notifyNavDepth() {
    this.onNavDepthChanged(this.getNavDepth());
  }

  onBackAction() {
    if (this.backAction !== this.lastBackAction) {
      this.lastBackAction = this.backAction;
      this.navigateBack();
    }
  }

  onKbNavigate() {
    if (this.kbNavigatePath.length > 0) {
      const path = this.kbNavigatePath;
      AppStorage.setOrCreate<string>('kbNavigatePath', '');
      this.openPage(path);
    }
  }

  navigateBack(): boolean {
    if (this.readingPage !== null) {
      this.closeReader();
      this.notifyNavDepth();
      return true;
    }
    if (this.browseMode === 'category') {
      this.browseMode = 'root';
      this.groupedPages = [];
      this.currentCategoryName = '';
      this.notifyNavDepth();
      return true;
    }
    return false;
  }

  async waitForInit() {
    if (!this.kbService.isReady()) {
      const ctx = AppStorage.get<Context>('context');
      if (ctx !== undefined) {
        await this.kbService.init(ctx);
      }
    }
    this.isKbIniting = false;
    await this.loadDirEntries('');
  }

  async loadDirEntries(parentPath: string) {
    this.dirEntries = await this.kbService.listDirEntries(parentPath);
  }

  async loadCategoryPages(categoryPath: string) {
    this.isLoadingCategory = true;
    this.groupedPages = await this.kbService.listAllPagesInCategory(categoryPath);
    this.currentCategoryName = categoryPath.split('/').pop() || categoryPath;
    this.browseMode = 'category';
    this.isLoadingCategory = false;
  }

  async doSearch() {
    const kw = this.searchKeyword.trim();
    if (kw.length === 0) {
      this.searchResults = [];
      this.browseMode = 'root';
      return;
    }
    this.isSearching = true;
    this.browseMode = 'search';
    try {
      this.searchResults = await this.kbService.searchWithSnippets(kw, 20);
    } catch (_e) {
      this.searchResults = [];
    }
    this.isSearching = false;
  }

  clearSearch() {
    this.searchKeyword = '';
    this.searchResults = [];
    this.browseMode = 'root';
  }

  searchByTag(tag: string) {
    this.readingPage = null;
    this.readingPath = '';
    this.pageNavStack = [];
    this.markdownLines = [];
    this.wikilinks = [];
    this.tocEntries = [];
    this.relatedPages = [];
    this.showToc = false;
    this.searchKeyword = tag;
    this.notifyNavDepth();
    this.doSearch();
  }

  async openPage(path: string) {
    this.isPageLoading = true;
    const page = await this.kbService.getPage(path);
    if (page !== null) {
      if (this.readingPath.length > 0) {
        this.pageNavStack = [...this.pageNavStack, this.readingPath];
      }
      this.readingPage = page;
      this.readingPath = path;
      this.markdownLines = parseKbMarkdown(page.content);
      this.wikilinks = this.kbService.extractWikilinks(page.content);
      this.tocEntries = extractTocFromLines(this.markdownLines);
      this.showToc = false;
      this.relatedPages = await this.kbService.getRelatedPages(path, 5);
    }
    this.isPageLoading = false;
  }

  closeReader() {
    if (this.pageNavStack.length > 0) {
      const prevPath = this.pageNavStack[this.pageNavStack.length - 1];
      this.pageNavStack = this.pageNavStack.slice(0, this.pageNavStack.length - 1);
      this.kbService.getPage(prevPath).then((p: KnowledgePage | null) => {
        if (p !== null) {
          this.readingPage = p;
          this.readingPath = prevPath;
          this.markdownLines = parseKbMarkdown(p.content);
          this.wikilinks = this.kbService.extractWikilinks(p.content);
          this.tocEntries = extractTocFromLines(this.markdownLines);
        }
      });
    } else {
      this.readingPage = null;
      this.readingPath = '';
      this.markdownLines = [];
      this.wikilinks = [];
      this.tocEntries = [];
      this.relatedPages = [];
    }
  }

  handleCategoryClick(entry: KnowledgeDirEntry) {
    if (entry.isDir) {
      this.loadCategoryPages(entry.path);
    } else {
      this.openPage(entry.path.endsWith('.md') ? entry.path : entry.path + '.md');
    }
  }

  handleWikilinkClick(link: string) {
    let resolvedPath = link;
    const pipeIdx = resolvedPath.indexOf('|');
    if (pipeIdx >= 0) {
      resolvedPath = resolvedPath.substring(0, pipeIdx);
    }
    if (!resolvedPath.endsWith('.md')) {
      resolvedPath = resolvedPath + '.md';
    }
    this.openPage(resolvedPath);
  }

  getCategoryColor(name: string): ResourceStr {
    const colors: ResourceStr[] = [AppColors.primary, AppColors.kbDeepGreen, AppColors.textSecondary, AppColors.kbWarmBrown];
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = (hash * 31 + name.charCodeAt(i)) % colors.length;
    }
    return colors[hash % colors.length];
  }

  getEntryLabel(entry: KnowledgeDirEntry): string {
    let base = entry.name.replace(/\.md$/, '');
    if (base.toLowerCase() === 'index') {
      base = entry.parentPath.split('/').pop() || '索';
    }
    if (base.length === 0) {
      return '?';
    }
    const first = base.charAt(0);
    let sameFirst = 0;
    for (const other of this.dirEntries) {
      let otherBase = other.name.replace(/\.md$/, '');
      if (otherBase.toLowerCase() === 'index') {
        otherBase = other.parentPath.split('/').pop() || '索';
      }
      if (otherBase.length > 0 && otherBase.charAt(0) === first) {
        sameFirst++;
      }
    }
    // 首字重名时用前两字提高辨识度
    return sameFirst > 1 && base.length > 1 ? base.substring(0, 2) : first;
  }

  getSearchResultTitle(sr: SearchResult): string {
    if (sr.title.length > 0) {
      return sr.title;
    }
    return sr.path.split('/').pop()?.replace(/\.md$/, '') || sr.path;
  }

  getPageTitle(): string {
    if (this.readingPage !== null && this.readingPage.title.length > 0) {
      return this.readingPage.title;
    }
    const parts = this.readingPath.split('/');
    let name = parts[parts.length - 1].replace(/\.md$/, '');
    if (name.toLowerCase() === 'index' && parts.length > 1) {
      name = parts[parts.length - 2];
    }
    return name;
  }

  getBreadcrumb(): string[] {
    if (this.readingPath.length === 0) {
      return [];
    }
    return this.readingPath.split('/');
  }

  getBreadcrumbItems(): CrumbItem[] {
    const parts = this.getBreadcrumb();
    const items: CrumbItem[] = [];
    for (let i = 0; i < parts.length; i++) {
      let label = parts[i].replace(/\.md$/, '');
      if (label.toLowerCase() === 'index' && i > 0) {
        label = parts[i - 1].replace(/\.md$/, '');
      }
      items.push({
        label: label,
        targetPath: parts.slice(0, i + 1).join('/'),
        clickable: i < parts.length - 1
      });
    }
    // 父子同名时折叠为一个（保留靠后的当前级）
    const deduped: CrumbItem[] = [];
    for (const item of items) {
      if (deduped.length > 0 && deduped[deduped.length - 1].label === item.label) {
        deduped.pop();
      }
      deduped.push(item);
    }
    return deduped;
  }

  getWikilinkDisplayName(link: string): string {
    const pipeIdx = link.indexOf('|');
    if (pipeIdx >= 0) {
      return link.substring(pipeIdx + 1);
    }
    const name = link.split('/').pop() || link;
    return name.replace(/\.md$/, '');
  }

  getGroupedPageGroups(): string[] {
    const groups: string[] = [];
    for (const page of this.groupedPages) {
      if (groups.indexOf(page.groupName) < 0) {
        groups.push(page.groupName);
      }
    }
    return groups;
  }

  getPagesForGroup(groupName: string): GroupedPageEntry[] {
    const result: GroupedPageEntry[] = [];
    for (const page of this.groupedPages) {
      if (page.groupName === groupName) {
        result.push(page);
      }
    }
    return result;
  }

  getGroupSourceInfo(groupName: string): string {
    for (const page of this.groupedPages) {
      if (page.groupName === groupName && page.sourceInfo.length > 0) {
        return page.sourceInfo;
      }
    }
    return '';
  }

  build() {
    Column() {
      if (this.readingPage !== null) {
        this.ReaderView();
      } else {
        this.MainView();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.background);
  }

  @Builder
  MainView() {
    Column() {
      this.SearchBar();

      if (this.browseMode === 'search' && this.searchKeyword.trim().length > 0) {
        this.SearchResultsView();
      } else if (this.browseMode === 'category') {
        this.CategoryPageView();
      } else {
        this.RootBrowseView();
      }
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  SearchBar() {
    Row() {
      Search({ value: this.searchKeyword, placeholder: $r('app.string.kb_search_placeholder') })
        .width('100%')
        .searchButton($r('app.string.kb_search_btn'))
        .onChange((value: string) => {
          this.searchKeyword = value;
          if (value.trim().length === 0) {
            this.browseMode = 'root';
            this.searchResults = [];
          }
        })
        .onSubmit(() => { this.doSearch(); })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 4 })
    .backgroundColor(AppColors.card);
  }

  @Builder
  SearchResultsView() {
    if (this.isSearching) {
      Column() {
        LoadingProgress().width(36).height(36).color(AppColors.textSecondary);
        Text($r('app.string.kb_searching_status'))
          .fontSize(13)
          .fontColor(AppColors.textSecondary)
          .margin({ top: 8 });
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center);
    } else if (this.searchResults.length === 0) {
      Column() {
         Text($r('app.string.kb_no_results'))
          .fontSize(15)
          .fontColor(AppColors.textSecondary);
         Text($r('app.string.kb_no_results_hint'))
          .fontSize(12)
          .fontColor(AppColors.textFaint)
          .margin({ top: 6 });
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center);
    } else {
      Column() {
        Text('找到 ' + this.searchResults.length + ' 条结果')
          .fontSize(12)
          .fontColor(AppColors.textSecondary)
          .width('100%')
          .padding({ left: 16, top: 8, bottom: 4 });

        Scroll() {
          Column() {
            ForEach(this.searchResults, (sr: SearchResult) => {
              this.SearchResultCard(sr);
            }, (sr: SearchResult) => sr.path);
          }
          .padding({ left: 12, right: 12, bottom: 12 });
        }
        .layoutWeight(1);
      }
      .layoutWeight(1);
    }
  }

  @Builder
  SearchResultCard(sr: SearchResult) {
    Column() {
      Row() {
        Text(this.getPathCategory(sr.path))
          .fontSize(10)
          .fontColor(AppColors.onPrimary)
          .backgroundColor(AppColors.textSecondary)
          .borderRadius(3)
          .padding({ left: 5, right: 5, top: 1, bottom: 1 });
        if (sr.sourceInfo.length > 0) {
          Text(sr.sourceInfo)
            .fontSize(10)
            .fontColor(AppColors.textSecondary)
            .maxLines(1)
            .margin({ left: 6 })
            .layoutWeight(1);
        }
        Blank();
      }
      .width('100%')
      .margin({ bottom: 4 });

      Text(this.getSearchResultTitle(sr))
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.primary)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%');

      if (sr.snippet.length > 0) {
        Text(stripMarkdownInline(sr.snippet))
          .fontSize(12)
          .fontColor(AppColors.textSecondary)
          .maxLines(3)
          .margin({ top: 4 })
          .width('100%');
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.card)
    .borderRadius(10)
    .margin({ bottom: 8 })
    .shadow({ radius: 1, color: '#1A000000', offsetY: 1 })
    .onClick(() => { this.openPage(sr.path); });
  }

  getPathCategory(path: string): string {
    const parts = path.split('/');
    return parts.length > 0 ? parts[0] : '';
  }

  @Builder
  RootBrowseView() {
    if (this.isKbIniting) {
      Column() {
        LoadingProgress().width(36).height(36).color(AppColors.textSecondary);
        Text($r('app.string.kb_initing'))
          .fontSize(13)
          .fontColor(AppColors.textSecondary)
          .margin({ top: 8 });
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center);
    } else if (this.dirEntries.length === 0) {
      Column() {
         Text($r('app.string.kb_empty'))
          .fontSize(15)
          .fontColor(AppColors.textSecondary);
         Text($r('app.string.kb_empty_hint'))
          .fontSize(12)
          .fontColor(AppColors.textFaint)
          .margin({ top: 6 });
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center);
    } else {
      Scroll() {
        Column() {
          this.CategoryGrid();
        }
        .padding({ left: 12, right: 12, top: 4, bottom: 12 });
      }
      .layoutWeight(1);
    }
  }

  @Builder
  CategoryGrid() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
      ForEach(this.dirEntries, (entry: KnowledgeDirEntry) => {
        this.CategoryCard(entry);
      }, (entry: KnowledgeDirEntry) => entry.path);
    }
    .width('100%');
  }

  @Builder
  CategoryCard(entry: KnowledgeDirEntry) {
    Column() {
      Text(this.getEntryLabel(entry))
        .fontSize(this.getEntryLabel(entry).length > 1 ? 16 : 22)
        .fontColor(AppColors.background)
        .fontWeight(FontWeight.Bold)
        .width(44)
        .height(AppDimens.touchTarget)
        .borderRadius(10)
        .backgroundColor(this.getCategoryColor(entry.name))
        .textAlign(TextAlign.Center);
      Text(entry.name)
        .fontSize(12)
        .fontColor(AppColors.primary)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })
        .width('100%')
        .textAlign(TextAlign.Center);
    }
    .width('23%')
    .margin({ right: '2%', bottom: 12 })
    .padding({ top: 8, bottom: 8 })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.handleCategoryClick(entry); });
  }

  @Builder
  CategoryPageView() {
    Column() {
      Row() {
        Text('\u2190')
          .fontSize(20)
          .fontColor(AppColors.primary)
          .padding({ right: 12 })
          .onClick(() => {
            this.browseMode = 'root';
            this.groupedPages = [];
            this.currentCategoryName = '';
          });
        Text(this.currentCategoryName)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .layoutWeight(1);
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor(AppColors.card);

      if (this.isLoadingCategory) {
        Column() {
          LoadingProgress().width(36).height(36).color(AppColors.textSecondary);
           Text($r('app.string.kb_loading'))
            .fontSize(13)
            .fontColor(AppColors.textSecondary)
            .margin({ top: 8 });
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else {
        Scroll() {
          Column() {
            ForEach(this.getGroupedPageGroups(), (groupName: string) => {
              this.PageGroupSection(groupName);
            }, (groupName: string) => groupName);
          }
          .padding({ left: 12, right: 12, top: 4, bottom: 12 });
        }
        .layoutWeight(1);
      }
    }
    .layoutWeight(1);
  }

  @Builder
  PageGroupSection(groupName: string) {
    Column() {
      Row() {
        if (groupName.length > 0) {
          Text(groupName)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.onPrimary)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(4)
            .backgroundColor(this.getCategoryColor(this.currentCategoryName + '/' + groupName));
          if (this.getGroupSourceInfo(groupName).length > 0) {
            Text(this.getGroupSourceInfo(groupName))
              .fontSize(11)
              .fontColor(AppColors.textSecondary)
              .margin({ left: 8 })
              .layoutWeight(1);
          }
        } else {
          Text(this.currentCategoryName)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.onPrimary)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(4)
            .backgroundColor(this.getCategoryColor(this.currentCategoryName));
        }
      }
      .width('100%')
      .margin({ top: 12, bottom: 8 });

      Column() {
        ForEach(this.getPagesForGroup(groupName), (page: GroupedPageEntry) => {
          this.PageCard(page);
        }, (page: GroupedPageEntry) => page.path);
      }
    }
    .width('100%');
  }

  @Builder
  PageCard(page: GroupedPageEntry) {
    Row() {
      Column() {
        Text(stripMarkdownInline(page.title))
          .fontSize(14)
          .fontColor(AppColors.primary)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%');
        if (page.summary.length > 0) {
          Text(page.summary)
            .fontSize(11)
            .fontColor(AppColors.textSecondary)
            .maxLines(2)
            .margin({ top: 2 })
            .width('100%');
        }
        if (page.sourceInfo.length > 0 && page.groupName.length > 0) {
          Text(page.sourceInfo)
            .fontSize(10)
            .fontColor(AppColors.textFaint)
            .maxLines(1)
            .margin({ top: 1 })
            .width('100%');
        }
      }
      .layoutWeight(1);

      Text('\u203A')
        .fontSize(18)
        .fontColor(AppColors.textFaint);
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(AppColors.card)
    .borderRadius(8)
    .margin({ bottom: 4 })
    .onClick(() => { this.openPage(page.path); });
  }

  @Builder
  ReaderView() {
    Column() {
      this.ReaderHeader();
      this.ReaderContent();
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  ReaderHeader() {
    Column() {
      Row() {
        Text('\u2190')
          .fontSize(20)
          .fontColor(AppColors.primary)
          .padding({ right: 8 })
          .onClick(() => { this.closeReader(); });

        Column() {
          Text(this.getPageTitle())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
          Scroll() {
            Row() {
              ForEach(this.getBreadcrumbItems(), (item: CrumbItem, index: number) => {
                if (index > 0) {
                  Text(' \u203A ')
                    .fontSize(10)
                    .fontColor(AppColors.textFaint);
                }
                Text(item.label)
                  .fontSize(10)
                  .fontColor(item.clickable ? AppColors.primary : AppColors.textSecondary)
                  .onClick(() => {
                    if (item.clickable) {
                      this.openPage(item.targetPath.endsWith('.md') ? item.targetPath : item.targetPath + '/index.md');
                    }
                  });
              }, (item: CrumbItem, index: number) => index.toString() + item.label);
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .width('100%');
        }
        .layoutWeight(1)
        .margin({ left: 4 });

        if (this.tocEntries.length > 0) {
          Text('\u2630')
            .fontSize(18)
            .fontColor(AppColors.textSecondary)
            .padding({ left: 8 })
            .onClick(() => { this.showToc = !this.showToc; });
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(AppColors.card);

      if (this.showToc && this.tocEntries.length > 0) {
        this.TocDropdown();
      }
    }
    .backgroundColor(AppColors.card)
    .shadow({ radius: 2, color: '#0A000000', offsetY: 1 });
  }

  @Builder
  TocDropdown() {
    Scroll() {
      Column() {
        ForEach(this.tocEntries, (entry: TocEntry) => {
          Row() {
            if (entry.level === 3) {
              Row().width(16);
            }
            Text('\u2022')
              .fontSize(10)
              .fontColor(AppColors.textSecondary)
              .margin({ right: 6 });
            Text(entry.text)
              .fontSize(12)
              .fontColor(AppColors.textBody)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1);
          }
          .width('100%')
          .padding({ top: 4, bottom: 4 })
          .onClick(() => {
            this.showToc = false;
            const targetId = entry.anchor;
            setTimeout(() => {
              try {
                const scrollRect = componentUtils.getRectangleById('kb_scroll');
                const targetRect = componentUtils.getRectangleById(targetId);
                const cur = this.pageScroller.currentOffset();
                this.pageScroller.scrollTo({
                  xOffset: 0,
                  yOffset: cur.yOffset + targetRect.windowOffset.y - scrollRect.windowOffset.y,
                });
              } catch (e) {
                hilog.warn(0x0001, 'KB', `TOC scroll failed for ${targetId}`);
              }
            }, 100);
          });
        }, (entry: TocEntry) => entry.anchor);
      }
      .padding({ left: 12, right: 12, top: 4, bottom: 8 });
    }
    .constraintSize({ maxHeight: 200 });
  }

  @Builder
  ReaderContent() {
    if (this.isPageLoading) {
      Column() {
        LoadingProgress().width(36).height(36).color(AppColors.textSecondary);
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center);
    } else {
      Scroll(this.pageScroller) {
        Column() {
          if (this.readingPage !== null && this.readingPage.sourceInfo.length > 0) {
            Row() {
              Text(this.readingPage.sourceInfo)
                .fontSize(11)
                .fontColor(AppColors.textSecondary)
                .layoutWeight(1)
                .maxLines(2);
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(AppColors.tierWarnBg)
            .borderRadius(6)
            .margin({ bottom: 8 });
          }

          ForEach(this.markdownLines, (ml: MarkdownLine) => {
            if (ml.anchorId.length > 0) {
              Column() {
                this.MarkdownLineView(ml);
              }
              .width('100%')
              .id(ml.anchorId);
            } else {
              this.MarkdownLineView(ml);
            }
          }, (ml: MarkdownLine, index: number) => index.toString());

          if (this.wikilinks.length > 0 || this.relatedPages.length > 0) {
            this.PageFooter();
          }
        }
        .padding(12);
      }
      .layoutWeight(1)
      .id('kb_scroll');
    }
  }

  @Builder
  MarkdownLineView(ml: MarkdownLine) {
    if (ml.type === 'h1') {
      Column() {
        Text(stripMarkdownInline(ml.text))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .width('100%');
        Row()
          .width(40)
          .height(3)
          .backgroundColor(AppColors.tierWarn)
          .borderRadius(2)
          .margin({ top: 4 });
      }
      .width('100%')
      .margin({ top: 16, bottom: 10 });
    } else if (ml.type === 'h2') {
      Text(stripMarkdownInline(ml.text))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.primary)
        .width('100%')
        .margin({ top: 14, bottom: 6 })
        .padding({ bottom: 4, left: 8 })
        .border({ width: { left: 3, right: 0, top: 0, bottom: 0 }, color: AppColors.kbAccent });
    } else if (ml.type === 'h3') {
      Text(stripMarkdownInline(ml.text))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.kbDeepGreen)
        .width('100%')
        .margin({ top: 10, bottom: 4 });
    } else if (ml.type === 'h4') {
      Text(stripMarkdownInline(ml.text))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.kbAccent)
        .width('100%')
        .margin({ top: 8, bottom: 3 });
    } else if (ml.type === 'callout') {
      this.CalloutView(ml);
    } else if (ml.type === 'codeBlock') {
      this.CodeBlockView(ml);
    } else if (ml.type === 'annotation') {
      this.AnnotationView(ml);
    } else if (ml.type === 'kvQuote') {
      this.KvQuoteView(ml);
    } else if (ml.type === 'li') {
      Row() {
        Text('\u2022')
          .fontSize(10)
          .fontColor(AppColors.kbAccent)
          .margin({ right: 6, top: 2 });
        Text(stripMarkdownInline(ml.text))
          .fontSize(13)
          .fontColor(AppColors.textBody)
          .layoutWeight(1);
      }
      .width('100%')
      .padding({ left: ml.indent * 12 + 4, top: 1, bottom: 1 });
    } else if (ml.type === 'quote') {
      Row() {
        Row()
          .width(3)
          .height(14)
          .backgroundColor(AppColors.tierWarn)
          .borderRadius(2)
          .margin({ top: 4, bottom: 4 });
        Text(stripMarkdownInline(ml.text))
          .fontSize(12)
          .fontColor(AppColors.textBody)
          .layoutWeight(1)
          .padding({ left: 8 });
      }
      .width('100%')
      .margin({ top: 2, bottom: 2 });
    } else if (ml.type === 'hr') {
      Row()
        .width('100%')
        .height(1)
        .backgroundColor(AppColors.divider)
        .margin({ top: 10, bottom: 10 });
    } else if (ml.type === 'blank') {
      Row().height(4);
    } else if (ml.type === 'tableSep') {
      Row();
    } else if (ml.type === 'tableHeader') {
      if (ml.cells.length > 0) {
        Scroll() {
          Row() {
            ForEach(ml.cells, (cell: string, idx: number) => {
              Text(cell)
                .fontSize(11)
                .fontColor(AppColors.primary)
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
                .padding({ left: 4, right: 4, top: 3, bottom: 3 });
            }, (cell: string, idx: number) => idx.toString());
          }
          .backgroundColor(AppColors.fillBeige)
          .borderRadius(2);
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%');
      } else {
        Scroll() {
          Text(stripTableMarkdown(stripMarkdownInline(ml.text)))
            .fontSize(11)
            .fontColor(AppColors.primary)
            .fontWeight(FontWeight.Bold)
            .fontFamily('monospace')
            .padding({ left: 6, right: 6, top: 3, bottom: 3 })
            .backgroundColor(AppColors.fillBeige)
            .borderRadius(2);
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%');
      }
    } else if (ml.type === 'table') {
      if (ml.cells.length > 0) {
        Scroll() {
          Row() {
            ForEach(ml.cells, (cell: string, idx: number) => {
              Text(cell)
                .fontSize(11)
                .fontColor(AppColors.textBody)
                .layoutWeight(1)
                .padding({ left: 4, right: 4, top: 2, bottom: 2 });
            }, (cell: string, idx: number) => idx.toString());
          }
          .backgroundColor(ml.tableRowIndex % 2 === 1 ? AppColors.surfaceMuted : AppColors.surfaceSubtle)
          .borderRadius(2);
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%');
      } else {
        Scroll() {
          Text(stripTableMarkdown(stripMarkdownInline(ml.text)))
            .fontSize(11)
            .fontColor(AppColors.textBody)
            .fontFamily('monospace')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(AppColors.surfaceSubtle)
            .borderRadius(2);
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%');
      }
    } else if (ml.type === 'tagLine') {
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(ml.text.split(/\s+/).filter((t: string): boolean => t.startsWith('#') && t.length > 1), (tag: string) => {
          Text(tag.substring(1))
            .fontSize(11)
            .fontColor(AppColors.primary)
            .backgroundColor(AppColors.background)
            .borderRadius(AppDimens.cardRadius)
            .border({ width: 1, color: AppColors.divider })
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .margin({ right: 6, bottom: 6 })
            .onClick(() => { this.searchByTag(tag.substring(1)); });
        }, (tag: string) => tag);
      }
      .width('100%')
      .margin({ top: 4, bottom: 4 });
    } else {
      Text(stripMarkdownInline(ml.text))
        .fontSize(13)
        .fontColor(AppColors.textBody)
        .width('100%')
        .margin({ top: 1, bottom: 1 });
    }
  }

  @Builder
  CalloutView(ml: MarkdownLine) {
    Column() {
      if (ml.calloutTitle.length > 0) {
        Row() {
          Text(getCalloutStyle(ml.calloutType).icon)
            .fontSize(14)
            .margin({ right: 6 });
          Text(stripMarkdownInline(ml.calloutTitle))
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(getCalloutStyle(ml.calloutType).borderColor)
            .layoutWeight(1);
        }
        .width('100%')
        .padding({ left: 12, right: 10, top: 8, bottom: 4 });
      }
      if (ml.calloutBody.length > 0) {
        Text(stripMarkdownInline(ml.calloutBody))
          .fontSize(12)
          .fontColor(AppColors.textBody)
          .width('100%')
          .padding({ left: 12, right: 10, top: ml.calloutTitle.length > 0 ? 0 : 8, bottom: 8 });
      }
    }
    .width('100%')
    .borderRadius(6)
    .border({ width: { left: 4, right: 0, top: 0, bottom: 0 }, color: getCalloutStyle(ml.calloutType).borderColor })
    .backgroundColor(getCalloutStyle(ml.calloutType).bgColor)
    .margin({ top: 6, bottom: 6 });
  }

  @Builder
  CodeBlockView(ml: MarkdownLine) {
    Scroll() {
      Text(ml.codeContent)
        .fontSize(11)
        .fontFamily('monospace')
        .fontColor(AppColors.textBody)
        .width('100%');
    }
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .padding(10)
    .backgroundColor(AppColors.surfaceMuted)
    .borderRadius(6)
    .margin({ top: 6, bottom: 6 });
  }

  @Builder
  AnnotationView(ml: MarkdownLine) {
    Row() {
      Text(getAnnotationBadgeInfo(ml.text).keyword)
        .fontSize(11)
        .fontColor(AppColors.onPrimary)
        .backgroundColor(getAnnotationBadgeInfo(ml.text).color)
        .borderRadius(3)
        .padding({ left: 6, right: 6, top: 1, bottom: 1 });
      if (getAnnotationBadgeInfo(ml.text).detail.length > 0) {
        Text(getAnnotationBadgeInfo(ml.text).detail)
          .fontSize(11)
          .fontColor(AppColors.textSecondary)
          .margin({ left: 6 });
      }
    }
    .margin({ top: 4, bottom: 4 });
  }

  @Builder
  KvQuoteView(ml: MarkdownLine) {
    Row() {
      Row()
        .width(3)
        .height('100%')
        .backgroundColor(AppColors.kbAccent)
        .borderRadius(2);
      Text(stripMarkdownInline(ml.text))
        .fontSize(13)
        .fontColor(AppColors.textBody)
        .layoutWeight(1)
        .padding({ left: 8, right: 8, top: 6, bottom: 6 });
    }
    .width('100%')
    .backgroundColor(AppColors.tierOkBg)
    .borderRadius({ topLeft: 0, bottomLeft: 0, topRight: 6, bottomRight: 6 })
    .margin({ top: 4, bottom: 4 });
  }

  @Builder
  PageFooter() {
    Column() {
      Row()
        .width('100%')
        .height(1)
        .backgroundColor(AppColors.divider)
        .margin({ top: 16, bottom: 12 });

      if (this.wikilinks.length > 0) {
         Text($r('app.string.kb_related_sections'))
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .width('100%')
          .margin({ bottom: 8 });
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.wikilinks.slice(0, 15), (link: string) => {
            Row() {
              Text(this.getWikilinkDisplayName(link))
                .fontSize(12)
                .fontColor(AppColors.primary);
            }
            .backgroundColor(AppColors.background)
            .borderRadius(AppDimens.cardRadius)
            .padding({ left: 8, right: 10, top: 4, bottom: 4 })
            .margin({ right: 6, bottom: 6 })
            .onClick(() => { this.handleWikilinkClick(link); });
          }, (link: string) => link);
        }
      }

      if (this.relatedPages.length > 0) {
         Text($r('app.string.kb_related_guidelines'))
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .width('100%')
          .margin({ top: this.wikilinks.length > 0 ? 12 : 0, bottom: 8 });
        Column() {
          ForEach(this.relatedPages, (sr: SearchResult) => {
            Row() {
              Column() {
                Text(this.getSearchResultTitle(sr))
                  .fontSize(13)
                  .fontColor(AppColors.primary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis });
                Text(this.getPathCategory(sr.path) + (sr.sourceInfo.length > 0 ? ' \u00B7 ' + sr.sourceInfo : ''))
                  .fontSize(10)
                  .fontColor(AppColors.textSecondary)
                  .maxLines(1)
                  .margin({ top: 1 });
              }
              .layoutWeight(1);
              Text('\u203A')
                .fontSize(16)
                .fontColor(AppColors.textFaint);
            }
            .width('100%')
            .padding({ top: 8, bottom: 8, left: 8, right: 8 })
            .borderRadius(6)
            .margin({ bottom: 2 })
            .backgroundColor(AppColors.card)
            .onClick(() => { this.openPage(sr.path); });
          }, (sr: SearchResult) => sr.path);
        }
      }
    }
    .width('100%');
  }
}
