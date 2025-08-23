const { app, Tray, Menu, Notification, nativeImage } = require('electron')
const PomodoroTimer = require('./timer')
const Settings = require('./settings')
const Statistics = require('./statistics')

let tray = null
let timer = null
let settings = null
let statistics = null

const createTray = () => {
  settings = new Settings()
  statistics = new Statistics()
  timer = new PomodoroTimer(settings)
  
  timer.onTick = (timeLeft, phase, state) => {
    updateTrayTitle(timeLeft, phase, state)
  }
  
  timer.onComplete = (nextPhase, completedPomodoros) => {
    showNotification(nextPhase, completedPomodoros)
    
    if (timer.phase === 'work') {
      statistics.recordSession('work', settings.get('workTime') * 60, true)
    } else {
      const duration = timer.phase === 'longbreak' ? settings.get('longBreakTime') * 60 : settings.get('breakTime') * 60
      statistics.recordSession('break', duration, true)
    }
  }
  
  const emptyIcon = nativeImage.createEmpty()
  tray = new Tray(emptyIcon)
  
  updateTrayTitle(timer.timeLeft, timer.phase, timer.state)
  
  tray.on('right-click', () => {
    tray.setContextMenu(buildContextMenu())
  })
}

const buildContextMenu = () => {
  const status = timer.getStatus()
  const phaseText = status.phase === 'work' ? '工作' : status.phase === 'longbreak' ? '长休息' : '短休息'
  
  return Menu.buildFromTemplate([
    { 
      label: `${status.timeLeftFormatted} - ${phaseText}`, 
      enabled: false 
    },
    { type: 'separator' },
    { 
      label: status.state === 'running' ? '暂停' : status.state === 'paused' ? '继续' : '开始', 
      click: () => timer.toggle()
    },
    { 
      label: '停止', 
      click: () => timer.stop(),
      enabled: status.state !== 'stopped'
    },
    { type: 'separator' },
    { label: '退出', click: () => app.quit() }
  ])
}

const updateTrayTitle = (timeLeft, phase, state) => {
  const formattedTime = timer.formatTime(timeLeft)
  const statusIcon = state === 'running' ? '' : state === 'paused' ? '⏸' : '⏹'
  const phaseIcon = phase === 'work' ? '🍅' : phase === 'longbreak' ? '🛌' : '☕'
  
  const phaseText = phase === 'work' ? '工作' : phase === 'longbreak' ? '长休息' : '短休息'
  
  tray.setTitle(`${statusIcon}${phaseIcon}${formattedTime}`)
  tray.setToolTip(`番茄钟 - ${phaseText} - ${formattedTime}`)
  tray.setContextMenu(buildContextMenu())
}

const showNotification = (nextPhase, completedPomodoros) => {
  let title, body
  
  if (nextPhase === 'work') {
    title = '休息结束！'
    body = `已完成 ${completedPomodoros} 个番茄钟。开始新的工作周期吧！`
  } else if (nextPhase === 'break') {
    title = '番茄钟完成！'
    body = '工作25分钟结束，休息5分钟吧！'
  } else {
    title = '番茄钟完成！'
    body = '工作25分钟结束，享受15分钟长休息！'
  }
  
  new Notification({
    title,
    body,
    sound: true
  }).show()
}

app.whenReady().then(() => {
  app.dock.hide()
  createTray()
})

app.on('window-all-closed', (e) => {
  e.preventDefault()
})

app.on('before-quit', () => {
  if (tray) {
    tray.destroy()
  }
})