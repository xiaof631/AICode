import Foundation

struct FixedWorkSchedule: WorkSchedule {
    // ... 已有的属性 (workStartTime, workEndTime, lunchBreakStartTime, etc.) ...

    // ... 已有的 getCurrentStatus 和 isWorkDay 方法 ...

    // --- 添加 getNextEvent 方法的实现 ---
    func getNextEvent(after currentDate: Date) -> (date: Date, status: WorkStatus)? {
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

        // 循环查找未来最多（例如）7天内的事件，避免无限循环
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
                if lunchEnd > currentDate { potentialEvents.append((lunchEnd, .working)) } // 假设午休后恢复工作
                if dinnerStart > currentDate { potentialEvents.append((dinnerStart, .dinnerBreak)) }
                if dinnerEnd > currentDate { potentialEvents.append((dinnerEnd, .working)) } // 假设晚餐后恢复工作
                if workEnd > currentDate { potentialEvents.append((workEnd, .offWork)) }
            } else {
                // 如果当天是休息日/周末/节假日，下一个事件可能是下一个工作日的开始
                // 需要找到下一个工作日
                var nextWorkday = calendar.date(byAdding: .day, value: 1, to: searchDate)!
                while self.isWorkDay(date: nextWorkday) != .workDay {
                     nextWorkday = calendar.date(byAdding: .day, value: 1, to: nextWorkday)!
                     // 可以加一个循环次数限制防止意外死循环
                }
                let nextWorkStart = combine(date: nextWorkday, time: workStartTime)
                // 只有当这个下一个工作日开始时间晚于当前时间时才添加
                if nextWorkStart > currentDate {
                    potentialEvents.append((nextWorkStart, .working))
                }
                // 找到第一个非工作日后的工作日即可跳出外层循环，因为我们只关心最近的事件
                 potentialEvents.sort { $0.date < $1.date } // 排序找到最近的
                 return potentialEvents.first // 直接返回找到的第一个事件
            }

            // 如果在当前搜索日期找到了未来的事件，就排序并返回最近的一个
            if !potentialEvents.isEmpty {
                potentialEvents.sort { $0.date < $1.date }
                return potentialEvents.first
            }

            // 如果今天没有找到未来的事件，继续搜索下一天
            searchDate = calendar.date(byAdding: .day, value: 1, to: searchDate)!
        }

        // 如果循环7天后仍未找到事件，则返回 nil
        return nil
    }
    // --- 结束添加 ---
}