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

    // --- 新增：下一个状态事件 ---
    @Published var nextEvent: (date: Date, status: WorkStatus)? = nil
    // --- 结束新增 ---

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
    
    // 新增：固定排班的每周工作日设置 [周一,周二,周三,周四,周五,周六,周日]
    @Published var fixedScheduleWorkingDays: [Bool] = [true, true, true, true, true, false, false]
    
    // MARK: - Private Properties (私有属性)

    // 当前激活的排班计划实例
    private var activeSchedule: WorkSchedule?

    // 用于定期更新状态的计时器
    private var statusTimer: Timer?
    
    // 设置文件名
    private let settingsFileName = "workScheduleSettings.json"
    
    // 用于编码和解码的数据模型
    private struct ScheduleSettings: Codable {
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
            fixedScheduleWorkingDays: fixedScheduleWorkingDays
        )
        
        // 使用FileStorage保存设置
        do {
            try FileStorage.shared.saveData(settings, toFile: settingsFileName)
        } catch {
            print("保存设置失败: \(error.localizedDescription)")
        }
    }

    // 从沙盒文件加载设置
    private func loadSettings() {
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
            
            print("设置已从文件加载")
        } catch {
            print("加载设置失败: \(error.localizedDescription)")
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
                dinnerEndTime: dinnerEndTime,     // 传递晚餐时间
                workingDays: fixedScheduleWorkingDays // 传递每周工作日设置
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

    // 更新当前的 `currentStatus`, `statusText`, 和 `nextEvent`
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

    // --- 新增：计算下一个状态事件的函数 ---
    private func calculateNextEvent(from currentDate: Date, schedule: WorkSchedule) {
        // 调用排班计划协议中的方法来获取下一个事件
        // 注意：这需要在 WorkSchedule 协议及其实现中添加 getNextEvent 方法
        nextEvent = schedule.getNextEvent(after: currentDate)
    }
    // --- 结束新增 ---

    // 启动一个计时器，定期更新状态 (例如每分钟)
    private func startStatusTimer() {
        // 如果已有计时器在运行，先停止它
        stopStatusTimer()
    
        // 创建一个新的计时器，每60秒触发一次
        // statusTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in // <- 原代码
        statusTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in // <- 建议修改为 60 秒
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
    
    // 更新固定排班的工作日设置
    func updateFixedScheduleWorkingDays(workingDays: [Bool]) {
        guard workingDays.count == 7 else { return }
        fixedScheduleWorkingDays = workingDays
        
        if currentScheduleType == .fixed {
            updateActiveSchedule()
        }
        saveSettings()
    }
    
    // 从 UserDefaults 迁移设置到文件存储
    private func migrateFromUserDefaults() {
        let defaults = UserDefaults.standard
        
        // 检查是否已经迁移过
        let migrationKey = "hasmigratedToFileStorage"
        if defaults.bool(forKey: migrationKey) {
            return
        }
        
        // 检查文件是否已存在
        if FileStorage.shared.fileExists(fileName: settingsFileName) {
            return
        }
        
        // 从 UserDefaults 加载设置
        if let savedTypeString = defaults.string(forKey: "scheduleType"),
           let savedType = WorkScheduleType(rawValue: savedTypeString) {
            currentScheduleType = savedType
        }
        
        if let startTimeInterval = defaults.object(forKey: "workStartTime") as? TimeInterval {
            workStartTime = Date(timeIntervalSince1970: startTimeInterval)
        }
        
        // ... 加载其他设置 ...
        
        // 保存到文件
        saveSettings()
        
        // 标记为已迁移
        defaults.set(true, forKey: migrationKey)
        defaults.synchronize()
    }
}





