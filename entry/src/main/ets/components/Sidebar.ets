import { CALCULATORS, GROUP_ORDER, Calculator } from '../model/CalculatorRegistry';
import { AppColors } from '../utils/AppColors';
import { AppDimens } from '../utils/AppDimens';

@Component
export struct Sidebar {
  @Link currentCalc: string;
  @Link favorites: string[];
  @Link sidebarCollapsed: boolean;

  build() {
    Column() {
      this.BrandSection();
      this.FavoritesSection();
      this.CalculatorList();
    }
    .width(220)
    .height('100%')
    .backgroundColor(AppColors.background)
    .border({ width: { right: 1 }, color: AppColors.divider });
  }

  @Builder
  BrandSection() {
    Row() {
      Text('T')
        .width(28)
        .height(28)
        .borderRadius(14)
        .backgroundColor(AppColors.headerText)
        .fontColor(AppColors.headerBg)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center);
      Column() {
        Text('医学计算器')
          .fontSize(12.5)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.headerText);
        Text('Teng.ZG')
          .fontSize(12)
          .fontColor(AppColors.headerText);
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 8 });
    }
    .padding({ left: 12, right: 12, top: 12, bottom: 8 })
    .width('100%')
    .backgroundColor(AppColors.headerBg);
  }

  @Builder
  FavoritesSection() {
    if (this.favorites.length > 0) {
      Column() {
        Row({ space: 4 }) {
          Image($r('app.media.ic_star_filled'))
            .width(12)
            .height(12)
            .fillColor(AppColors.primary)
            .objectFit(ImageFit.Contain)
          Text('收藏')
            .fontSize(12)
            .fontColor(AppColors.textSecondary)
        }
        .margin({ bottom: 4 });
        ForEach(this.favorites, (favId: string) => {
          this.CalculatorItem(CALCULATORS.find(c => c.id === favId)!);
        }, (favId: string) => favId);
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .width('100%');
    }
  }

  @Builder
  CalculatorList() {
    List() {
      ForEach(GROUP_ORDER, (groupName: string) => {
        ListItemGroup({ header: this.GroupHeader(groupName) }) {
          ForEach(CALCULATORS.filter(c => c.group === groupName), (calc: Calculator) => {
            ListItem() {
              this.CalculatorItem(calc);
            };
          }, (calc: Calculator) => calc.id);
        }
      });
    }
    .width('100%')
    .layoutWeight(1);
  }

  @Builder
  GroupHeader(groupName: string) {
    Column() {
      Row({ space: 8 }) {
        Row() {
          Image(this.groupIcon(groupName))
            .width(16)
            .height(16)
            .fillColor(AppColors.onPrimary)
            .objectFit(ImageFit.Contain)
        }
        .width(24)
        .height(24)
        .borderRadius(7)
        .backgroundColor(AppColors.getCategoryColor(groupName))
        .justifyContent(FlexAlign.Center)

        Text(groupName)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.getCategoryColor(groupName))
          .layoutWeight(1)

        Text(this.groupCount(groupName).toString())
          .fontSize(12)
          .fontColor(AppColors.textSecondary)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(10)
          .border({ width: 1, color: AppColors.border })
          .backgroundColor(AppColors.card)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 4 })

      Row()
        .width('100%')
        .height(2)
        .backgroundColor(AppColors.getCategoryColor(groupName))
        .opacity(0.35)
        .margin({ left: 12, right: 12, top: 4 })
    }
  }

  private groupCount(groupName: string): number {
    return CALCULATORS.filter(c => c.group === groupName).length;
  }

  private groupIcon(groupName: string): Resource {
    if (groupName === '呼吸') {
      return $r('app.media.ic_lungs');
    }
    if (groupName === '心血管') {
      return $r('app.media.ic_heart_pulse');
    }
    if (groupName === '肾') {
      return $r('app.media.ic_kidney');
    }
    if (groupName === '肝') {
      return $r('app.media.ic_liver');
    }
    if (groupName === '神经') {
      return $r('app.media.ic_brain');
    }
    if (groupName === '代谢') {
      return $r('app.media.ic_metabolism');
    }
    if (groupName === '感染') {
      return $r('app.media.ic_infection');
    }
    return $r('app.media.ic_general');
  }

  @Builder
  CalculatorItem(calc: Calculator) {
    Row() {
      if (calc.id === this.currentCalc) {
        Row()
          .width(3)
          .height('100%')
          .backgroundColor(AppColors.getCategoryColor(calc.group))
      }
      Image(this.calcIcon(calc.id))
        .width(16)
        .height(16)
        .fillColor(calc.id === this.currentCalc ? AppColors.getCategoryColor(calc.group) : AppColors.textSecondary)
        .objectFit(ImageFit.Contain)
      if (!this.sidebarCollapsed) {
        Text(calc.name)
          .fontSize(12.5)
          .fontColor(calc.id === this.currentCalc ? AppColors.primary : AppColors.textPrimary)
          .fontWeight(calc.id === this.currentCalc ? FontWeight.Bold : FontWeight.Normal)
          .layoutWeight(1)
          .margin({ left: 6 });
      }
    }
    .width('100%')
    .height(40)
    .padding({ left: 12, right: 12 })
    .backgroundColor(calc.id === this.currentCalc ? AppColors.card : 'transparent')
    .borderRadius(4)
    .onClick(() => {
      this.currentCalc = calc.id;
      this.sidebarCollapsed = true;
    });
  }

  private calcIcon(calcId: string): Resource {
    const groupMap: Record<string, string[]> = {
      '呼吸': ['pf', 'rox', 'bg', 'news2', 'fssicu', 'camicu'],
      '心血管': ['map', 'sf', 'sofa', 'chadsvasc', 'hasbled', 'curb65', 'scai', 'vasopressor', 'wells', 'pesi'],
      '肾': ['crcl', 'gfr', 'kdigo', 'na'],
      '肝': [],
      '神经': ['gcs', 'nihss', 'rass', 'wfns', 'fisher', 'ich', 'abcd2'],
      '代谢': ['cag', 'sirs', 'mehran', 'mnutric', 'nrs2002'],
      '感染': ['sofa', 'sirs', 'curb65'],
      '综合': [],
    };
    if (groupMap['呼吸'].includes(calcId)) {
      return $r('app.media.ic_lungs');
    }
    if (groupMap['心血管'].includes(calcId)) {
      return $r('app.media.ic_heart_pulse');
    }
    if (groupMap['肾'].includes(calcId)) {
      return $r('app.media.ic_kidney');
    }
    if (groupMap['肝'].includes(calcId)) {
      return $r('app.media.ic_liver');
    }
    if (groupMap['神经'].includes(calcId)) {
      return $r('app.media.ic_brain');
    }
    if (groupMap['代谢'].includes(calcId)) {
      return $r('app.media.ic_metabolism');
    }
    if (groupMap['感染'].includes(calcId)) {
      return $r('app.media.ic_infection');
    }
    return $r('app.media.ic_general');
  }

  @Builder
  CollapsedView() {
    Column() {
      Text('T')
        .width(28)
        .height(28)
        .borderRadius(14)
        .backgroundColor(AppColors.headerText)
        .fontColor(AppColors.headerBg)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center);
      List() {
        ForEach(CALCULATORS, (calc: Calculator) => {
          ListItem() {
            Row() {
              Image(this.calcIcon(calc.id))
                .width(20)
                .height(20)
                .fillColor(calc.id === this.currentCalc ? AppColors.primary : AppColors.textSecondary)
                .objectFit(ImageFit.Contain)
            }
            .width(40)
            .height(AppDimens.inputHeight)
            .justifyContent(FlexAlign.Center)
            .borderRadius(4)
            .backgroundColor(calc.id === this.currentCalc ? AppColors.card : 'transparent')
            .onClick(() => {
              this.currentCalc = calc.id;
            });
          };
        }, (calc: Calculator) => calc.id);
      }
      .layoutWeight(1)
      .margin({ top: 8 });
    }
    .padding({ top: 12 })
    .width('100%');
  }
}
