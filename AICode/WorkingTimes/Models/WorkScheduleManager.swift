import Foundation
import Combine

// 管理工作排班的核心类，负责加载、保存、更新和计算当前的工作状态
class WorkScheduleManager: ObservableObject {
    // 单例实例
    static let shared = WorkScheduleManager()

    // MARK: - Published Properties (发布属性，用于 SwiftUI 视图绑定)

    // 当前选择的排班类型 (例如：固定、交替、轮班、自定义)
    @Published var currentScheduleType: WorkScheduleType = .fixed
    // 当前的工作状态 (例如：工作中、午休、下班、周末、节假日、休息日)
    @Published var currentStatus: WorkStatus = .offWork
    // 用于显示的当前状态文本
    @Published var statusText: String = "Initial Status" // 初始状态

    // 工作时间 (所有排班类型通用)
    @Published var workStartTime: Date // 工作开始时间
    @Published var workEndTime: Date   // 工作结束时间
    @Published var lunchBreakStartTime: Date // 午休开始时间
    @Published var lunchBreakEndTime: Date   // 午休结束时间
    @Published var dinnerStartTime: Date // 新增：晚餐开始时间
    @Published var dinnerEndTime: Date   // 新增：晚餐结束时间

    // 特定排班类型的属性
    @Published var alternatingStartDate: Date = Date() // 交替排班的参考开始日期 (用于计算大小周)
    @Published var currentWeekType: WeekType = .bigWeek // 交替排班的当前周类型 (大周/小周)
    @Published var shiftStartDate: Date = Date() // 轮班制的开始日期
    @Published var shiftWorkDays: Int = 5 // 轮班制连续工作天数
    @Published var shiftRestDays: Int = 2 // 轮班制连续休息天数
    @Published var customRestDays: [Date] = [] // 自定义排班的特定休息日列表

    // MARK: - Private Properties (私有属性)

    // 当前激活的排班计划实例
    private var activeSchedule: WorkSchedule?

    // 用于定期更新状态的计时器
    private var statusTimer: Timer?

    // UserDefaults 存储键
    private struct Keys {
        static let scheduleType = "scheduleType"
        static let workStartTime = "workStartTime"
        static let workEndTime = "workEndTime"
        static let lunchBreakStartTime = "lunchBreakStartTime"
        static let lunchBreakEndTime = "lunchBreakEndTime"
        static let dinnerStartTime = "dinnerStartTime" // 新增
        static let dinnerEndTime = "dinnerEndTime"   // 新增
        static let alternatingStartDate = "alternatingStartDate" // 注意：这个键似乎没有在 load/save 中使用
        static let currentWeekType = "currentWeekType"
        static let shiftStartDate = "shiftStartDate"
        static let shiftWorkDays = "shiftWorkDays"
        static let shiftRestDays = "shiftRestDays"
        static let customRestDays = "customRestDays"
    }

    // 私有初始化方法，确保单例模式
    private init() {
        // 设置默认工作时间 (上午9点 - 下午6点, 午休 12点 - 1点)
        let calendar = Calendar.current

        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        workStartTime = calendar.date(from: components) ?? Date()

        components.hour = 18
        components.minute = 0
        workEndTime = calendar.date(from: components) ?? Date()

        components.hour = 12
        components.minute = 0
        lunchBreakStartTime = calendar.date(from: components) ?? Date()

        components.hour = 13
        components.minute = 0
        lunchBreakEndTime = calendar.date(from: components) ?? Date()

        // 设置默认晚餐时间 (晚上 7点 - 8点)
        components.hour = 19
        components.minute = 0
        dinnerStartTime = calendar.date(from: components) ?? Date() // 新增

        components.hour = 20
        components.minute = 0
        dinnerEndTime = calendar.date(from: components) ?? Date()   // 新增

        // 加载保存的设置 (如果不存在则使用默认值)
        loadSettings()

        // 加载当前年份的节假日信息
        let currentYear = calendar.component(.year, from: Date())
        HolidayManager.shared.loadHolidays(for: currentYear)

        // 使用加载或默认的设置初始化激活的排班计划
        updateActiveSchedule()

        // 启动状态更新计时器
        startStatusTimer()
    }

