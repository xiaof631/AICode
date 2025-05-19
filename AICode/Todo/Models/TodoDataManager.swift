import Foundation
import SwiftUI

class TodoDataManager: ObservableObject {
    @Published var currentLog: DailyLog
    @Published var allLogs: [DailyLog] = []
    
    private let saveKey = "todo_logs"
    
    init() {
        // 初始化当前日志
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        self.currentLog = DailyLog(date: today)
        
        // 加载所有日志
        loadAllLogs()
        
        // 加载或创建今天的日志
        if let todayLog = allLogs.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            self.currentLog = todayLog
        } else {
            self.currentLog = DailyLog(date: today)
            allLogs.append(self.currentLog)
        }
    }
    
    // MARK: - 任务管理
    
    func addTask(_ task: TodoTask) {
        currentLog.tasks.append(task)
        saveData()
    }
    
    func updateTask(_ task: TodoTask) {
        if let index = currentLog.tasks.firstIndex(where: { $0.id == task.id }) {
            currentLog.tasks[index] = task
            saveData()
        }
    }
    
    func deleteTask(_ task: TodoTask) {
        currentLog.tasks.removeAll { $0.id == task.id }
        saveData()
    }
    
    // MARK: - 计划任务管理
    
    func addScheduledTask(_ task: ScheduledTask) {
        currentLog.scheduledTasks.append(task)
        saveData()
    }
    
    func updateScheduledTask(_ task: ScheduledTask) {
        if let index = currentLog.scheduledTasks.firstIndex(where: { $0.id == task.id }) {
            currentLog.scheduledTasks[index] = task
            saveData()
        }
    }
    
    func deleteScheduledTask(_ task: ScheduledTask) {
        currentLog.scheduledTasks.removeAll { $0.id == task.id }
        saveData()
    }
    
    func markScheduledTaskAsCompleted(_ task: ScheduledTask) {
        var updatedTask = task
        updatedTask.isCompleted = !task.isCompleted
        
        if updatedTask.isCompleted {
            // 创建完成记录
            let completedTask = CompletedTask(
                title: task.title,
                startTime: task.startTime,
                endTime: task.endTime,
                notes: task.notes,
                scheduledTaskId: task.id
            )
            currentLog.completedTasks.append(completedTask)
        } else {
            // 移除对应的完成记录
            currentLog.completedTasks.removeAll { $0.scheduledTaskId == task.id }
        }
        
        updateScheduledTask(updatedTask)
    }
    
    // MARK: - 完成任务管理
    
    func addCompletedTask(_ task: CompletedTask) {
        currentLog.completedTasks.append(task)
        saveData()
    }
    
    func updateCompletedTask(_ task: CompletedTask) {
        if let index = currentLog.completedTasks.firstIndex(where: { $0.id == task.id }) {
            currentLog.completedTasks[index] = task
            saveData()
        }
    }
    
    func deleteCompletedTask(_ task: CompletedTask) {
        currentLog.completedTasks.removeAll { $0.id == task.id }
        saveData()
    }
    
    // MARK: - 备注管理
    
    func updateNotes(_ notes: String) {
        currentLog.notes = notes
        saveData()
    }
    
    // MARK: - 数据持久化
    
    func saveData() {
        // 更新当前日志在 allLogs 中的记录
        if let index = allLogs.firstIndex(where: { $0.id == currentLog.id }) {
            allLogs[index] = currentLog
        } else {
            allLogs.append(currentLog)
        }
        
        // 保存到 UserDefaults
        if let encoded = try? JSONEncoder().encode(allLogs) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    func loadAllLogs() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([DailyLog].self, from: data) {
            allLogs = decoded
        }
    }
    
    func switchToDate(_ date: Date) {
        let calendar = Calendar.current
        if let log = allLogs.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            currentLog = log
        } else {
            let newLog = DailyLog(date: date)
            allLogs.append(newLog)
            currentLog = newLog
        }
    }
} 