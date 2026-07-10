import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class ImageStore {
  private static instance: ImageStore | null = null;
  private baseDir: string = '';
  private thumbDir: string = '';
  private tempDir: string = '';

  private constructor() {}

  static getInstance(): ImageStore {
    if (!ImageStore.instance) {
      ImageStore.instance = new ImageStore();
    }
    return ImageStore.instance;
  }

  init(context: Context): void {
    try {
      this.baseDir = context.filesDir + '/patient_images';
      this.thumbDir = context.filesDir + '/patient_thumbs';
      this.tempDir = context.filesDir + '/temp_edit';
      fileIo.mkdirSync(this.baseDir, true);
      fileIo.mkdirSync(this.thumbDir, true);
      fileIo.mkdirSync(this.tempDir, true);
    } catch (_e) {
    }
  }

  saveImage(patientId: string, recordId: string, data: Uint8Array, ext: string): string {
    try {
      const dir = this.baseDir + '/' + patientId;
      fileIo.mkdirSync(dir, true);
      const filePath = dir + '/' + recordId + '.' + ext;
      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      fileIo.writeSync(file.fd, data);
      fileIo.closeSync(file.fd);
      return filePath;
    } catch (_e) {
      return '';
    }
  }

  saveImageFromUri(patientId: string, recordId: string, uri: string, context: Context): string {
    try {
      const dir = this.baseDir + '/' + patientId;
      fileIo.mkdirSync(dir, true);
      const ext = this.getExtFromUri(uri);
      const filePath = dir + '/' + recordId + '.' + ext;
      const srcFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(uri);
      const buf = new ArrayBuffer(stat.size);
      fileIo.readSync(srcFile.fd, buf);
      fileIo.closeSync(srcFile.fd);
      const dstFile = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      fileIo.writeSync(dstFile.fd, buf);
      fileIo.closeSync(dstFile.fd);
      return filePath;
    } catch (_e) {
      return '';
    }
  }

  deleteImage(filePath: string): void {
    try {
      if (filePath.length > 0 && fileIo.accessSync(filePath)) {
        fileIo.unlinkSync(filePath);
      }
    } catch (_e) {
    }
  }

  deletePatientImages(patientId: string): void {
    const dir = this.baseDir + '/' + patientId;
    try {
      if (fileIo.accessSync(dir)) {
        fileIo.rmdirSync(dir);
      }
    } catch (_e) {
    }
  }

  getImageUri(filePath: string): string {
    return 'file://' + filePath;
  }

  private getExtFromUri(uri: string): string {
    if (uri.indexOf('.png') >= 0) {
      return 'png';
    }
    if (uri.indexOf('.jpeg') >= 0 || uri.indexOf('.jpg') >= 0) {
      return 'jpg';
    }
    return 'jpg';
  }

  copyToTemp(uri: string, id: string): string {
    try {
      fileIo.mkdirSync(this.tempDir, true);
      const ext = this.getExtFromUri(uri);
      const filePath = this.tempDir + '/' + id + '.' + ext;
      fileIo.copyFileSync(uri, filePath);
      return filePath;
    } catch (_e) {
      try {
        const srcFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
        const buf = new ArrayBuffer(1024 * 1024 * 50);
        const bytesRead = fileIo.readSync(srcFile.fd, buf);
        fileIo.closeSync(srcFile.fd);
        const ext = this.getExtFromUri(uri);
        const filePath = this.tempDir + '/' + id + '.' + ext;
        const dstFile = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
        const trimmed = new Uint8Array(bytesRead);
        const srcView = new Uint8Array(buf);
        for (let i = 0; i < bytesRead; i++) {
          trimmed[i] = srcView[i];
        }
        fileIo.writeSync(dstFile.fd, trimmed.buffer);
        fileIo.closeSync(dstFile.fd);
        return filePath;
      } catch (_e2) {
        return '';
      }
    }
  }

  clearTemp(): void {
    try {
      if (fileIo.accessSync(this.tempDir)) {
        const list = fileIo.listFileSync(this.tempDir);
        for (let i = 0; i < list.length; i++) {
          try {
            fileIo.unlinkSync(this.tempDir + '/' + list[i]);
          } catch (_e2) {
          }
        }
      }
    } catch (_e) {
    }
  }

  launchSystemEditor(sandboxFilePath: string): Promise<string> {
    return new Promise((resolve, reject) => {
      const context = AppStorage.get<common.UIAbilityContext>('context');
      if (!context) {
        reject(new Error('UIAbilityContext not available'));
        return;
      }
      const fileUri = 'file://' + sandboxFilePath;
      const wantParam: Record<string, Object> = {
        'content-Uri': fileUri
      };
      const callback: common.AbilityStartCallback = {
        onError: (code: number, name: string, message: string) => {
          hilog.error(0xF000, 'ImageStore', 'photoEditor error: ' + code + ' ' + message);
          reject(new Error('Editor error: ' + message));
        },
        onResult: (abilityResult: common.AbilityResult) => {
          hilog.info(0xF000, 'ImageStore', 'photoEditor result: ' + abilityResult.resultCode);
          if (abilityResult.resultCode === 0 && abilityResult.want) {
            const editedUri = abilityResult.want.uri;
            if (editedUri && editedUri.length > 0) {
              resolve(editedUri);
              return;
            }
          }
          reject(new Error('Editor cancelled or no result'));
        }
      };
      try {
        context.startAbilityByType('photoEditor', wantParam, callback, (err: BusinessError) => {
          if (err) {
            hilog.error(0xF000, 'ImageStore', 'startAbilityByType failed: ' + err.message);
            reject(new Error('No photo editor available'));
          }
        });
      } catch (e) {
        reject(new Error('startAbilityByType exception'));
      }
    });
  }
}
