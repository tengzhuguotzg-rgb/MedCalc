import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export function showConfirmDialog(title: string, message: string, onConfirm: () => void): void {
  try {
    promptAction.showDialog({
      title: title,
      message: message,
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '确定', color: '#E84040' }
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
