import Foundation

// MARK: - Base Work Schedule Protocol (基础工作排班协议)
protocol WorkSchedule {
    var workStartTime: Date { get set }       // 工作开始时间
    var workEndTime: Date { get set }         // 工作结束时间
    var lunchBreakStartTime: Date { get set } // 午休开始时间
    var lunchBreakEndTime: Date { get set }   // 午休结束时间
    var dinnerStartTime: Date { get set }     // 晚餐开始时间
    var dinnerEndTime: Date { get set }       // 晚餐结束时间
    var holidayAutoRest: Bool { get set }     // 节假日是否自动休息
    
    // 获取指定日期的当前状态
    func getCurrentStatus(date: Date) -> WorkStatus
    // 判断指定日期是否为工作日、休息日或节假日
    func isWorkDay(date: Date) -> WorkDayType
    
    // 计算给定日期之后的下一个状态变更事件
    func getNextEvent(after currentDate: Date) -> (date: Date, status: WorkStatus)?
}

// MARK: - 工作时间状态检查的扩展方法
extension WorkSchedule {
    // 通用的工作时间状态检查方法
    func checkWorkTimeStatus(date: Date) -> WorkStatus {
        let calendar = Calendar.current
        let now = calendar.dateComponents([.hour, .minute], from: date)
        let workStart = calendar.dateComponents([.hour, .minute], from: workStartTime)
        let workEnd = calendar.dateComponents([.hour, .minute], from: workEndTime)
        let lunchStart = calendar.dateComponents([.hour, .minute], from: lunchBreakStartTime)
        let lunchEnd = calendar.dateComponents([.hour, .minute], from: lunchBreakEndTime)
        let dinnerStart = calendar.dateComponents([.hour, .minute], from: dinnerStartTime)
        let dinnerEnd = calendar.dateComponents([.hour, .minute], from: dinnerEndTime)
        
        let nowMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let workStartMinutes = (workStart.hour ?? 0) * 60 + (workStart.minute ?? 0)
        let workEndMinutes = (workEnd.hour ?? 0) * 60 + (workEnd.minute ?? 0)
        let lunchStartMinutes = (lunchStart.hour ?? 0) * 60 + (lunchStart.minute ?? 0)
        let lunchEndMinutes = (lunchEnd.hour ?? 0) * 60 + (lunchEnd.minute ?? 0)
        let dinnerStartMinutes = (dinnerStart.hour ?? 0) * 60 + (dinnerStart.minute ?? 0)
        let dinnerEndMinutes = (dinnerEnd.hour ?? 0) * 60 + (dinnerEnd.minute ?? 0)
        
        // 更新状态检查逻辑，包含晚餐休息
        if nowMinutes < workStartMinutes || nowMinutes >= workEndMinutes {
            // 在下班时间检查晚餐状态
            if nowMinutes >= dinnerStartMinutes && nowMinutes < dinnerEndMinutes {
                return .dinnerBreak
            }
            return .offWork
        } else if nowMinutes >= lunchStartMinutes && nowMinutes < lunchEndMinutes {
            return .lunchBreak
        } else if nowMinutes >= dinnerStartMinutes && nowMinutes < dinnerEndMinutes {
            // 工作时间内检查晚餐状态
            return .dinnerBreak
        } else {
            return .working
        }
    }
    
    // 通用的下一个事件计算方法
    func calculateNextEvent(after currentDate: Date) -> (date: Date, status: WorkStatus)? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: currentDate)
        
        // 辅助函数：合并日期和时间部分
        func combine(date: Date, time: Date) -> Date {
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
            return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                 minute: timeComponents.minute ?? 0,
                                 second: timeComponents.second ?? 0,
                                 of: date) ?? date
        }
        
        var potentialEvents: [(date: Date, status: WorkStatus)] = []
        var searchDate = today // 从今天开始搜索
        
        // 循环查找未来最多7天内的事件
        for _ in 0..<7 {
            let workDayType = self.isWorkDay(date: searchDate)
            
            if workDayType == .workDay {
                // 获取当天的所有时间点
                let workStart = combine(date: searchDate, time: workStartTime)
                let lunchStart = combine(date: searchDate, time: lunchBreakStartTime)
                let lunchEnd = combine(date: searchDate, time: lunchBreakEndTime)
                let dinnerStart = combine(date: searchDate, time: dinnerStartTime)
                let dinnerEnd = combine(date: searchDate, time: dinnerEndTime)
                let workEnd = combine(date: searchDate, time: workEndTime)
                
                // 添加所有在 currentDate 之后的时间点
                if workStart > currentDate { potentialEvents.append((workStart, .working)) }
                if lunchStart > currentDate { potentialEvents.append((lunchStart, .lunchBreak)) }
                if lunchEnd > currentDate { potentialEvents.append((lunchEnd, .working)) }
                if dinnerStart > currentDate { potentialEvents.append((dinnerStart, .dinnerBreak)) }
                if dinnerEnd > currentDate { potentialEvents.append((dinnerEnd, .working)) }
                if workEnd > currentDate { potentialEvents.append((workEnd, .offWork)) }
            } else {
                // 如果当天是休息日/周末/节假日，查找下一个工作日
                var nextWorkday = calendar.date(byAdding: .day, value: 1, to: searchDate)!
                var loopCount = 0 // 防止无限循环
                while self.isWorkDay(date: nextWorkday) != .workDay && loopCount < 365 {
                    nextWorkday = calendar.date(byAdding: .day, value: 1, to: nextWorkday)!
                    loopCount += 1
                }
                
                if loopCount < 365 {
                    let nextWorkStart = combine(date: nextWorkday, time: workStartTime)
                    if nextWorkStart > currentDate {
                        potentialEvents.append((nextWorkStart, .working))
                    }
                }
                
                potentialEvents.sort { $0.date < $1.date }
                return potentialEvents.first
            }
            
            // 如果在当前搜索日期找到了未来的事件，就排序并返回最近的一个
            if !potentialEvents.isEmpty {
                potentialEvents.sort { $0.date < $1.date }
                return potentialEvents.first
            }
            
            // 继续搜索下一天
            searchDate = calendar.date(byAdding: .day, value: 1, to: searchDate)!
        }
        
        // 如果循环结束后仍未找到事件，则返回 nil
        return nil
    }
}