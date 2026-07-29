// Enums.ets - 全局枚举定义
// 替换 Index.ets 中的魔法数字 currentTab: 0/1/2/3 和魔法字符串 calcMode: 'normal'/'recommend'/'recognize'

export enum TabIndex {
  Calculator = 0,
  Patient = 1,
  Knowledge = 2,
  Settings = 3
}

export enum CalcMode {
  Normal = 'normal',
  Recommend = 'recommend',
  Recognize = 'recognize'
}