    // MARK: - Settings Persistence (设置持久化)

    // 将所有设置保存到 UserDefaults
    func saveSettings() {
        let defaults = UserDefaults.standard

        // 保存排班类型
        defaults.set(currentScheduleType.rawValue, forKey: Keys.scheduleType)

        // 保存工作时间 (存储为 TimeInterval)
        defaults.set(workStartTime.timeIntervalSince1970, forKey: Keys.workStartTime)
        defaults.set(workEndTime.timeIntervalSince1970, forKey: Keys.workEndTime)
        defaults.set(lunchBreakStartTime.timeIntervalSince1970, forKey: Keys.lunchBreakStartTime)
        defaults.set(lunchBreakEndTime.timeIntervalSince1970, forKey: Keys.lunchBreakEndTime)
        defaults.set(dinnerStartTime.timeIntervalSince1970, forKey: Keys.dinnerStartTime) // 新增
        defaults.set(dinnerEndTime.timeIntervalSince1970, forKey: Keys.dinnerEndTime)     // 新增

        // 保存特定排班类型的数据
        // 注意：alternatingStartDate 未保存
        defaults.set(currentWeekType.rawValue, forKey: Keys.currentWeekType)
        defaults.set(shiftStartDate.timeIntervalSince1970, forKey: Keys.shiftStartDate)
        defaults.set(shiftWorkDays, forKey: Keys.shiftWorkDays)
        defaults.set(shiftRestDays, forKey: Keys.shiftRestDays)

        // 保存自定义休息日 (存储为 TimeInterval 数组)
        let customRestDaysTimeIntervals = customRestDays.map { $0.timeIntervalSince1970 }
        defaults.set(customRestDaysTimeIntervals, forKey: Keys.customRestDays)

        // 强制同步以确保数据写入磁盘
        defaults.synchronize()
    }

    // 从 UserDefaults 加载设置
    private func loadSettings() {
        let defaults = UserDefaults.standard

        // 加载排班类型
        if let savedTypeString = defaults.string(forKey: Keys.scheduleType),
           let savedType = WorkScheduleType(rawValue: savedTypeString) {
            currentScheduleType = savedType
        }

        // 加载工作时间 (从 TimeInterval 转换回 Date)
        if let startTimeInterval = defaults.object(forKey: Keys.workStartTime) as? TimeInterval {
            workStartTime = Date(timeIntervalSince1970: startTimeInterval)
        }
        // ... 其他时间加载逻辑 ...
        if let endTimeInterval = defaults.object(forKey: Keys.workEndTime) as? TimeInterval {
            workEndTime = Date(timeIntervalSince1970: endTimeInterval)
        }

        if let lunchStartTimeInterval = defaults.object(forKey: Keys.lunchBreakStartTime) as? TimeInterval {
            lunchBreakStartTime = Date(timeIntervalSince1970: lunchStartTimeInterval)
        }

        if let lunchEndTimeInterval = defaults.object(forKey: Keys.lunchBreakEndTime) as? TimeInterval {
            lunchBreakEndTime = Date(timeIntervalSince1970: lunchEndTimeInterval)
        }


        // 加载晚餐时间
        if let dinnerStartTimeInterval = defaults.object(forKey: Keys.dinnerStartTime) as? TimeInterval { // 新增
            dinnerStartTime = Date(timeIntervalSince1970: dinnerStartTimeInterval)
        }
        if let dinnerEndTimeInterval = defaults.object(forKey: Keys.dinnerEndTime) as? TimeInterval {   // 新增
            dinnerEndTime = Date(timeIntervalSince1970: dinnerEndTimeInterval)
        }


        // 加载特定排班类型的数据
        // 注意：alternatingStartDate 未加载
        if let weekTypeString = defaults.string(forKey: Keys.currentWeekType),
           let weekType = WeekType(rawValue: weekTypeString) {
            currentWeekType = weekType
        }

        if let shiftStartInterval = defaults.object(forKey: Keys.shiftStartDate) as? TimeInterval {
            shiftStartDate = Date(timeIntervalSince1970: shiftStartInterval)
        }

        // 加载轮班天数，如果未保存则使用默认值
        shiftWorkDays = defaults.integer(forKey: Keys.shiftWorkDays)
        if shiftWorkDays == 0 { shiftWorkDays = 5 } // 如果读取为0（未设置过），则设为默认值5

        shiftRestDays = defaults.integer(forKey: Keys.shiftRestDays)
        if shiftRestDays == 0 { shiftRestDays = 2 } // 如果读取为0（未设置过），则设为默认值2

        // 加载自定义休息日 (从 TimeInterval 数组转换回 Date 数组)
        if let customRestDaysTimeIntervals = defaults.array(forKey: Keys.customRestDays) as? [TimeInterval] {
            customRestDays = customRestDaysTimeIntervals.map { Date(timeIntervalSince1970: $0) }
            // 对加载的休息日进行排序，确保顺序一致性
            customRestDays.sort()
        }
    }

