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
        .backgroundColor(AppColors.primary)
        .fontColor(AppColors.card)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center);
      Column() {
        Text('医学计算器')
          .fontSize(12.5)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary);
        Text('Teng.ZG')
          .fontSize(12)
          .fontColor(AppColors.textSecondary);
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 8 });
    }
    .padding({ left: 12, right: 12, top: 12, bottom: 8 })
    .width('100%');
  }

  @Builder
  FavoritesSection() {
    if (this.favorites.length > 0) {
      Column() {
        Text('★ 收藏')
          .fontSize(12)
          .fontColor(AppColors.textSecondary)
          .letterSpacing(1.5)
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
    Text(groupName)
      .fontSize(12)
      .fontColor(AppColors.textSecondary)
      .letterSpacing(1.5)
      .padding({ left: 12, right: 12, top: 8, bottom: 4 });
  }

  @Builder
  CalculatorItem(calc: Calculator) {
    Row() {
      Text(calc.icon)
        .fontSize(14)
        .width(18);
      if (!this.sidebarCollapsed) {
        Text(calc.name)
          .fontSize(12.5)
          .fontColor(calc.id === this.currentCalc ? AppColors.primary : AppColors.textPrimary)
          .fontWeight(calc.id === this.currentCalc ? FontWeight.Bold : FontWeight.Normal)
          .layoutWeight(1);
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor(calc.id === this.currentCalc ? AppColors.card : 'transparent')
    .borderRadius(4)
    .onClick(() => {
      this.currentCalc = calc.id;
      this.sidebarCollapsed = true;
    });
  }

  @Builder
  CollapsedView() {
    Column() {
      Text('T')
        .width(28)
        .height(28)
        .borderRadius(14)
        .backgroundColor(AppColors.primary)
        .fontColor(AppColors.card)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center);
      List() {
        ForEach(CALCULATORS, (calc: Calculator) => {
          ListItem() {
            Text(calc.icon)
              .fontSize(18)
              .width(40)
              .height(AppDimens.inputHeight)
              .textAlign(TextAlign.Center)
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
