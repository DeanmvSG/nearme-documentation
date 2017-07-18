// @flow

interface SliderItemProvider {
  constructor(el: HTMLElement): void,
  load(startIndex: number, endIndex: number): Promise<void>,
  getTotalSlidesCount(): Promise<number>
}