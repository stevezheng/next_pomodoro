import { Tray, Menu, nativeImage, app } from 'electron'
import path from 'path'
import { TimerState, StateContext, EventType } from '@shared/types'
import { TitleFormatter } from './title-formatter'
import { MENU_ITEMS } from '@shared/constants'

/**
 * Tray 管理器
 * 管理 Menu Bar 图标和菜单
 */
export class TrayManager {
  private tray: Tray | null = null
  private onActionCallback: ((action: string) => void) | null = null

  constructor() {
    this.createTray()
  }

  /**
   * 创建 Tray 图标
   */
  private createTray(): void {
    // 创建一个简单的图标（16x16 透明图片）
    const icon = nativeImage.createEmpty()
    this.tray = new Tray(icon)

    // 设置初始标题（传入完整的 StateContext）
    const initialContext: StateContext = {
      currentState: TimerState.IDLE,
      timeLeft: 0,
      completedPomodoros: 0,
      snoozeCount: 0,
      snoozeMinutes: 0
    }
    this.updateTitle(TimerState.IDLE, initialContext)

    // 设置初始菜单
    this.updateMenu(TimerState.IDLE)
  }

  /**
   * 更新 Menu Bar 标题
   * @param state 当前状态
   * @param context 状态上下文
   */
  public updateTitle(state: TimerState, context: StateContext): void {
    if (!this.tray) return

    const title = TitleFormatter.format(state, context)
    console.log('更新 Tray 标题:', title)
    this.tray.setTitle(title)
  }

  /**
   * 更新右键菜单
   * @param state 当前状态
   */
  public updateMenu(state: TimerState): void {
    if (!this.tray) return

    const template = this.buildMenuTemplate(state)
    const contextMenu = Menu.buildFromTemplate(template)
    this.tray.setContextMenu(contextMenu)
  }

  /**
   * 构建菜单模板
   * @param state 当前状态
   * @returns 菜单模板
   */
  private buildMenuTemplate(state: TimerState): Electron.MenuItemConstructorOptions[] {
    const items: Electron.MenuItemConstructorOptions[] = []

    // 显示当前状态
    items.push({
      label: TitleFormatter.getStatusText(state),
      enabled: false
    })

    items.push({ type: 'separator' })

    // 根据状态添加不同菜单项
    switch (state) {
      case TimerState.IDLE:
        items.push({
          label: MENU_ITEMS.START,
          click: () => this.handleAction('start')
        })
        break

      case TimerState.FOCUS:
        items.push({
          label: MENU_ITEMS.PAUSE,
          click: () => this.handleAction('pause')
        })
        break

      case TimerState.SNOOZE:
        items.push({
          label: '开始休息',
          click: () => this.handleAction('startBreak')
        })
        break

      case TimerState.BREAK:
        items.push({
          label: MENU_ITEMS.PAUSE,
          click: () => this.handleAction('pause')
        })
        break
    }

    items.push({ type: 'separator' })

    // 退出按钮
    items.push({
      label: MENU_ITEMS.QUIT,
      click: () => this.handleAction('quit')
    })

    return items
  }

  /**
   * 处理菜单动作
   * @param action 动作类型
   */
  private handleAction(action: string): void {
    if (action === 'quit') {
      app.quit()
    } else if (this.onActionCallback) {
      this.onActionCallback(action)
    }
  }

  /**
   * 设置动作回调
   * @param callback 回调函数
   */
  public onAction(callback: (action: string) => void): void {
    this.onActionCallback = callback
  }

  /**
   * 销毁 Tray
   */
  public destroy(): void {
    if (this.tray) {
      this.tray.destroy()
      this.tray = null
    }
  }
}
