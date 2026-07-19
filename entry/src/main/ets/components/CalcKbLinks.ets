import { KnowledgeService, SearchResult } from '../services/KnowledgeService';
import { CALCULATORS, Calculator } from '../model/CalculatorRegistry';
import { AppColors } from '../utils/AppColors';

@Component
export struct CalcKbLinks {
  @Prop calcId: string = '';
  @State kbResults: SearchResult[] = [];
  @State loaded: boolean = false;
  @State expanded: boolean = false;
  @State kbNavigatePath: string = '';

  private kbService: KnowledgeService = KnowledgeService.getInstance();

  aboutToAppear() {
    this.waitForInit();
  }

  async waitForInit() {
    if (!this.kbService.isReady()) {
      const ctx = AppStorage.get<Context>('context');
      if (ctx !== undefined) {
        await this.kbService.init(ctx);
      }
    }
    this.loadKb();
  }

  async loadKb() {
    const calc = CALCULATORS.find((c: Calculator): boolean => c.id === this.calcId);
    if (calc === undefined) {
      this.loaded = true;
      return;
    }
    const query = calc.name + ' ' + calc.group;
    try {
      this.kbResults = await this.kbService.smartSearch(query, 5);
    } catch (_e) {
      this.kbResults = [];
    }
    this.loaded = true;
  }

  getResultTitle(sr: SearchResult): string {
    if (sr.title.length > 0) {
      return sr.title;
    }
    return sr.path.split('/').pop()?.replace(/\.md$/, '') || sr.path;
  }

  getResultCategory(sr: SearchResult): string {
    return sr.path.split('/')[0] || '';
  }

  openInKb(sr: SearchResult) {
    AppStorage.setOrCreate<string>('kbNavigatePath', sr.path);
  }

  build() {
    if (this.loaded && this.kbResults.length > 0) {
      Column() {
        Row() {
          Text('\u{1F4D6}')
            .fontSize(14)
            .margin({ right: 4 });
          Text('指南参考')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary);
          Blank();
          Text(this.expanded ? '收起' : '查看')
            .fontSize(12)
            .fontColor(AppColors.primary)
            .onClick(() => { this.expanded = !this.expanded; });
        }
        .width('100%');

        if (this.expanded) {
          Column() {
            ForEach(this.kbResults, (sr: SearchResult) => {
              Row() {
                Column() {
                  Text(this.getResultTitle(sr))
                    .fontSize(12)
                    .fontColor(AppColors.primary)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1);
                  Text(this.getResultCategory(sr) + (sr.sourceInfo.length > 0 ? ' \u00B7 ' + sr.sourceInfo : ''))
                    .fontSize(12)
                    .fontColor(AppColors.textSecondary)
                    .maxLines(1)
                    .margin({ top: 1 });
                }
                .layoutWeight(1);
                Text('\u203A')
                  .fontSize(14)
                  .fontColor(AppColors.textFaint);
              }
              .width('100%')
              .padding({ top: 6, bottom: 6, left: 4, right: 4 })
              .borderRadius(4)
              .onClick(() => { this.openInKb(sr); });
            }, (sr: SearchResult) => sr.path);
          }
          .margin({ top: 4 });
        } else {
          Text(this.kbResults.map((sr: SearchResult): string => this.getResultTitle(sr)).join(' \u00B7 '))
            .fontSize(12)
            .fontColor(AppColors.primary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
            .width('100%');
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(AppColors.card)
      .borderRadius(8)
      .margin({ top: 8 });
    }
  }
}
