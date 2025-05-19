import SwiftUI


struct ScheduleEditorView: View {
    let task: ScheduledTask?
    let onSave: (ScheduledTask) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes: String
    @State private var isParallel: Bool
    
    init(task: ScheduledTask?, onSave: @escaping (ScheduledTask) -> Void) {
        self.task = task
        self.onSave = onSave
        
        _title = State(initialValue: task?.title ?? "")
        _startTime = State(initialValue: task?.startTime ?? Date())
        _endTime = State(initialValue: task?.endTime ?? Date().addingTimeInterval(3600))
        _notes = State(initialValue: task?.notes ?? "")
        _isParallel = State(initialValue: task?.isParallel ?? false)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("计划标题", text: $title)
                    
                    DatePicker("开始时间", selection: $startTime, displayedComponents: [.hourAndMinute])
                    DatePicker("结束时间", selection: $endTime, displayedComponents: [.hourAndMinute])
                    
                    Toggle("并行任务", isOn: $isParallel)
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(task == nil ? "新建计划" : "编辑计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let newTask = ScheduledTask(
                            id: task?.id ?? UUID(),
                            title: title,
                            startTime: startTime,
                            endTime: endTime,
                            notes: notes,
                            isParallel: isParallel
                        )
                        onSave(newTask)
                        dismiss()
                    }
                    .disabled(title.isEmpty || endTime <= startTime)
                }
            }
        }
    }
} 
