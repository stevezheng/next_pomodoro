const { app } = require('electron')
const path = require('path')
const fs = require('fs')

class Settings {
  constructor() {
    this.userDataPath = app.getPath('userData')
    this.settingsPath = path.join(this.userDataPath, 'settings.json')
    this.defaults = {
      workTime: 25,
      breakTime: 5,
      longBreakTime: 15,
      longBreakInterval: 4,
      autoStartBreaks: false,
      autoStartPomodoros: false,
      notifications: true,
      soundEnabled: true,
      soundVolume: 0.5,
      darkMode: false,
      showTimeInMenuBar: true,
      tickSounds: false
    }
    this.settings = this.load()
  }
  
  load() {
    try {
      if (fs.existsSync(this.settingsPath)) {
        const data = fs.readFileSync(this.settingsPath, 'utf8')
        return { ...this.defaults, ...JSON.parse(data) }
      }
    } catch (error) {
      console.error('加载设置失败:', error)
    }
    return { ...this.defaults }
  }
  
  save() {
    try {
      fs.writeFileSync(this.settingsPath, JSON.stringify(this.settings, null, 2))
    } catch (error) {
      console.error('保存设置失败:', error)
    }
  }
  
  get(key) {
    return this.settings[key]
  }
  
  set(key, value) {
    this.settings[key] = value
    this.save()
  }
  
  getAll() {
    return { ...this.settings }
  }
  
  reset() {
    this.settings = { ...this.defaults }
    this.save()
  }
}

module.exports = Settings