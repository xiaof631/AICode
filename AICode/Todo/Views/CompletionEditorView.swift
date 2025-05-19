import SwiftUI

// 导入模型


struct CompletionEditorView: View {
    let task: CompletedTask?
    let onSave: (CompletedTask) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes: String
    
    init(task: CompletedTask?, onSave: @escaping (CompletedTask) -> Void) {
        self.task = task
        self.onSave = onSave
        
        _title = State(initialValue: task?.title ?? "")
        _startTime = State(initialValue: task?.startTime ?? Date())
        _endTime = State(initialValue: task?.endTime ?? Date().addingTimeInterval(3600))
        _notes = State(initialValue: task?.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("任务标题", text: $title)
                    
                    DatePicker("开始时间", selection: $startTime, displayedComponents: [.hourAndMinute])
                    DatePicker("结束时间", selection: $endTime, displayedComponents: [.hourAndMinute])
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(task == nil ? "新建完成记录" : "编辑完成记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let newTask = CompletedTask(
                            id: task?.id ?? UUID(),
                            title: title,
                            startTime: startTime,
                            endTime: endTime,
                            notes: notes,
                            scheduledTaskId: task?.scheduledTaskId
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
