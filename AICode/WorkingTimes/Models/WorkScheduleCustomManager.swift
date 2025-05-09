import Foundation

// WorkScheduleManager 的自定义排班管理扩展
extension WorkScheduleManager {
    
    // MARK: - 固定排班工作日设置
    
    // 更新固定排班的每周工作日设置
    func updateFixedScheduleWorkingDays(workingDays: [Bool]) {
        // 确保数组长度正确
        guard workingDays.count == 7 else {
            print("工作日设置数组长度必须为7")
            return
        }
        
        // 更新工作日设置
        fixedScheduleWorkingDays = workingDays
        
        // 如果当前是固定排班，则更新激活的排班计划
        if currentScheduleType == .fixed {
            updateActiveSchedule()
        }
        
        // 保存设置
        saveSettings()
    }
    
    // MARK: - 自定义休息日管理
    
    // 添加自定义休息日
    func addCustomRestDay(date: Date) {
        // 获取日历
        let calendar = Calendar.current
        // 获取日期的开始时间（忽略时间部分）
        let startOfDay = calendar.startOfDay(for: date)
        
        // 检查是否已存在该日期
        if !customRestDays.contains(where: { calendar.isDate($0, inSameDayAs: startOfDay) }) {
            // 添加到休息日列表
            customRestDays.append(startOfDay)
            // 排序休息日列表
            customRestDays.sort()
            
            // 如果当前是自定义排班，则更新激活的排班计划
            if currentScheduleType == .custom {
                updateActiveSchedule()
            }
            
            // 保存设置
            saveSettings()
        }
    }
    
    // 添加多个自定义休息日
    func addMultipleCustomRestDays(dates: [Date]) {
        // 获取日历
        let calendar = Calendar.current
        
        // 处理每个日期
        for date in dates {
            // 获取日期的开始时间（忽略时间部分）
            let startOfDay = calendar.startOfDay(for: date)
            
            // 检查是否已存在该日期
            if !customRestDays.contains(where: { calendar.isDate($0, inSameDayAs: startOfDay) }) {
                // 添加到休息日列表
                customRestDays.append(startOfDay)
            }
        }
        
        // 排序休息日列表
        customRestDays.sort()
        
        // 如果当前是自定义排班，则更新激活的排班计划
        if currentScheduleType == .custom {
            updateActiveSchedule()
        }
        
        // 保存设置
        saveSettings()
    }
    
    // 移除自定义休息日
    func removeCustomRestDay(date: Date) {
        // 获取日历
        let calendar = Calendar.current
        
        // 查找并移除匹配的日期
        customRestDays.removeAll { existingDate in
            calendar.isDate(existingDate, inSameDayAs: date)
        }
        
        // 如果当前是自定义排班，则更新激活的排班计划
        if currentScheduleType == .custom {
            updateActiveSchedule()
        }
        
        // 保存设置
        saveSettings()
    }
    
    // 清除所有自定义休息日
    func clearAllCustomRestDays() {
        // 清空休息日列表
        customRestDays.removeAll()
        
        // 如果当前是自定义排班，则更新激活的排班计划
        if currentScheduleType == .custom {
            updateActiveSchedule()
        }
        
        // 保存设置
        saveSettings()
    }
}