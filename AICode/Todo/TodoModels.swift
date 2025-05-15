import Foundation
import SwiftUI
import CloudKit

// 任务四象限类型
enum TaskQuadrant: Int, Codable, CaseIterable, Identifiable {
    case important_urgent = 0      // 重要且紧急
    case important_notUrgent = 1   // 重要不紧急
    case notImportant_urgent = 2   // 不重要但紧急
    case notImportant_notUrgent = 3 // 不重要不紧急
    
    var id: Int { self.rawValue }
    
    var color: Color {
        switch self {
        case .important_urgent:
            return .red
        case .important_notUrgent:
            return .blue
        case .notImportant_urgent:
            return .orange
        case .notImportant_notUrgent:
            return .gray
        }
    }
    
    var name: String {
        switch self {
        case .important_urgent:
            return "重要且紧急"
        case .important_notUrgent:
            return "重要不紧急"
        case .notImportant_urgent:
            return "不重要但紧急"
        case .notImportant_notUrgent:
            return "不重要不紧急"
        }
    }
    
    // 新增：每个象限的图标
    var icon: String {
        switch self {
        case .important_urgent:
            return "exclamationmark.triangle.fill" // 警告图标，表示重要且紧急
        case .important_notUrgent:
            return "star.fill" // 星星图标，表示重要但不紧急
        case .notImportant_urgent:
            return "clock.fill" // 时钟图标，表示紧急但不重要
        case .notImportant_notUrgent:
            return "checkmark.circle" // 勾选图标，表示不重要不紧急
        }
    }
}

// 任务模型
struct TodoTask: Identifiable, Codable {
    var id: UUID
    var title: String
    var quadrant: TaskQuadrant
    var isCompleted: Bool
    var completionNotes: String // 新增：完成情况备注
    var incompleteReason: String // 新增：未完成原因说明
    
    init(id: UUID = UUID(), title: String, quadrant: TaskQuadrant = .important_urgent, isCompleted: Bool = false, completionNotes: String = "", incompleteReason: String = "") {
        self.id = id
        self.title = title
        self.quadrant = quadrant
        self.isCompleted = isCompleted
        self.completionNotes = completionNotes
        self.incompleteReason = incompleteReason
    }
}

// 计划任务模型
struct ScheduledTask: Identifiable, Codable {
    var id: UUID
    var title: String
    var startTime: Date
    var endTime: Date
    var isParallel: Bool
    var notes: String
    var isCompleted: Bool // 新增：是否已完成
    
    init(id: UUID = UUID(), title: String, startTime: Date, endTime: Date, isParallel: Bool = false, notes: String = "", isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.isParallel = isParallel
        self.notes = notes
        self.isCompleted = isCompleted
    }
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    var durationText: String {
        let minutes = Int(duration / 60)
        return "\(minutes)分钟"
    }
    
    var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}

// 实际完成的任务
struct CompletedTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var startTime: Date
    var endTime: Date
    var notes: String = ""
    var scheduledTaskId: UUID? // 关联的计划任务ID，如果有的话
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    var durationText: String {
        let minutes = Int(duration / 60)
        return "\(minutes)分钟"
    }
    
    var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}

// 日志数据模型
// 在DailyLog结构体中添加复盘字段
struct DailyLog: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var tasks: [TodoTask] = []
    var scheduledTasks: [ScheduledTask] = []
    var completedTasks: [CompletedTask] = []
    var notes: String = ""
    var reflection: Reflection? = nil  // 新增：每日复盘
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// 新增：复盘数据模型
struct Reflection: Codable {
    var description: String = ""  // 描述经过
    var analysis: String = ""     // 分析原因
    var improvement: String = ""  // 改进措施
}

// 数据管理类
class TodoDataManager: ObservableObject {
    @Published var currentLog: DailyLog
    @Published var allLogs: [DailyLog] = []
    @Published var iCloudAvailable: Bool = false
    
    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private let calendar = Calendar.current
    private let fileManager = FileManager.default
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    // 通知名称
    static let dataChangedNotification = Notification.Name("TodoDataManagerDataChanged")
    
