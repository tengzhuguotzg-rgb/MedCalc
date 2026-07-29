import { promptAction } from '@kit.ArkUI';

export function showToast(message: string, duration: number = 2000): void {
  promptAction.showToast({
    message: message,
    duration: duration,
    bottom: 200
  });
}
