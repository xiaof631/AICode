import Foundation

// WorkScheduleManager 的状态管理扩展
extension WorkScheduleManager {
    
    // 更新当前状态
    func updateStatus() {
        // 确保有激活的排班计划
        guard let schedule = activeSchedule else {
            currentStatus = .offWork // 没有排班计划则默认为下班
            statusText = "No active schedule" // 无激活排班
            nextEvent = nil // 没有排班，就没有下一个事件
            return
        }
    
        let now = Date() // 获取当前时间
        // 调用激活排班计划的 getCurrentStatus 方法获取当前状态
        currentStatus = schedule.getCurrentStatus(date: now)
        // --- 新增：计算下一个事件 ---
        calculateNextEvent(from: now, schedule: schedule)
        // --- 结束新增 ---
    
        // 根据获取的状态更新用于显示的文本
        switch currentStatus {
        case .working:
            statusText = NSLocalizedString("Working", comment: "Status: Working") // 工作中
        case .lunchBreak:
            statusText = NSLocalizedString("Lunch Break", comment: "Status: Lunch Break") // 午休中
        case .dinnerBreak: // 新增
            statusText = NSLocalizedString("Dinner Break", comment: "Status: Dinner Break") // 晚餐中
        case .offWork:
            statusText = NSLocalizedString("Off Work", comment: "Status: Off Work") // 下班
        case .weekend:
            statusText = NSLocalizedString("Weekend", comment: "Status: Weekend") // 周末
        case .holiday:
            statusText = NSLocalizedString("Holiday", comment: "Status: Holiday") // 节假日
        case .restDay:
            statusText = NSLocalizedString("Rest Day", comment: "Status: Rest Day") // 休息日 (非周末的休息)
        }
    }
    
    // 计算下一个状态变更事件
    func calculateNextEvent(from currentDate: Date, schedule: WorkSchedule) {
        // 使用排班计划的 getNextEvent 方法获取下一个事件
        nextEvent = schedule.getNextEvent(after: currentDate)
    }
    
    // 启动状态更新计时器
    func startStatusTimer() {
        // 停止现有计时器（如果有）
        stopStatusTimer()
        
        // 创建新的计时器，每分钟更新一次状态
        statusTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
        
        // 立即更新一次状态
        updateStatus()
    }
    
    // 停止状态更新计时器
    func stopStatusTimer() {
        statusTimer?.invalidate()
        statusTimer = nil
    }
    
    // 根据当前的 `currentScheduleType` 更新 `activeSchedule` 实例
    func updateActiveSchedule() {
        switch currentScheduleType {
        case .fixed:
            activeSchedule = FixedWorkSchedule(
                workStartTime: workStartTime,
                workEndTime: workEndTime,
                lunchBreakStartTime: lunchBreakStartTime,
                lunchBreakEndTime: lunchBreakEndTime,
                dinnerStartTime: dinnerStartTime,
                dinnerEndTime: dinnerEndTime,
                workingDays: fixedScheduleWorkingDays
            )
        case .alternating:
            activeSchedule = AlternatingWorkSchedule(
                workStartTime: workStartTime,
                workEndTime: workEndTime,
                lunchBreakStartTime: lunchBreakStartTime,
                lunchBreakEndTime: lunchBreakEndTime,
                dinnerStartTime: dinnerStartTime,
                dinnerEndTime: dinnerEndTime,
                currentWeekType: currentWeekType,
                holidayAutoRest: holidayAutoRest // 新增：传递节假日自动休息设置
            )
        case .shift:
            activeSchedule = ShiftWorkSchedule(
                workStartTime: workStartTime,
                workEndTime: workEndTime,
                lunchBreakStartTime: lunchBreakStartTime,
                lunchBreakEndTime: lunchBreakEndTime,
                dinnerStartTime: dinnerStartTime,
                dinnerEndTime: dinnerEndTime,
                startDate: shiftStartDate,
                workDays: shiftWorkDays,
                restDays: shiftRestDays,
                holidayAutoRest: holidayAutoRest // 新增：传递节假日自动休息设置
            )
        case .custom:
            activeSchedule = CustomWorkSchedule(
                workStartTime: workStartTime,
                workEndTime: workEndTime,
                lunchBreakStartTime: lunchBreakStartTime,
                lunchBreakEndTime: lunchBreakEndTime,
                dinnerStartTime: dinnerStartTime,
                dinnerEndTime: dinnerEndTime,
                customRestDays: customRestDays,
                holidayAutoRest: holidayAutoRest // 新增：传递节假日自动休息设置
            )
        }

        // 更新排班后立即更新当前状态
        updateStatus()
    }
}