import {
  MarkdownLine,
  stripMarkdownInline, stripTableMarkdown, getCalloutStyle, getAnnotationBadgeInfo
} from '../../utils/KbMarkdownParser';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';

@Component
export struct KbMarkdownRenderer {
  @Prop lines: MarkdownLine[] = [];

  build() {
    ForEach(this.lines, (ml: MarkdownLine) => {
      this.MarkdownLineView(ml);
    }, (ml: MarkdownLine, index: number) => index.toString());
  }

  @Builder
  MarkdownLineView(ml: MarkdownLine) {
    if (ml.type === 'h1') {
      Text(stripMarkdownInline(ml.text))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.primary)
        .width('100%')
        .margin({ top: 12, bottom: 6 });
    } else if (ml.type === 'h2') {
      Text(stripMarkdownInline(ml.text))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.primary)
        .width('100%')
        .margin({ top: 8, bottom: 4 });
    } else if (ml.type === 'h3') {
      Text(stripMarkdownInline(ml.text))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.primary)
        .width('100%')
        .margin({ top: 6, bottom: 3 });
    } else if (ml.type === 'callout') {
      this.CalloutView(ml);
    } else if (ml.type === 'codeBlock') {
      this.CodeBlockView(ml);
    } else if (ml.type === 'annotation') {
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
    } else if (ml.type === 'kvQuote') {
      Row() {
        Row()
          .width(3)
          .height('100%')
          .backgroundColor(AppColors.kbAccent)
          .borderRadius(2);
        Text(stripMarkdownInline(ml.text))
          .fontSize(12)
          .fontColor(AppColors.textBody)
          .layoutWeight(1)
          .padding({ left: 8, right: 8, top: 6, bottom: 6 });
      }
      .width('100%')
      .backgroundColor(AppColors.tierOkBg)
      .borderRadius({ topLeft: 0, bottomLeft: 0, topRight: 6, bottomRight: 6 })
      .margin({ top: 4, bottom: 4 });
    } else if (ml.type === 'li') {
      Row() {
        Text('\u2022')
          .fontSize(12)
          .fontColor(AppColors.textSecondary)
          .margin({ right: 6 });
        Text(stripMarkdownInline(ml.text))
          .fontSize(12)
          .fontColor(AppColors.textBody)
          .layoutWeight(1);
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .padding({ left: ml.indent * 12 + 8, top: 1, bottom: 1 });
    } else if (ml.type === 'quote') {
      Row() {
        Row()
          .width(3)
          .height(14)
          .backgroundColor(AppColors.tierWarn)
          .borderRadius(2)
          .margin({ top: 4, bottom: 4 });
        Text(stripMarkdownInline(ml.text))
          .fontSize(11)
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
        .margin({ top: 6, bottom: 6 });
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
          .backgroundColor(AppColors.surfaceSubtle)
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
      Row() {
        ForEach(ml.text.split(/\s+/).filter((t: string): boolean => t.startsWith('#') && t.length > 1), (tag: string) => {
          Text(tag.substring(1))
            .fontSize(11)
            .fontColor(AppColors.primary)
            .backgroundColor(AppColors.background)
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ right: 4, bottom: 4 });
        }, (tag: string) => tag);
      }
      .width('100%')
      .margin({ top: 4, bottom: 4 });
    } else {
      Text(stripMarkdownInline(ml.text))
        .fontSize(12)
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
}