    // MARK: - Schedule Management (排班管理)

    // 根据当前的 `currentScheduleType` 更新 `activeSchedule` 实例
    func updateActiveSchedule() {
        // 现在将晚餐时间传递给初始化器
        switch currentScheduleType {
        case .fixed:
            activeSchedule = FixedWorkSchedule(
                workStartTime: workStartTime,
                workEndTime: workEndTime,
                lunchBreakStartTime: lunchBreakStartTime,
                lunchBreakEndTime: lunchBreakEndTime,
                dinnerStartTime: dinnerStartTime, // 传递晚餐时间
                dinnerEndTime: dinnerEndTime      // 传递晚餐时间
            )
        case .alternating:
            activeSchedule = AlternatingWorkSchedule(
                workStartTime: workStartTime,
                workEndTime: workEndTime,
                lunchBreakStartTime: lunchBreakStartTime,
                lunchBreakEndTime: lunchBreakEndTime,
                dinnerStartTime: dinnerStartTime, // 传递晚餐时间
                dinnerEndTime: dinnerEndTime,     // 传递晚餐时间
                currentWeekType: currentWeekType
            )
        case .shift:
            activeSchedule = ShiftWorkSchedule(
                workStartTime: workStartTime,
                workEndTime: workEndTime,
                lunchBreakStartTime: lunchBreakStartTime,
                lunchBreakEndTime: lunchBreakEndTime,
                dinnerStartTime: dinnerStartTime, // 传递晚餐时间
                dinnerEndTime: dinnerEndTime,     // 传递晚餐时间
                startDate: shiftStartDate,
                workDays: shiftWorkDays,
                restDays: shiftRestDays
            )
        case .custom:
            activeSchedule = CustomWorkSchedule(
                workStartTime: workStartTime,
                workEndTime: workEndTime,
                lunchBreakStartTime: lunchBreakStartTime,
                lunchBreakEndTime: lunchBreakEndTime,
                dinnerStartTime: dinnerStartTime, // 传递晚餐时间
                dinnerEndTime: dinnerEndTime,     // 传递晚餐时间
                customRestDays: customRestDays
            )
        }

        // 更新排班后立即更新当前状态
        updateStatus()
    }

    // MARK: - Status Update (状态更新)

