import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

class MosaicRect {
  x: number = 0;
  y: number = 0;
  w: number = 0;
  h: number = 0;
}

class MosaicStroke {
  rects: MosaicRect[] = [];
}

@Component
export struct ImageEditor {
  @Link showEditor: boolean;
  @Link editorResultBase64: string;
  @Link editorResultMime: string;
  @Prop imageUri: string = '';
  @State canvasWidth: number = 0;
  @State canvasHeight: number = 0;
  @State displayWidth: number = 0;
  @State displayHeight: number = 0;
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State scaleRatio: number = 1;
  @State brushSize: number = 10;
  @State undoCount: number = 0;
  @State editorReady: boolean = false;
  @State errorMsg: string = '';
  @State isTouching: boolean = false;
  @State magPosX: number = -200;
  @State magPosY: number = -200;

  private pixelMap: image.PixelMap | null = null;
  private originalBuffer: ArrayBuffer | null = null;
  private strokes: MosaicStroke[] = [];
  private currentStroke: MosaicStroke | null = null;
  private lastBrushX: number = 0;
  private lastBrushY: number = 0;
  private lastMagX: number = -999;
  private lastMagY: number = -999;
  private magCanvasReady: boolean = false;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private magSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private magContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.magSettings);
  private magnifierSize: number = 150;
  private magnifierZoom: number = 3;

  getMosaicBlockSize(): number {
    return Math.max(8, Math.floor(this.brushSize / 2.5));
  }

  async loadImage() {
    try {
      this.editorReady = false;
      this.errorMsg = '';
      this.strokes = [];
      this.currentStroke = null;
      this.undoCount = 0;

      const srcFile = fileIo.openSync(this.imageUri, fileIo.OpenMode.READ_ONLY);
      const imageSource = image.createImageSource(srcFile.fd);
      const decodingOptions: image.DecodingOptions = {
        editable: true,
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      };
      const pm = await imageSource.createPixelMap(decodingOptions);
      fileIo.closeSync(srcFile);

      this.pixelMap = pm;
      const imgInfo = pm.getImageInfoSync();
      const imgW = imgInfo.size.width;
      const imgH = imgInfo.size.height;
      const totalBytes = pm.getPixelBytesNumber();
      const buffer = new ArrayBuffer(totalBytes);
      await pm.readPixelsToBuffer(buffer);
      this.originalBuffer = buffer;

      this.computeLayout(imgW, imgH);
      this.redrawCanvas();
      this.editorReady = true;
    } catch (e) {
      this.errorMsg = '图片加载失败: ' + (e instanceof Error ? e.message : String(e));
      hilog.error(0xF000, 'ImageEditor', 'loadImage failed: ' + (e instanceof Error ? e.stack : String(e)));
    }
  }

  computeLayout(imgW: number, imgH: number) {
    const containerW = this.canvasWidth;
    const containerH = this.canvasHeight;
    if (containerW <= 0 || containerH <= 0) {
      return;
    }
    const ratioW = containerW / imgW;
    const ratioH = containerH / imgH;
    const ratio = Math.min(ratioW, ratioH);
    this.scaleRatio = ratio;
    this.displayWidth = Math.floor(imgW * ratio);
    this.displayHeight = Math.floor(imgH * ratio);
    this.offsetX = Math.floor((containerW - this.displayWidth) / 2);
    this.offsetY = Math.floor((containerH - this.displayHeight) / 2);
  }

  async restoreOriginal() {
    const pm = this.pixelMap;
    const buf = this.originalBuffer;
    if (!pm || !buf) {
      return;
    }
    await pm.writeBufferToPixels(buf);
  }

  redrawCanvas() {
    const pm = this.pixelMap;
    if (!pm) {
      return;
    }
    this.context.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    this.context.drawImage(pm, this.offsetX, this.offsetY, this.displayWidth, this.displayHeight);

    const allStrokes: MosaicStroke[] = this.currentStroke ? [...this.strokes, this.currentStroke] : [...this.strokes];
    for (let s = 0; s < allStrokes.length; s++) {
      this.drawMosaicOverlay(allStrokes[s]);
    }
  }

  drawMosaicOverlay(stroke: MosaicStroke) {
    this.context.fillStyle = '#808080';
    this.context.globalAlpha = 0.7;
    for (let i = 0; i < stroke.rects.length; i++) {
      const r = stroke.rects[i];
      this.context.fillRect(r.x, r.y, r.w, r.h);
    }
    this.context.globalAlpha = 1.0;
  }

  drawSingleRect(rect: MosaicRect) {
    this.context.fillStyle = '#808080';
    this.context.globalAlpha = 0.7;
    this.context.fillRect(rect.x, rect.y, rect.w, rect.h);
    this.context.globalAlpha = 1.0;
  }

  async applyMosaicToPixelMap() {
    const pm = this.pixelMap;
    if (!pm) {
      return;
    }
    await this.restoreOriginal();
    const ms = this.getMosaicBlockSize();
    const info = pm.getImageInfoSync();
    const imgTotalW = info.size.width;
    const imgTotalH = info.size.height;

    for (let s = 0; s < this.strokes.length; s++) {
      const stroke = this.strokes[s];
      for (let i = 0; i < stroke.rects.length; i++) {
        const r = stroke.rects[i];
        const imgX = Math.floor((r.x - this.offsetX) / this.scaleRatio);
        const imgY = Math.floor((r.y - this.offsetY) / this.scaleRatio);
        const imgW = Math.floor(r.w / this.scaleRatio);
        const imgH = Math.floor(r.h / this.scaleRatio);
        const imgMs = Math.max(ms, Math.round(ms / this.scaleRatio));

        const startBlkX = Math.max(0, Math.floor(imgX / imgMs) * imgMs);
        const startBlkY = Math.max(0, Math.floor(imgY / imgMs) * imgMs);
        const endX = Math.min(imgTotalW, imgX + imgW);
        const endY = Math.min(imgTotalH, imgY + imgH);

        for (let by = startBlkY; by < endY; by += imgMs) {
          for (let bx = startBlkX; bx < endX; bx += imgMs) {
            const blkW = Math.min(imgMs, endX - bx);
            const blkH = Math.min(imgMs, endY - by);
            this.pixelateBlock(pm, bx, by, blkW, blkH);
          }
        }
      }
    }
  }

  pixelateBlock(pm: image.PixelMap, bx: number, by: number, bw: number, bh: number) {
    if (bw <= 0 || bh <= 0) {
      return;
    }
    const bufSize = bw * bh * 4;
    const buffer = new ArrayBuffer(bufSize);
    const area: image.PositionArea = {
      pixels: buffer,
      offset: 0,
      stride: bw * 4,
      region: { size: { height: bh, width: bw }, x: bx, y: by }
    };
    try {
      pm.readPixelsSync(area);
    } catch (_e) {
      return;
    }
    const data = new Uint8Array(buffer);
    let totalR = 0;
    let totalG = 0;
    let totalB = 0;
    let count = 0;
    for (let i = 0; i < data.length; i += 4) {
      totalR += data[i];
      totalG += data[i + 1];
      totalB += data[i + 2];
      count++;
    }
    if (count === 0) {
      return;
    }
    const avgR = Math.floor(totalR / count);
    const avgG = Math.floor(totalG / count);
    const avgB = Math.floor(totalB / count);
    for (let i = 0; i < data.length; i += 4) {
      data[i] = avgR;
      data[i + 1] = avgG;
      data[i + 2] = avgB;
    }
    const writeArea: image.PositionArea = {
      pixels: buffer,
      offset: 0,
      stride: bw * 4,
      region: { size: { height: bh, width: bw }, x: bx, y: by }
    };
    try {
      pm.writePixelsSync(writeArea);
    } catch (_e) {
      return;
    }
  }

  async undoLast() {
    if (this.strokes.length === 0) {
      return;
    }
    this.strokes = this.strokes.slice(0, this.strokes.length - 1);
    this.undoCount = this.strokes.length;
    await this.applyMosaicToPixelMap();
    this.redrawCanvas();
  }

  async clearAllMosaic() {
    this.strokes = [];
    this.currentStroke = null;
    this.undoCount = 0;
    await this.restoreOriginal();
    this.redrawCanvas();
  }

  async exportBase64(): Promise<string> {
    const pm = this.pixelMap;
    if (!pm) {
      return '';
    }
    const packer = image.createImagePacker();
    const packOpts: image.PackingOption = {
      format: 'image/jpeg',
      quality: 90
    };
    const packedData = await packer.packing(pm, packOpts);
    await packer.release();
    const uint8Arr = new Uint8Array(packedData);
    const base64Helper = new util.Base64Helper();
    return base64Helper.encodeToStringSync(uint8Arr);
  }

  handleTouch(x: number, y: number, isStart: boolean) {
    if (!this.editorReady || !this.pixelMap) {
      return;
    }
    const halfBrush = Math.floor(this.brushSize / 2);

    if (isStart) {
      const stroke = new MosaicStroke();
      const rect = new MosaicRect();
      rect.x = x - halfBrush;
      rect.y = y - halfBrush;
      rect.w = this.brushSize;
      rect.h = this.brushSize;
      stroke.rects.push(rect);
      this.currentStroke = stroke;
      this.lastBrushX = x;
      this.lastBrushY = y;
      this.drawSingleRect(rect);
    } else if (this.currentStroke) {
      const dx = x - this.lastBrushX;
      const dy = y - this.lastBrushY;
      const dist = Math.sqrt(dx * dx + dy * dy);
      const step = Math.max(Math.floor(halfBrush * 0.5), 6);

      if (dist < step) {
        const rect = new MosaicRect();
        rect.x = x - halfBrush;
        rect.y = y - halfBrush;
        rect.w = this.brushSize;
        rect.h = this.brushSize;
        this.currentStroke.rects.push(rect);
        this.drawSingleRect(rect);
      } else {
        const steps = Math.ceil(dist / step);
        for (let i = 1; i <= steps; i++) {
          const t = i / steps;
          const ix = this.lastBrushX + dx * t;
          const iy = this.lastBrushY + dy * t;
          const rect = new MosaicRect();
          rect.x = ix - halfBrush;
          rect.y = iy - halfBrush;
          rect.w = this.brushSize;
          rect.h = this.brushSize;
          this.currentStroke.rects.push(rect);
          this.drawSingleRect(rect);
        }
      }
      this.lastBrushX = x;
      this.lastBrushY = y;
    }
  }

  async finishStroke() {
    if (this.currentStroke && this.currentStroke.rects.length > 0) {
      this.strokes = [...this.strokes, this.currentStroke];
      this.currentStroke = null;
      this.undoCount = this.strokes.length;
      await this.applyMosaicToPixelMap();
      this.redrawCanvas();
    }
  }

  drawMagnifier(touchX: number, touchY: number) {
    const pm = this.pixelMap;
    if (!pm || !this.magCanvasReady) {
      return;
    }
    const dx = touchX - this.lastMagX;
    const dy = touchY - this.lastMagY;
    if (dx * dx + dy * dy < 4) {
      return;
    }
    this.lastMagX = touchX;
    this.lastMagY = touchY;

    const magSize = this.magnifierSize;
    const zoom = this.magnifierZoom;
    const half = Math.floor(magSize / 2);
    const halfBrush = this.brushSize / 2;

    this.magContext.clearRect(0, 0, magSize, magSize);
    this.magContext.save();
    this.magContext.beginPath();
    this.magContext.arc(half, half, half, 0, Math.PI * 2);
    this.magContext.clip();

    this.magContext.translate(half - touchX * zoom, half - touchY * zoom);
    this.magContext.scale(zoom, zoom);

    this.magContext.fillStyle = '#2A2A2A';
    this.magContext.fillRect(0, 0, this.canvasWidth, this.canvasHeight);
    this.magContext.drawImage(pm, this.offsetX, this.offsetY, this.displayWidth, this.displayHeight);

    const allStrokes: MosaicStroke[] = this.currentStroke ? [...this.strokes, this.currentStroke] : [...this.strokes];
    this.magContext.fillStyle = '#808080';
    this.magContext.globalAlpha = 0.7;
    for (let s = 0; s < allStrokes.length; s++) {
      const stroke = allStrokes[s];
      for (let i = 0; i < stroke.rects.length; i++) {
        const r = stroke.rects[i];
        this.magContext.fillRect(r.x, r.y, r.w, r.h);
      }
    }
    this.magContext.globalAlpha = 1.0;

    this.magContext.strokeStyle = '#FF3333';
    this.magContext.lineWidth = 2 / zoom;
    this.magContext.strokeRect(touchX - halfBrush, touchY - halfBrush, this.brushSize, this.brushSize);

    this.magContext.strokeStyle = 'rgba(255,255,255,0.5)';
    this.magContext.lineWidth = 1 / zoom;
    this.magContext.beginPath();
    this.magContext.moveTo(touchX, touchY - 10 / zoom);
    this.magContext.lineTo(touchX, touchY + 10 / zoom);
    this.magContext.stroke();
    this.magContext.beginPath();
    this.magContext.moveTo(touchX - 10 / zoom, touchY);
    this.magContext.lineTo(touchX + 10 / zoom, touchY);
    this.magContext.stroke();

    this.magContext.restore();

    this.magContext.strokeStyle = 'rgba(200,200,200,0.8)';
    this.magContext.lineWidth = 3;
    this.magContext.beginPath();
    this.magContext.arc(half, half, half - 1, 0, Math.PI * 2);
    this.magContext.stroke();

    let px = touchX - half;
    let py = touchY - 130 - magSize;
    if (py < 4) {
      py = touchY + 80;
    }
    if (px < 4) { px = 4; }
    if (px + magSize > this.canvasWidth - 4) { px = this.canvasWidth - magSize - 4; }
    if (py + magSize > this.canvasHeight - 4) { py = this.canvasHeight - magSize - 4; }
    this.magPosX = px;
    this.magPosY = py;
  }

  aboutToAppear() {
    if (this.imageUri.length > 0 && this.canvasWidth > 0) {
      this.loadImage();
    }
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text('取消')
            .fontSize(16)
            .fontColor('#5F6654')
            .padding({ left: 16, top: 12, bottom: 12 })
            .onClick(() => {
              this.showEditor = false;
            })
          Text('图片脱敏')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F3D2F')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Text('确认')
            .fontSize(16)
            .fontColor('#1F3D2F')
            .fontWeight(FontWeight.Medium)
            .padding({ right: 16, top: 12, bottom: 12 })
            .onClick(async () => {
              const base64 = await this.exportBase64();
              this.editorResultBase64 = base64;
              this.editorResultMime = 'image/jpeg';
              this.showEditor = false;
            })
        }
        .width('100%')
        .backgroundColor('#FFFFFF')

        Divider().color('#E0DCC8')

        if (this.errorMsg.length > 0) {
          Text(this.errorMsg)
            .fontSize(13)
            .fontColor('#E76F2C')
            .width('100%')
            .padding(12)
            .backgroundColor('#FFF3E0')
        }

        Stack() {
          Canvas(this.context)
            .width('100%')
            .height('100%')
            .backgroundColor('#2A2A2A')
            .onReady(() => {
              this.canvasWidth = this.context.width;
              this.canvasHeight = this.context.height;
              if (this.imageUri.length > 0 && !this.pixelMap) {
                this.loadImage();
              } else if (this.pixelMap) {
                this.redrawCanvas();
              }
            })
            .onTouch((event: TouchEvent) => {
              if (event.touches.length > 0) {
                const x = event.touches[0].x;
                const y = event.touches[0].y;
                if (event.type === TouchType.Down) {
                  this.isTouching = true;
                  this.lastMagX = -999;
                  this.lastMagY = -999;
                  this.handleTouch(x, y, true);
                  this.drawMagnifier(x, y);
                } else if (event.type === TouchType.Move) {
                  this.handleTouch(x, y, false);
                  this.drawMagnifier(x, y);
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  this.isTouching = false;
                  this.magPosX = -200;
                  this.magPosY = -200;
                  this.finishStroke();
                }
              }
            })

          Canvas(this.magContext)
            .width(this.magnifierSize)
            .height(this.magnifierSize)
            .position({ x: this.magPosX, y: this.magPosY })
            .zIndex(10)
            .hitTestBehavior(HitTestMode.None)
            .onReady(() => {
              this.magCanvasReady = true;
            })
            .shadow({ radius: 8, color: '#80000000', offsetY: 2 })
            .visibility(this.isTouching ? Visibility.Visible : Visibility.Hidden)
        }
        .layoutWeight(1)
        .width('100%')

        Row() {
          Text('笔刷:')
            .fontSize(13)
            .fontColor('#5F6654')
          Slider({
            value: this.brushSize,
            min: 10,
            max: 80,
            step: 5
          })
            .layoutWeight(1)
            .height(30)
            .onChange((value: number) => {
              this.brushSize = value;
            })
          Text(this.brushSize.toString())
            .fontSize(13)
            .fontColor('#1F3D2F')
            .width(30)
          Blank().width(12)
          Button('撤销')
            .fontSize(12)
            .fontColor('#1F3D2F')
            .backgroundColor('#E8E5D8')
            .borderRadius(6)
            .height(32)
            .padding({ left: 10, right: 10 })
            .enabled(this.undoCount > 0)
            .onClick(() => {
              this.undoLast();
            })
          Button('清空')
            .fontSize(12)
            .fontColor('#E76F2C')
            .backgroundColor('#FFF3E0')
            .borderRadius(6)
            .height(32)
            .padding({ left: 10, right: 10 })
            .margin({ left: 8 })
            .enabled(this.undoCount > 0)
            .onClick(() => {
              this.clearAllMosaic();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('#FFFFFF')
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#2A2A2A')
  }
}
