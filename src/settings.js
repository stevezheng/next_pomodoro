const { app } = require('electron')
const path = require('path')
const fs = require('fs')
require('dotenv').config()

class Settings {
  constructor() {
    this.userDataPath = app.getPath('userData')
    this.settingsPath = path.join(this.userDataPath, 'settings.json')
    this.defaults = {
      workTime: process.env.DEV_WORK_TIME ? parseInt(process.env.DEV_WORK_TIME) / 60 : 25,
      breakTime: process.env.DEV_BREAK_TIME ? parseInt(process.env.DEV_BREAK_TIME) / 60 : 5,
      longBreakTime: process.env.DEV_LONG_BREAK_TIME ? parseInt(process.env.DEV_LONG_BREAK_TIME) / 60 : 15,
      longBreakInterval: process.env.LONG_BREAK_INTERVAL ? parseInt(process.env.LONG_BREAK_INTERVAL) : 4,
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