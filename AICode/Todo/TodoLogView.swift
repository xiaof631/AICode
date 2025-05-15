import SwiftUI

struct TodoLogView: View {
    @ObservedObject var dataManager: TodoDataManager
    @State private var showingTaskEditor = false
    @State private var showingScheduleEditor = false
    @State private var showingCompletionEditor = false
    @State private var editingTask: TodoTask?
    @State private var editingScheduledTask: ScheduledTask?
    @State private var editingCompletedTask: CompletedTask?
    @State private var showingSaveConfirmation = false
    @State private var showingCopyDatePicker = false // 复制日期选择器状态
    @State private var showingHistoryView = false // 新增：历史记录视图状态
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题部分 - 显示当天日期和保存按钮
            VStack(spacing: 10) {
                // 第一行 - 标题
                Text(dataManager.currentLog.dateString)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 第二行 - 按钮
                HStack(spacing: 12) {
                    Spacer()
                    
                    // 新增：历史记录按钮
                    Button(action: {
                        // 确保加载所有日志
                        dataManager.loadAllLogs()
                        showingHistoryView = true
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("历史记录")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    // 快速复制按钮
                    Button(action: {
                        showingCopyDatePicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("快速复制")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        dataManager.saveData()
                        showingSaveConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("保存")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 顶部 - 当天所有任务
                    todoSection
                    
                    // 中部 - 计划和完成情况
                    HStack(alignment: .top, spacing: 10) {
                        // 左侧 - 当天计划
                        scheduleSection
                        
                        // 右侧 - 实际完成情况
                        completionSection
                    }
                    .frame(minHeight: 300)
                    
                    // 底部 - 备注栏
                    notesSection
                }
                .padding()
            }
        }
        .alert(isPresented: $showingSaveConfirmation) {
            Alert(
                title: Text("保存成功"),
                message: Text("今日任务数据已成功保存"),
                dismissButton: .default(Text("确定"))
            )
        }
        // 日期选择器弹窗
        .sheet(isPresented: $showingCopyDatePicker) {
            copyDatePickerView
        }
        // 新增：历史记录视图弹窗
        .sheet(isPresented: $showingHistoryView) {
            historyView
        }
    }
    
    // 顶部任务区域
    private var todoSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("今日任务")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    editingTask = nil
                    showingTaskEditor = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            if dataManager.currentLog.tasks.isEmpty {
                Text("暂无任务")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(dataManager.currentLog.tasks) { task in
                    TaskRow(task: task, dataManager: dataManager)
                        .onTapGesture {
                            editingTask = task
                            showingTaskEditor = true
                        }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .sheet(isPresented: $showingTaskEditor) {
            TaskEditorView(
                task: editingTask,
                onSave: { newTask in
                    if let editingTask = editingTask {
                        var updatedTask = editingTask
                        updatedTask.title = newTask.title
                        updatedTask.quadrant = newTask.quadrant
                        updatedTask.isCompleted = newTask.isCompleted
                        updatedTask.completionNotes = newTask.completionNotes
                        updatedTask.incompleteReason = newTask.incompleteReason
                        dataManager.updateTask(updatedTask)
                    } else {
                        dataManager.addTask(newTask)
                    }
                    self.editingTask = nil
                }
            )
        }
    }
    
    // 中部左侧计划区域
    private var scheduleSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("计划安排")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    editingScheduledTask = nil
                    showingScheduleEditor = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            if dataManager.currentLog.scheduledTasks.isEmpty {
                Text("暂无计划")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(dataManager.currentLog.scheduledTasks) { task in
                    ScheduledTaskRow(task: task, dataManager: dataManager)
                        .onTapGesture {
                            editingScheduledTask = task
                            showingScheduleEditor = true
                        }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .sheet(isPresented: $showingScheduleEditor) {
            ScheduleEditorView(
                task: editingScheduledTask,
                onSave: { newTask in
                    if let editingTask = editingScheduledTask {
                        var updatedTask = editingTask
                        updatedTask.title = newTask.title
                        updatedTask.startTime = newTask.startTime
                        updatedTask.endTime = newTask.endTime
                        updatedTask.isParallel = newTask.isParallel
                        updatedTask.notes = newTask.notes
                        dataManager.updateScheduledTask(updatedTask)
                    } else {
                        dataManager.addScheduledTask(newTask)
                    }
                    self.editingScheduledTask = nil
                }
            )
        }
    }
    
    // 中部右侧完成情况区域
    private var completionSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("实际完成")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    editingCompletedTask = nil
                    showingCompletionEditor = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            if dataManager.currentLog.completedTasks.isEmpty {
                Text("暂无完成记录")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(dataManager.currentLog.completedTasks) { task in
                    CompletedTaskRow(task: task)
                        .onTapGesture {
                            editingCompletedTask = task
                            showingCompletionEditor = true
                        }
                }
            }
            
            // 移除了"从计划导入"部分
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .sheet(isPresented: $showingCompletionEditor) {
            CompletionEditorView(
                task: editingCompletedTask,
                onSave: { newTask in
                    if let editingTask = editingCompletedTask {
                        var updatedTask = editingTask
                        updatedTask.title = newTask.title
                        updatedTask.startTime = newTask.startTime
                        updatedTask.endTime = newTask.endTime
                        updatedTask.notes = newTask.notes
                        dataManager.updateCompletedTask(updatedTask)
                    } else {
                        dataManager.addCompletedTask(newTask)
                    }
                    self.editingCompletedTask = nil
                }
            )
        }
    }
    
    // 底部备注区域
    private var notesSection: some View {
        VStack(alignment: .leading) {
            Text("备注")
                .font(.headline)
            
            TextEditor(text: Binding(
                get: { dataManager.currentLog.notes },
                set: { dataManager.updateNotes($0) }
            ))
            .frame(minHeight: 100)
            .padding(4)
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    
    // 新增：历史记录视图
    private var historyView: some View {
        NavigationView {
            VStack {
                Text("历史记录")
                    .font(.headline)
                    .padding()
                
                if dataManager.allLogs.isEmpty {
                    Text("没有可用的历史记录")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(dataManager.allLogs.sorted(by: { $0.date > $1.date })) { log in
                            NavigationLink(destination: HistoryDetailView(log: log)) {
                                HStack {
                                    Text(formatDate(log.date))
                                    Spacer()
                                        
                                    VStack(alignment: .trailing) {
                                        Text("任务: \(log.tasks.count)项")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        
                                        Text("计划: \(log.scheduledTasks.count)项")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                        
                                        Text("完成: \(log.completedTasks.count)项")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("历史记录")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("关闭") {
                showingHistoryView = false
            }
        )
    }

    // 新增：历史详情视图
    struct HistoryDetailView: View {
        let log: DailyLog
        
        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    // 日期标题
                    Text(formatDate(log.date))
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // 任务部分
                    if !log.tasks.isEmpty {
                        historySection(title: "任务", count: log.tasks.count) {
                            ForEach(log.tasks) { task in
                                HStack {
                                    Circle()
                                        .fill(task.quadrant.color)
                                        .frame(width: 12, height: 12)
                                    
                                    Text(task.title)
                                        .strikethrough(task.isCompleted)
                                        .foregroundColor(task.isCompleted ? .gray : .primary)
                                    
                                    Spacer()
                                    
                                    Text(task.quadrant.name)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    // 计划部分
                    if !log.scheduledTasks.isEmpty {
                        historySection(title: "计划安排", count: log.scheduledTasks.count) {
                            ForEach(log.scheduledTasks) { task in
                                HStack(spacing: 8) {
                                    Text(task.timeRangeText)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .frame(width: 90, alignment: .leading)
                                    
                                    if task.isParallel {
                                        Image(systemName: "arrow.triangle.branch")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                    }
                                    
                                    Text(task.title)
                                        .font(.body)
                                        .lineLimit(1)
                                        .foregroundColor(task.isCompleted ? .gray : .primary)
                                    
                                    Spacer()
                                    
                                    Text("(\(task.durationText))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    // 完成情况部分
                    if !log.completedTasks.isEmpty {
                        historySection(title: "实际完成", count: log.completedTasks.count) {
                            ForEach(log.completedTasks) { task in
                                HStack(spacing: 8) {
                                    Text(task.timeRangeText)
                                        .font(.caption)
                                        .foregroundColor(task.scheduledTaskId == nil ? .orange : .green)
                                        .frame(width: 90, alignment: .leading)
                                    
                                    Text(task.title)
                                        .font(.body)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text("(\(task.durationText))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    // 备注部分
                    if !log.notes.isEmpty {
                        VStack(alignment: .leading) {
                            Text("备注")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            Text(log.notes)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitle("详细记录", displayMode: .inline)
        }
        
        // 历史记录部分通用视图
        private func historySection<Content: View>(title: String, count: Int, @ViewBuilder content: @escaping () -> Content) -> some View {
            VStack(alignment: .leading) {
                HStack {
                    Text(title)
                        .font(.headline)
                    
                    Text("(\(count)项)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding(.bottom, 8)
                
                content()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        
        // 格式化日期函数
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月dd日 EEEE"
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.string(from: date)
        }
    }

}


extension TodoLogView{
    // 复制日期选择器视图
    private var copyDatePickerView: some View {
        NavigationView {
            VStack {
                Text("选择要复制的日期")
                    .font(.headline)
                    .padding()
                
                if dataManager.allLogs.isEmpty {
                    Text("没有可用的历史记录")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(dataManager.allLogs.filter { log in
                            // 过滤掉当前日期
                            !Calendar.current.isDate(log.date, inSameDayAs: dataManager.currentLog.date)
                        }) { log in
                            Button(action: {
                                copyFromLog(log)
                                showingCopyDatePicker = false
                            }) {
                                HStack {
                                    Text(formatDate(log.date))
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("任务: \(log.tasks.count)项")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        
                                        Text("计划: \(log.scheduledTasks.count)项")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationBarTitle("快速复制", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    showingCopyDatePicker = false
                }
            )
        }
    }
    
    // 格式化日期函数
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    // 从历史日志复制内容
    private func copyFromLog(_ log: DailyLog) {
        // 弹出确认对话框
        let alert = UIAlertController(
            title: "确认复制",
            message: "您要复制哪些内容？",
            preferredStyle: .alert
        )
        
        // 只复制任务
        alert.addAction(UIAlertAction(title: "只复制任务", style: .default) { _ in
            self.copyTasks(from: log)
        })
        
        // 只复制计划
        alert.addAction(UIAlertAction(title: "只复制计划", style: .default) { _ in
            self.copySchedules(from: log)
        })
        
        // 全部复制
        alert.addAction(UIAlertAction(title: "全部复制", style: .default) { _ in
            self.copyTasks(from: log)
            self.copySchedules(from: log)
        })
        
        // 取消
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 显示对话框
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    // 复制任务
    private func copyTasks(from log: DailyLog) {
        for task in log.tasks {
            var newTask = task
            newTask.id = UUID() // 生成新的ID
            newTask.isCompleted = false // 重置完成状态
            dataManager.addTask(newTask)
        }
    }
    
    // 复制计划
    private func copySchedules(from log: DailyLog) {
        for scheduledTask in log.scheduledTasks {
            var newTask = scheduledTask
            newTask.id = UUID() // 生成新的ID
            newTask.isCompleted = false // 重置完成状态
            
            // 调整时间到当前日期
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let originalDate = calendar.startOfDay(for: scheduledTask.startTime)
            
            // 计算时间差
            let startComponents = calendar.dateComponents([.hour, .minute], from: scheduledTask.startTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: scheduledTask.endTime)
            
            // 创建新的时间
            newTask.startTime = calendar.date(bySettingHour: startComponents.hour ?? 0, minute: startComponents.minute ?? 0, second: 0, of: today) ?? today
            newTask.endTime = calendar.date(bySettingHour: endComponents.hour ?? 0, minute: endComponents.minute ?? 0, second: 0, of: today) ?? today
            
            dataManager.addScheduledTask(newTask)
        }
    }
}




// 任务行视图
struct TaskRow: View {
    let task: TodoTask
    @ObservedObject var dataManager: TodoDataManager
    
    var body: some View {
        HStack {
            // 添加复选框
            Button(action: {
                // 标记任务为完成
                var updatedTask = task
                updatedTask.isCompleted = !task.isCompleted
                dataManager.updateTask(updatedTask)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            Circle()
                .fill(task.quadrant.color)
                .frame(width: 12, height: 12)
            
            Text(task.title)
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .gray : .primary)
            
            Spacer()
            
            Text(task.quadrant.name)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

// 计划任务行视图
struct ScheduledTaskRow: View {
    let task: ScheduledTask
    @ObservedObject var dataManager: TodoDataManager
    
    var body: some View {
        HStack(spacing: 8) {
            // 添加复选框
            Button(action: {
                // 标记计划任务为完成并同步到实际完成栏
                dataManager.markScheduledTaskAsCompleted(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(task.timeRangeText)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 90, alignment: .leading)
            
            if task.isParallel {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
            
            Text(task.title)
                .font(.body)
                .lineLimit(1)
                .foregroundColor(task.isCompleted ? .gray : .primary)
            
            Spacer()
            
            Text("(\(task.durationText))")
                .font(.caption)
                .foregroundColor(.gray)
            
            if !task.notes.isEmpty {
                Image(systemName: "doc.text")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(.systemGray5).opacity(0.3))
        .cornerRadius(6)
    }
}

// 完成任务行视图
struct CompletedTaskRow: View {
    let task: CompletedTask
    
    var body: some View {
        HStack(spacing: 8) {
            Text(task.timeRangeText)
                .font(.caption)
                .foregroundColor(task.scheduledTaskId == nil ? .orange : .green)
                .frame(width: 90, alignment: .leading)
            
            Text(task.title)
                .font(.body)
                .lineLimit(1)
            
            Spacer()
            
            Text("(\(task.durationText))")
                .font(.caption)
                .foregroundColor(.gray)
            
            if !task.notes.isEmpty {
                Image(systemName: "doc.text")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(task.scheduledTaskId == nil ? .systemOrange : .systemGreen).opacity(0.1))
        .cornerRadius(6)
    }
}

struct TodoLogView_Previews: PreviewProvider {
    static var previews: some View {
        TodoLogView(dataManager: TodoDataManager())
    }
}



