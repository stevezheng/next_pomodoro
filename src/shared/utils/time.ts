/**
 * 时间格式化工具
 */

/**
 * 将秒数格式化为 MM:SS 格式
 * @param seconds 秒数
 * @returns 格式化后的时间字符串
 */
export function formatTime(seconds: number): string {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`
}

/**
 * 将分钟数转换为秒数
 * @param minutes 分钟数
 * @returns 秒数
 */
export function minutesToSeconds(minutes: number): number {
  return minutes * 60
}

/**
 * 计算休息时间
 * 公式：5分钟 + floor(累计推迟分钟 ÷ 5)
 * @param totalSnoozeMinutes 累计推迟分钟数
 * @returns 休息时间（秒）
 */
export function calculateBreakTime(totalSnoozeMinutes: number): number {
  const baseMinutes = 5
  const penaltyMinutes = Math.floor(totalSnoozeMinutes / 5)
  return (baseMinutes + penaltyMinutes) * 60
}