    // 更新当前的 `currentStatus` 和 `statusText`
    func updateStatus() {
        // 确保有激活的排班计划
        guard let schedule = activeSchedule else {
            currentStatus = .offWork // 没有排班计划则默认为下班
            statusText = "No active schedule" // 无激活排班
            return
        }

        let now = Date() // 获取当前时间
        // 调用激活排班计划的 getCurrentStatus 方法获取当前状态
        currentStatus = schedule.getCurrentStatus(date: now)

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

    // 启动一个计时器，定期更新状态 (例如每分钟)
    private func startStatusTimer() {
        // 如果已有计时器在运行，先停止它
        stopStatusTimer()

        // 创建一个新的计时器，每60秒触发一次
        statusTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            // 计时器触发时，调用 updateStatus 更新状态
            // 使用 [weak self] 防止循环引用
            self?.updateStatus()
        }

        // 将计时器添加到当前 RunLoop 的 .common 模式，确保在滚动等 UI 操作时也能正常触发
        if let timer = statusTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    // 停止状态更新计时器
    private func stopStatusTimer() {
        statusTimer?.invalidate() // 使计时器失效
        statusTimer = nil // 释放计时器对象
    }

    // MARK: - Date Checking (日期检查)

    // 检查指定日期是工作日、休息日还是节假日
    func isWorkDay(date: Date) -> WorkDayType {
        // 确保有激活的排班计划
        guard let schedule = activeSchedule else {
            // 没有排班计划，默认返回休息日
            return .restDay
        }
        // 调用激活排班计划的 isWorkDay 方法
        return schedule.isWorkDay(date: date)
    }

    // MARK: - Custom Rest Day Management (自定义休息日管理)

    // 添加一个自定义休息日
    func addCustomRestDay(date: Date) {
        let calendar = Calendar.current
        // 获取日期部分，忽略时间
        let dateOnly = calendar.startOfDay(for: date)

        // 检查是否已存在该休息日 (避免重复添加)
        if !customRestDays.contains(where: { calendar.isDate($0, inSameDayAs: dateOnly) }) {
            customRestDays.append(dateOnly)
            // 添加后对休息日列表进行排序
            customRestDays.sort()

            // 如果当前排班类型是自定义，则更新激活的排班计划
            if currentScheduleType == .custom {
                updateActiveSchedule()
            }
            // 保存更改后的设置
            saveSettings()
        }
    }

    // 移除一个自定义休息日
    func removeCustomRestDay(date: Date) {
        let calendar = Calendar.current
        // 移除所有与指定日期在同一天的休息日
        customRestDays.removeAll { restDay in
            calendar.isDate(restDay, inSameDayAs: date)
        }

        // 如果当前排班类型是自定义，则更新激活的排班计划
        if currentScheduleType == .custom {
            updateActiveSchedule()
        }
        // 保存更改后的设置
        saveSettings()
    }

    // 添加多个自定义休息日
    func addMultipleCustomRestDays(dates: [Date]) {
        let calendar = Calendar.current

        for date in dates {
            let dateOnly = calendar.startOfDay(for: date)
            // 检查是否已存在，不存在则添加
            if !customRestDays.contains(where: { calendar.isDate($0, inSameDayAs: dateOnly) }) {
                customRestDays.append(dateOnly)
            }
        }

        // 添加完所有日期后对列表进行排序
        customRestDays.sort()

        // 如果当前排班类型是自定义，则更新激活的排班计划
        if currentScheduleType == .custom {
            updateActiveSchedule()
        }
        // 保存更改后的设置
        saveSettings()
    }

    // 清除所有自定义休息日
    func clearAllCustomRestDays() {
        customRestDays.removeAll()

        // 如果当前排班类型是自定义，则更新激活的排班计划
        if currentScheduleType == .custom {
            updateActiveSchedule()
        }
        // 保存更改后的设置
        saveSettings()
    }

    // MARK: - Holiday Management (节假日管理 - 通过 HolidayManager)

    // 添加一个节假日 (委托给 HolidayManager)
    func addHoliday(date: Date) {
        HolidayManager.shared.addHoliday(date: date)
        // 添加节假日后，需要更新当前状态，因为它可能影响 isWorkDay 的判断
        updateStatus()
    }

    // 移除一个节假日 (委托给 HolidayManager)
    func removeHoliday(date: Date) {
        HolidayManager.shared.removeHoliday(date: date)
        // 移除节假日后，同样需要更新当前状态
        updateStatus()
    }

    // MARK: - Settings Application (设置应用)

    // 应用新的工作和休息时间并更新排班计划
    // 重命名并扩展此方法以包含所有时间设置
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

    // 更改排班类型并更新
    func changeScheduleType(type: WorkScheduleType) {
        // 更新当前的排班类型
        currentScheduleType = type
        // 根据新的类型更新激活的排班计划
        updateActiveSchedule()
        // 保存更改后的设置
        saveSettings()
    }
}