import Foundation

// WorkScheduleManager 的设置管理扩展
extension WorkScheduleManager {
    
    // 用于编码和解码的数据模型
    struct ScheduleSettings: Codable {
        var scheduleType: String
        var workStartTime: TimeInterval
        var workEndTime: TimeInterval
        var lunchBreakStartTime: TimeInterval
        var lunchBreakEndTime: TimeInterval
        var dinnerStartTime: TimeInterval
        var dinnerEndTime: TimeInterval
        var alternatingStartDate: TimeInterval
        var currentWeekType: String
        var shiftStartDate: TimeInterval
        var shiftWorkDays: Int
        var shiftRestDays: Int
        var customRestDays: [TimeInterval]
        var fixedScheduleWorkingDays: [Bool]
        var holidayAutoRest: Bool // 新增：节假日是否自动休息
    }
    
    // 将所有设置保存到沙盒文件
    func saveSettings() {
        // 创建设置数据模型
        let settings = ScheduleSettings(
            scheduleType: currentScheduleType.rawValue,
            workStartTime: workStartTime.timeIntervalSince1970,
            workEndTime: workEndTime.timeIntervalSince1970,
            lunchBreakStartTime: lunchBreakStartTime.timeIntervalSince1970,
            lunchBreakEndTime: lunchBreakEndTime.timeIntervalSince1970,
            dinnerStartTime: dinnerStartTime.timeIntervalSince1970,
            dinnerEndTime: dinnerEndTime.timeIntervalSince1970,
            alternatingStartDate: alternatingStartDate.timeIntervalSince1970,
            currentWeekType: currentWeekType.rawValue,
            shiftStartDate: shiftStartDate.timeIntervalSince1970,
            shiftWorkDays: shiftWorkDays,
            shiftRestDays: shiftRestDays,
            customRestDays: customRestDays.map { $0.timeIntervalSince1970 },
            fixedScheduleWorkingDays: fixedScheduleWorkingDays,
            holidayAutoRest: holidayAutoRest // 新增：保存节假日自动休息设置
        )
        
        // 使用FileStorage保存设置
        do {
            try FileStorage.shared.saveData(settings, toFile: settingsFileName)
        } catch {
            print("保存设置失败: \(error.localizedDescription)")
        }
    }

    // 从沙盒文件加载设置
    func loadSettings() {
        // 使用FileStorage加载设置
        guard FileStorage.shared.fileExists(fileName: settingsFileName) else {
            print("设置文件不存在，将使用默认设置")
            return
        }
        
        do {
            // 加载并解码设置
            let settings = try FileStorage.shared.loadData(fromFile: settingsFileName, as: ScheduleSettings.self)
            
            // 应用设置
            if let savedType = WorkScheduleType(rawValue: settings.scheduleType) {
                currentScheduleType = savedType
            }
            
            workStartTime = Date(timeIntervalSince1970: settings.workStartTime)
            workEndTime = Date(timeIntervalSince1970: settings.workEndTime)
            lunchBreakStartTime = Date(timeIntervalSince1970: settings.lunchBreakStartTime)
            lunchBreakEndTime = Date(timeIntervalSince1970: settings.lunchBreakEndTime)
            dinnerStartTime = Date(timeIntervalSince1970: settings.dinnerStartTime)
            dinnerEndTime = Date(timeIntervalSince1970: settings.dinnerEndTime)
            
            alternatingStartDate = Date(timeIntervalSince1970: settings.alternatingStartDate)
            if let weekType = WeekType(rawValue: settings.currentWeekType) {
                currentWeekType = weekType
            }
            
            shiftStartDate = Date(timeIntervalSince1970: settings.shiftStartDate)
            shiftWorkDays = settings.shiftWorkDays
            shiftRestDays = settings.shiftRestDays
            
            customRestDays = settings.customRestDays.map { Date(timeIntervalSince1970: $0) }
            customRestDays.sort()
            
            if settings.fixedScheduleWorkingDays.count == 7 {
                fixedScheduleWorkingDays = settings.fixedScheduleWorkingDays
            }
            
            // 新增：加载节假日自动休息设置
            holidayAutoRest = settings.holidayAutoRest
            
            print("设置已从文件加载")
        } catch {
            print("加载设置失败: \(error.localizedDescription)")
        }
    }
    
    // 应用工作时间设置
    func applyScheduleTimes(workStart: Date, workEnd: Date, lunchStart: Date, lunchEnd: Date, dinnerStart: Date, dinnerEnd: Date) {
        // 更新工作时间相关的 @Published 属性
        workStartTime = workStart
        workEndTime = workEnd
        lunchBreakStartTime = lunchStart
        lunchBreakEndTime = lunchEnd
        dinnerStartTime = dinnerStart // 新增
        dinnerEndTime = dinnerEnd     // 新增

        // 更新激活的排班计划以反映新的时间
        // updateActiveSchedule() // 内部已包含状态更新
        // 保存更改后的设置
        saveSettings()
        // 手动触发一次状态更新，确保界面立即反应
        updateStatus()
    }
}