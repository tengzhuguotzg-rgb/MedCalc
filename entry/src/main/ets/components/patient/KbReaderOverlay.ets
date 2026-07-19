import { MarkdownLine } from '../../utils/KbMarkdownParser';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { KbMarkdownRenderer } from './KbMarkdownRenderer';

@Component
export struct KbReaderOverlay {
  @Consume showKbReader: boolean;
  @Consume kbReaderPath: string;
  @Consume kbReaderTitle: string;
  @Consume kbReaderLines: MarkdownLine[];

  build() {
    Column() {
      Row() {
        Button('< 返回')
          .fontSize(14)
          .fontColor(AppColors.primary)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showKbReader = false;
            this.kbReaderPath = '';
          });
        Text(this.kbReaderTitle)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .layoutWeight(1)
          .margin({ left: 8 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(AppColors.card);

      Scroll() {
        Column() {
          Text(this.kbReaderTitle)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .width('100%');
          Text(this.kbReaderPath)
            .fontSize(11)
            .fontColor(AppColors.textSecondary)
            .width('100%')
            .margin({ top: 4, bottom: 8 });
          KbMarkdownRenderer({ lines: this.kbReaderLines });
        }
        .padding(12);
      }
      .layoutWeight(1);
    }
    .width('95%')
    .height('85%')
    .backgroundColor(AppColors.card)
    .borderRadius(AppDimens.cardRadius);
  }
}