    // 文件名格式
    private let fileNameFormat = "todo_log_%@.json"
    
    init() {
        // 初始化为今天的日志
        self.currentLog = DailyLog(date: Date())
        
        // 检查 iCloud 状态
        checkiCloudStatus()
        
        // 设置通知监听
        setupNotificationObservers()
        
        // 加载今天的日志
        loadTodayLog()
        
        // 加载所有日志
        loadAllLogs()
    }
    
    // 检查 iCloud 状态
    private func checkiCloudStatus() {
        CKContainer.default().accountStatus { [weak self] (status, error) in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.iCloudAvailable = true
                    print("iCloud 可用")
                    // 同步 iCloud 数据
                    self?.iCloudStore.synchronize()
                default:
                    self?.iCloudAvailable = false
                    print("iCloud 不可用: \(status.rawValue)")
                }
            }
        }
    }
    
    // 设置通知监听
    private func setupNotificationObservers() {
        // 监听 iCloud 数据变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ubiquitousKeyValueStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )
        
        // 监听应用进入前台
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // iCloud 数据变化处理
    @objc private func ubiquitousKeyValueStoreDidChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            print("检测到 iCloud 数据变化")
            self?.loadAllLogs()
            self?.loadTodayLog()
        }
    }
    
    // 应用进入前台处理
    @objc private func appWillEnterForeground() {
        DispatchQueue.main.async { [weak self] in
            print("应用进入前台，同步数据")
            self?.iCloudStore.synchronize()
            self?.loadTodayLog()
            self?.loadAllLogs()
        }
    }
    
    // 获取文档目录
    private func getDocumentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // 获取 iCloud 文档目录
    private func getiCloudDocumentsDirectory() -> URL? {
        return fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }
    
    // 获取日志文件名
    private func getLogFileName(for date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        return String(format: fileNameFormat, dateString)
    }
    
    // 加载今天的日志
    func loadTodayLog() {
        let today = calendar.startOfDay(for: Date())
        
        // 尝试从本地或 iCloud 加载
        if let loadedLog = loadLog(for: today) {
            self.currentLog = loadedLog
            print("成功加载今日日志")
        } else {
            // 如果没有找到，创建新的日志
            self.currentLog = DailyLog(date: today)
            print("创建新的今日日志")
            // 保存新创建的日志
            saveLog(self.currentLog)
        }
    }
    
    // 加载指定日期的日志
    func loadLog(for date: Date) -> DailyLog? {
        let startOfDay = calendar.startOfDay(for: date)
        let fileName = getLogFileName(for: startOfDay)
        
        // 首先尝试从 iCloud 加载
        if let iCloudURL = getiCloudDocumentsDirectory()?.appendingPathComponent(fileName) {
            do {
                // 确保 iCloud 目录存在
                try createDirectoryIfNeeded(at: iCloudURL.deletingLastPathComponent())
                
                // 检查文件是否存在
                if fileManager.fileExists(atPath: iCloudURL.path) {
                    let data = try Data(contentsOf: iCloudURL)
                    let log = try decoder.decode(DailyLog.self, from: data)
                    return log
                }
            } catch {
                print("从 iCloud 加载日志失败: \(error.localizedDescription)")
            }
        }
        
        // 如果 iCloud 加载失败，尝试从本地加载
        let localURL = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            if fileManager.fileExists(atPath: localURL.path) {
                let data = try Data(contentsOf: localURL)
                let log = try decoder.decode(DailyLog.self, from: data)
                return log
            }
        } catch {
            print("从本地加载日志失败: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // 加载所有日志
    func loadAllLogs() {
        var logs: [DailyLog] = []
        
        // 从本地和 iCloud 加载所有日志文件
        let localDirectory = getDocumentsDirectory()
        let iCloudDirectory = getiCloudDocumentsDirectory()
        
        // 合并本地和 iCloud 的文件列表
        var allFiles = Set<String>()
        
        // 获取本地文件
        do {
            let localFiles = try fileManager.contentsOfDirectory(at: localDirectory, includingPropertiesForKeys: nil)
            for file in localFiles {
                if file.lastPathComponent.starts(with: "todo_log_") && file.pathExtension == "json" {
                    allFiles.insert(file.lastPathComponent)
                }
            }
        } catch {
            print("读取本地目录失败: \(error.localizedDescription)")
        }
        
        // 获取 iCloud 文件
        if let iCloudDir = iCloudDirectory {
            do {
                try createDirectoryIfNeeded(at: iCloudDir)
                let iCloudFiles = try fileManager.contentsOfDirectory(at: iCloudDir, includingPropertiesForKeys: nil)
                for file in iCloudFiles {
                    if file.lastPathComponent.starts(with: "todo_log_") && file.pathExtension == "json" {
                        allFiles.insert(file.lastPathComponent)
                    }
                }
            } catch {
                print("读取 iCloud 目录失败: \(error.localizedDescription)")
            }
        }
        
        // 解析日期并加载日志
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for fileName in allFiles {
            // 从文件名中提取日期
            let prefix = "todo_log_"
            let suffix = ".json"
            guard fileName.hasPrefix(prefix) && fileName.hasSuffix(suffix) else { continue }
            
            let startIndex = fileName.index(fileName.startIndex, offsetBy: prefix.count)
            let endIndex = fileName.index(fileName.endIndex, offsetBy: -suffix.count)
            let dateString = String(fileName[startIndex..<endIndex])
            
            if let date = dateFormatter.date(from: dateString),
               let log = loadLog(for: date) {
                logs.append(log)
            }
        }
        
        // 按日期排序
        logs.sort { $0.date > $1.date }
        self.allLogs = logs
        
        print("加载了 \(logs.count) 个日志")
    }
    
    // 确保目录存在
    private func createDirectoryIfNeeded(at url: URL) throws {
        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    // 保存日志
    private func saveLog(_ log: DailyLog) {
        let fileName = getLogFileName(for: log.date)
        
        do {
            let data = try encoder.encode(log)
            
            // 保存到本地
            let localURL = getDocumentsDirectory().appendingPathComponent(fileName)
            try data.write(to: localURL)
            print("日志已保存到本地")
            
            // 保存到 iCloud
            if let iCloudURL = getiCloudDocumentsDirectory()?.appendingPathComponent(fileName) {
                try createDirectoryIfNeeded(at: iCloudURL.deletingLastPathComponent())
                try data.write(to: iCloudURL)
                print("日志已保存到 iCloud")
            }
            
            // 通知数据变化
            NotificationCenter.default.post(name: TodoDataManager.dataChangedNotification, object: self)
        } catch {
            print("保存日志失败: \(error.localizedDescription)")
        }
    }
    
    // 保存当前日志
    func saveData() {
        saveLog(currentLog)
        
        // 更新 allLogs 中的对应日志
        if let index = allLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: currentLog.date) }) {
            allLogs[index] = currentLog
        } else {
            allLogs.append(currentLog)
            allLogs.sort { $0.date > $1.date }
        }
    }
    
    // 切换到指定日期的日志
    func switchToDate(_ date: Date) {
        // 保存当前日志
        saveData()
        
        // 加载指定日期的日志
        let targetDate = calendar.startOfDay(for: date)
        if let log = loadLog(for: targetDate) {
            currentLog = log
        } else {
            currentLog = DailyLog(date: targetDate)
            saveLog(currentLog)
        }
    }
    
    // 添加待办任务
    func addTask(_ task: TodoTask) {
        currentLog.tasks.append(task)
        saveData()
    }
    
    // 更新待办任务
    func updateTask(_ task: TodoTask) {
        if let index = currentLog.tasks.firstIndex(where: { $0.id == task.id }) {
            currentLog.tasks[index] = task
            saveData()
        }
    }
    
    // 添加计划任务
    func addScheduledTask(_ task: ScheduledTask) {
        currentLog.scheduledTasks.append(task)
        // 按开始时间排序
        currentLog.scheduledTasks.sort { $0.startTime < $1.startTime }
        saveData()
    }
    
    // 更新计划任务
    func updateScheduledTask(_ task: ScheduledTask) {
        if let index = currentLog.scheduledTasks.firstIndex(where: { $0.id == task.id }) {
            currentLog.scheduledTasks[index] = task
            // 按开始时间排序
            currentLog.scheduledTasks.sort { $0.startTime < $1.startTime }
            saveData()
        }
    }
    
    // 添加完成任务
    func addCompletedTask(_ task: CompletedTask) {
        currentLog.completedTasks.append(task)
        // 按开始时间排序
        currentLog.completedTasks.sort { $0.startTime < $1.startTime }
        saveData()
    }
    
    // 更新完成任务
    func updateCompletedTask(_ task: CompletedTask) {
        if let index = currentLog.completedTasks.firstIndex(where: { $0.id == task.id }) {
            currentLog.completedTasks[index] = task
            // 按开始时间排序
            currentLog.completedTasks.sort { $0.startTime < $1.startTime }
            saveData()
        }
    }
    
    // 从计划任务创建完成任务
    func createCompletedTaskFromScheduled(_ scheduledTask: ScheduledTask) {
        let completedTask = CompletedTask(
            title: scheduledTask.title,
            startTime: scheduledTask.startTime,
            endTime: scheduledTask.endTime,
            notes: scheduledTask.notes,
            scheduledTaskId: scheduledTask.id
        )
        addCompletedTask(completedTask)
    }
    
    // 更新备注
    func updateNotes(_ notes: String) {
        currentLog.notes = notes
        saveData()
    }
    
    // 删除日志
    func deleteLog(at date: Date) {
        let fileName = getLogFileName(for: date)
        
        // 从本地删除
        let localURL = getDocumentsDirectory().appendingPathComponent(fileName)
        try? fileManager.removeItem(at: localURL)
        
        // 从 iCloud 删除
        if let iCloudURL = getiCloudDocumentsDirectory()?.appendingPathComponent(fileName) {
            try? fileManager.removeItem(at: iCloudURL)
        }
        
        // 更新 allLogs
        allLogs.removeAll { calendar.isDate($0.date, inSameDayAs: date) }
        
        // 如果删除的是当前日志，切换到今天
        if calendar.isDate(currentLog.date, inSameDayAs: date) {
            loadTodayLog()
        }
    }
}

// 在 TodoDataManager 中添加标记计划任务完成的方法
extension TodoDataManager {
    // 标记计划任务为完成并同步到实际完成栏
    func markScheduledTaskAsCompleted(_ task: ScheduledTask) {
        // 更新计划任务的完成状态
        if let index = currentLog.scheduledTasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            updatedTask.isCompleted = !task.isCompleted
            currentLog.scheduledTasks[index] = updatedTask
            
            // 如果标记为完成，则添加到实际完成栏
            if updatedTask.isCompleted {
                // 检查是否已经存在相同 ID 的完成任务
                let exists = currentLog.completedTasks.contains { $0.scheduledTaskId == task.id }
                
                if !exists {
                    // 创建完成任务并添加到实际完成栏
                    let completedTask = CompletedTask(
                        title: task.title,
                        startTime: task.startTime,
                        endTime: task.endTime,
                        notes: task.notes,
                        scheduledTaskId: task.id
                    )
                    addCompletedTask(completedTask)
                }
            } else {
                // 如果取消完成，则从实际完成栏中移除
                currentLog.completedTasks.removeAll { $0.scheduledTaskId == task.id }
            }
            
            // 保存数据
            saveData()
        }
    }
}
