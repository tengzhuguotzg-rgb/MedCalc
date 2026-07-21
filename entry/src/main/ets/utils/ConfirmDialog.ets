import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export function showConfirmDialog(title: ResourceStr, message: ResourceStr, onConfirm: () => void): void {
  try {
    promptAction.showDialog({
      title: title,
      message: message,
      buttons: [
        { text: '取消', color: $r('app.color.app_color_dialog_cancel') },
        { text: '确定', color: $r('app.color.app_color_dialog_confirm') }
      ]
    }, (err, data) => {
      if (err) {
        return;
      }
      if (data.index === 1) {
        onConfirm();
      }
    });
  } catch (error) {
    const e = error as BusinessError;
    hilog.error(0x0001, 'ConfirmDialog', `showDialog failed: ${e.code} ${e.message}`);
  }
}
