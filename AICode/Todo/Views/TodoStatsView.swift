import SwiftUI
import CloudKit

struct TodoStatsView: View {
    @ObservedObject var dataManager: TodoDataManager
    @StateObject private var syncManager = ICloudSyncManager()
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var showDatePicker = false
    @State private var isSelectingStartDate = true
    @State private var filteredLogs: [DailyLog] = []
    @State private var showHistoryDatePicker = false
    @State private var showICloudLogin = false
    @State private var isICloudAvailable = false
    @State private var showSyncAlert = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(dataManager: TodoDataManager) {
        self.dataManager = dataManager
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let oneWeekAgo = calendar.date(byAdding: .day, value: -6, to: today)!
        
        _startDate = State(initialValue: oneWeekAgo)
        _endDate = State(initialValue: today)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    // 标题部分
                    headerView
                        .padding(.horizontal)
                    
                    // 统计内容
                    ScrollView {
                        VStack(spacing: 20) {
                            // 任务完成情况统计
                            taskCompletionStats
                            
                            // 时间利用率统计
                            timeUtilizationStats
                            
                            // 任务分布统计
                            taskDistributionStats
                            
                            // 每日任务完成趋势
                            dailyCompletionTrend
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            updateFilteredLogs()
            Task {
                isICloudAvailable = await syncManager.checkICloudStatus()
            }
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerView
        }
        .sheet(isPresented: $showHistoryDatePicker) {
            historyDatePickerView
        }
        .sheet(isPresented: $showICloudLogin) {
            ICloudLoginView(onLoginSuccess: {
                isICloudAvailable = true
                Task {
                    await syncData()
                }
            })
        }
        .alert("同步状态", isPresented: $showSyncAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            if let error = syncManager.syncError {
                Text("同步失败：\(error)")
            } else if let lastSync = syncManager.lastSyncDate {
                Text("上次同步时间：\(formatDate(lastSync, format: "yyyy-MM-dd HH:mm:ss"))")
            } else {
                Text("同步成功")
            }
        }
    }
    
    // 标题视图
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("任务统计")
                    .font(.system(size: horizontalSizeClass == .regular ? 34 : 28, weight: .bold))
                
                Spacer()
                
                // iCloud 同步按钮
                Button(action: {
                    if isICloudAvailable {
                        Task {
                            await syncData()
                        }
                    } else {
                        showICloudLogin = true
                    }
                }) {
                    HStack {
                        if syncManager.isSyncing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: isICloudAvailable ? "icloud.fill" : "icloud")
                            Text(isICloudAvailable ? "同步" : "iCloud")
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(isICloudAvailable ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(syncManager.isSyncing)
                
                // 历史记录按钮
                Button(action: {
                    showHistoryDatePicker = true
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("历史记录")
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            // 日期选择器按钮
            Button(action: {
                showDatePicker = true
            }) {
                HStack {
                    Text(dateRangeText)
                        .foregroundColor(.primary)
                    
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    // 计算网格列数
    private var gridColumns: [GridItem] {
        let columns = horizontalSizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: columns)
    }
    
    // 统计卡片视图
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: horizontalSizeClass == .regular ? 24 : 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: horizontalSizeClass == .regular ? 20 : 18, weight: .bold))
            
            Text(title)
                .font(.system(size: horizontalSizeClass == .regular ? 14 : 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    // 同步数据
    private func syncData() async {
        do {
            if isICloudAvailable {
                // 同步到 iCloud
                try await syncManager.syncToCloud(logs: dataManager.allLogs)
                showSyncAlert = true
            }
        } catch {
            showSyncAlert = true
        }
    }
    
    // 日期选择器视图
    private var datePickerView: some View {
        NavigationView {
            VStack {
                // 选择开始日期或结束日期的分段控制器
                Picker("选择日期类型", selection: $isSelectingStartDate) {
                    Text("开始日期").tag(true)
                    Text("结束日期").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // 日期选择器
                DatePicker(
                    isSelectingStartDate ? "开始日期" : "结束日期",
                    selection: isSelectingStartDate ? $startDate : $endDate,
                    in: isSelectingStartDate ? .distantPast...endDate : startDate...Date.distantFuture,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                Spacer()
            }
            .navigationBarTitle("选择日期区间", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    showDatePicker = false
                },
                trailing: Button("确定") {
                    // 确保开始日期不晚于结束日期
                    if startDate > endDate {
                        startDate = endDate
                    }
                    
                    updateFilteredLogs()
                    showDatePicker = false
                }
            )
        }
    }
    
    // 更新过滤后的日志
    private func updateFilteredLogs() {
        let calendar = Calendar.current
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let startOfEndDate = calendar.startOfDay(for: endDate)
        
        // 过滤日期范围内的日志
        filteredLogs = dataManager.allLogs.filter { log in
            let logDate = calendar.startOfDay(for: log.date)
            return (logDate >= startOfStartDate && logDate <= startOfEndDate)
        }
        
        // 按日期排序
        filteredLogs.sort { $0.date < $1.date }
    }
    
    // 日期范围文本
    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        
        let startText = formatter.string(from: startDate)
        let endText = formatter.string(from: endDate)
        
        return "\(startText) 至 \(endText)"
    }
    
    // 任务完成情况统计
    private var taskCompletionStats: some View {
        VStack(alignment: .leading) {
            Text("任务完成情况")
                .font(.headline)
                .padding(.bottom, 8)
            
            LazyVGrid(columns: gridColumns, spacing: 16) {
                statCard(
                    title: "总任务数",
                    value: "\(totalTasks)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                statCard(
                    title: "已完成",
                    value: "\(completedTasks)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                statCard(
                    title: "完成率",
                    value: completionRateText,
                    icon: "chart.pie",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // 时间利用率统计
    private var timeUtilizationStats: some View {
        VStack(alignment: .leading) {
            Text("时间利用情况")
                .font(.headline)
                .padding(.bottom, 8)
            
            LazyVGrid(columns: gridColumns, spacing: 16) {
                statCard(
                    title: "计划任务",
                    value: "\(totalScheduledTasks)项",
                    icon: "calendar",
                    color: .blue
                )
                
                statCard(
                    title: "已完成任务",
                    value: "\(totalCompletedTasks)项",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                statCard(
                    title: "计划总时长",
                    value: totalScheduledTimeText,
                    icon: "clock",
                    color: .purple
                )
                
                statCard(
                    title: "实际总时长",
                    value: totalCompletedTimeText,
                    icon: "stopwatch",
                    color: .pink
                )
                
                statCard(
                    title: "时间执行率",
                    value: timeExecutionRateText,
                    icon: "chart.bar",
                    color: .orange
                )
                
                statCard(
                    title: "平均任务时长",
                    value: averageTaskTimeText,
                    icon: "timer",
                    color: .teal
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // 任务分布统计
    private var taskDistributionStats: some View {
        VStack(alignment: .leading) {
            Text("任务分布情况")
                .font(.headline)
                .padding(.bottom, 8)
            
            LazyVGrid(columns: gridColumns, spacing: 16) {
                let importantUrgent = TaskQuadrant.importantUrgent
                let importantNotUrgent = TaskQuadrant.importantNotUrgent
                let notImportantUrgent = TaskQuadrant.notImportantUrgent
                let notImportantNotUrgent = TaskQuadrant.notImportantNotUrgent
                
                statCard(
                    title: importantUrgent.name,
                    value: "\(taskCountByQuadrant(importantUrgent))项",
                    icon: importantUrgent.icon,
                    color: importantUrgent.color
                )
                
                statCard(
                    title: importantNotUrgent.name,
                    value: "\(taskCountByQuadrant(importantNotUrgent))项",
                    icon: importantNotUrgent.icon,
                    color: importantNotUrgent.color
                )
                
                statCard(
                    title: notImportantUrgent.name,
                    value: "\(taskCountByQuadrant(notImportantUrgent))项",
                    icon: notImportantUrgent.icon,
                    color: notImportantUrgent.color
                )
                
                statCard(
                    title: notImportantNotUrgent.name,
                    value: "\(taskCountByQuadrant(notImportantNotUrgent))项",
                    icon: notImportantNotUrgent.icon,
                    color: notImportantNotUrgent.color
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // 每日任务完成趋势
    private var dailyCompletionTrend: some View {
        VStack(alignment: .leading) {
            Text("每日任务完成趋势")
                .font(.headline)
                .padding(.bottom, 8)
            
            if filteredLogs.isEmpty {
                Text("所选时间范围内没有数据")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(filteredLogs) { log in
                            let totalCount = log.tasks.count
                            let completedCount = log.tasks.filter { $0.isCompleted }.count
                            let completionRate = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
                            
                            VStack {
                                Text("\(Int(completionRate * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 6)
                                    .background(Color.blue)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: 30, height: max(20, 100 * completionRate))
                                
                                Text(formatDate(log.date, format: "MM/dd"))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.vertical)
                    .frame(height: 150)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // 格式化日期
    private func formatDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    // 计算属性 - 总任务数
    private var totalTasks: Int {
        return filteredLogs.reduce(0) { $0 + $1.tasks.count }
    }
    
    // 计算属性 - 已完成任务数
    private var completedTasks: Int {
        return filteredLogs.reduce(0) { $0 + $1.tasks.filter { $0.isCompleted }.count }
    }
    
    // 计算属性 - 完成率文本
    private var completionRateText: String {
        if totalTasks == 0 {
            return "0%"
        }
        
        let rate = Double(completedTasks) / Double(totalTasks) * 100
        return String(format: "%.1f%%", rate)
    }
    
    // 计算属性 - 总计划任务数
    private var totalScheduledTasks: Int {
        return filteredLogs.reduce(0) { $0 + $1.scheduledTasks.count }
    }
    
    // 计算属性 - 总完成任务数
    private var totalCompletedTasks: Int {
        return filteredLogs.reduce(0) { $0 + $1.completedTasks.count }
    }
    
    // 计算属性 - 计划总时长
    private var totalScheduledTimeText: String {
        let totalSeconds = filteredLogs.reduce(0.0) { $0 + $1.scheduledTasks.reduce(0.0) { $0 + $1.duration } }
        return formatTimeInterval(totalSeconds)
    }
    
    // 计算属性 - 实际总时长
    private var totalCompletedTimeText: String {
        let totalSeconds = filteredLogs.reduce(0.0) { $0 + $1.completedTasks.reduce(0.0) { $0 + $1.duration } }
        return formatTimeInterval(totalSeconds)
    }
    
    // 计算属性 - 时间执行率
    private var timeExecutionRateText: String {
        let scheduledTime = filteredLogs.reduce(0.0) { $0 + $1.scheduledTasks.reduce(0.0) { $0 + $1.duration } }
        guard scheduledTime > 0 else { return "0%" }
        let completedTime = filteredLogs.reduce(0.0) { $0 + $1.completedTasks.reduce(0.0) { $0 + $1.duration } }
        let rate = completedTime / scheduledTime * 100
        return String(format: "%.1f%%", rate)
    }
    
    // 计算属性 - 平均任务时长
    private var averageTaskTimeText: String {
        let completedTasksCount = totalCompletedTasks
        guard completedTasksCount > 0 else { return "0分钟" }
        let totalTime = filteredLogs.reduce(0.0) { $0 + $1.completedTasks.reduce(0.0) { $0 + $1.duration } }
        return formatTimeInterval(totalTime / Double(completedTasksCount))
    }
    
    // 格式化时间间隔
    private func formatTimeInterval(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    // 按象限统计任务数
    private func taskCountByQuadrant(_ quadrant: TaskQuadrant) -> Int {
        return filteredLogs.reduce(0) { $0 + $1.tasks.filter { $0.quadrant == quadrant }.count }
    }
    
    // 新增：历史日期选择器视图 - 移动到结构体内部
    private var historyDatePickerView: some View {
        NavigationView {
            VStack {
                // 日期选择器
                DatePicker(
                    "选择日期",
                    selection: Binding(
                        get: { Calendar.current.startOfDay(for: Date()) },
                        set: { newDate in
                            // 关闭弹窗并切换到选择的日期
                            showHistoryDatePicker = false
                            dataManager.switchToDate(newDate)
                        }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                // 显示可用的历史记录日期
                if !dataManager.allLogs.isEmpty {
                    List {
                        Section(header: Text("可用的历史记录")) {
                            ForEach(dataManager.allLogs.prefix(30)) { log in
                                Button(action: {
                                    showHistoryDatePicker = false
                                    dataManager.switchToDate(log.date)
                                }) {
                                    HStack {
                                        Text(formatDate(log.date, format: "yyyy年MM月dd日"))
                                        Spacer()
                                        if Calendar.current.isDate(log.date, inSameDayAs: dataManager.currentLog.date) {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Text("没有可用的历史记录")
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                }
                
                Spacer()
            }
            .navigationBarTitle("选择历史日期", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    showHistoryDatePicker = false
                },
                trailing: Button("今天") {
                    showHistoryDatePicker = false
                    dataManager.switchToDate(Date())
                }
            )
        }
    }
}

