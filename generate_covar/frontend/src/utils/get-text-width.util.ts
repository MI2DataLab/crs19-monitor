const c = document.createElement('canvas');

export function getTextWidth(txt: string, fontName: string, fontSize: string): number {
    const ctx = c.getContext('2d')!;
    const fontSpec = fontSize + ' ' + fontName;
    ctx.font = fontSpec;
    return ctx.measureText(txt).width;
}