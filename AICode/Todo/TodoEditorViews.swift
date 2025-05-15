import SwiftUI

// 任务编辑视图
struct TaskEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let task: TodoTask?
    let onSave: (TodoTask) -> Void
    
    @State private var title: String
    @State private var quadrant: TaskQuadrant
    @State private var isCompleted: Bool
    
    @State private var completionNotes: String // 新增：完成情况备注
    @State private var incompleteReason: String // 新增：未完成原因说明
    
    init(task: TodoTask?, onSave: @escaping (TodoTask) -> Void) {
        self.task = task
        self.onSave = onSave
        
        _title = State(initialValue: task?.title ?? "")
        _quadrant = State(initialValue: task?.quadrant ?? .important_urgent)
        _isCompleted = State(initialValue: task?.isCompleted ?? false)
        
        _completionNotes = State(initialValue: task?.completionNotes ?? "")
        _incompleteReason = State(initialValue: task?.incompleteReason ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务信息")) {
                    TextField("任务标题", text: $title)
                    
                    Picker("重要性与紧急性", selection: $quadrant) {
                        ForEach(TaskQuadrant.allCases) { quadrant in
                            Text(quadrant.name).tag(quadrant)
                        }
                    }
                    
                    Toggle("已完成", isOn: $isCompleted)
                }
                
                Section(header: Text("备注信息")) {
                    if isCompleted {
                        // 如果任务已完成，显示完成情况备注
                        TextField("完成情况说明", text: $completionNotes)
                            .frame(height: 60)
                    } else {
                        // 如果任务未完成，显示未完成原因
                        TextField("未完成原因说明", text: $incompleteReason)
                            .frame(height: 60)
                    }
                }
            }
            .navigationTitle(task == nil ? "添加任务" : "编辑任务")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    let newTask = TodoTask(
                        id: task?.id ?? UUID(),
                        title: title,
                        quadrant: quadrant,
                        isCompleted: isCompleted
                    )
                    onSave(newTask)
                    presentationMode.wrappedValue.dismiss()
                }
                    .disabled(title.isEmpty)
            )
        }
    }
}

// 计划任务编辑视图
struct ScheduleEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let task: ScheduledTask?
    let onSave: (ScheduledTask) -> Void
    
    @State private var title: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var isParallel: Bool
    @State private var notes: String
    
    init(task: ScheduledTask?, onSave: @escaping (ScheduledTask) -> Void) {
        self.task = task
        self.onSave = onSave
        
        let now = Date()
        let calendar = Calendar.current
        let defaultStart = calendar.date(bySettingHour: calendar.component(.hour, from: now), minute: 0, second: 0, of: now) ?? now
        let defaultEnd = calendar.date(byAdding: .hour, value: 1, to: defaultStart) ?? now
        
        _title = State(initialValue: task?.title ?? "")
        _startTime = State(initialValue: task?.startTime ?? defaultStart)
        _endTime = State(initialValue: task?.endTime ?? defaultEnd)
        _isParallel = State(initialValue: task?.isParallel ?? false)
        _notes = State(initialValue: task?.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务信息")) {
                    TextField("任务标题", text: $title)
                    
                    DatePicker("开始时间", selection: $startTime, displayedComponents: .hourAndMinute)
                    
                    DatePicker("结束时间", selection: $endTime, displayedComponents: .hourAndMinute)
                        .onChange(of: endTime) { newValue in
                            if newValue < startTime {
                                endTime = startTime
                            }
                        }
                    
                    Toggle("并行任务", isOn: $isParallel)
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(task == nil ? "添加计划" : "编辑计划")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    let newTask = ScheduledTask(
                        id: task?.id ?? UUID(),
                        title: title,
                        startTime: startTime,
                        endTime: endTime,
                        isParallel: isParallel,
                        notes: notes
                    )
                    onSave(newTask)
                    presentationMode.wrappedValue.dismiss()
                }
                    .disabled(title.isEmpty || endTime < startTime)
            )
        }
    }
}

// 完成任务编辑视图
struct CompletionEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let task: CompletedTask?
    let onSave: (CompletedTask) -> Void
    
    @State private var title: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes: String
    
    init(task: CompletedTask?, onSave: @escaping (CompletedTask) -> Void) {
        self.task = task
        self.onSave = onSave
        
        let now = Date()
        let calendar = Calendar.current
        let defaultStart = calendar.date(bySettingHour: calendar.component(.hour, from: now), minute: 0, second: 0, of: now) ?? now
        let defaultEnd = calendar.date(byAdding: .hour, value: 1, to: defaultStart) ?? now
        
        _title = State(initialValue: task?.title ?? "")
        _startTime = State(initialValue: task?.startTime ?? defaultStart)
        _endTime = State(initialValue: task?.endTime ?? defaultEnd)
        _notes = State(initialValue: task?.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务信息")) {
                    TextField("任务标题", text: $title)
                    
                    DatePicker("开始时间", selection: $startTime, displayedComponents: .hourAndMinute)
                    
                    DatePicker("结束时间", selection: $endTime, displayedComponents: .hourAndMinute)
                        .onChange(of: endTime) { newValue in
                            if newValue < startTime {
                                endTime = startTime
                            }
                        }
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(task == nil ? "添加完成记录" : "编辑完成记录")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    let newTask = CompletedTask(
                        id: task?.id ?? UUID(),
                        title: title,
                        startTime: startTime,
                        endTime: endTime,
                        notes: notes,
                        scheduledTaskId: task?.scheduledTaskId
                    )
                    onSave(newTask)
                    presentationMode.wrappedValue.dismiss()
                }
                    .disabled(title.isEmpty || endTime < startTime)
            )
        }
    }
}
