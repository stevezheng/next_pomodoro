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
  
  timer.onComplete = (completedPhase, nextPhase, completedPomodoros) => {
    showNotification(completedPhase, nextPhase, completedPomodoros)
    
    if (completedPhase === 'work') {
      statistics.recordSession('work', settings.get('workTime') * 60, true)
    } else {
      const duration = completedPhase === 'longbreak' ? settings.get('longBreakTime') * 60 : settings.get('breakTime') * 60
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

const showNotification = (completedPhase, nextPhase, completedPomodoros) => {
  let title, body
  
  if (completedPhase === 'work') {
    title = '🍅 工作时间结束！'
    if (nextPhase === 'longbreak') {
      body = `恭喜完成第 ${completedPomodoros} 个番茄钟！\n开始15分钟长休息吧！`
    } else {
      body = `恭喜完成第 ${completedPomodoros} 个番茄钟！\n开始5分钟短休息吧！`
    }
  } else if (completedPhase === 'break') {
    title = '☕ 短休息结束！'
    body = '休息时间结束了，开始新的25分钟工作周期吧！'
  } else if (completedPhase === 'longbreak') {
    title = '🛌 长休息结束！'
    body = '长休息时间结束了，准备开始新的工作周期！'
  }
  
  new Notification({
    title,
    body,
    sound: true,
    urgency: 'critical'
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