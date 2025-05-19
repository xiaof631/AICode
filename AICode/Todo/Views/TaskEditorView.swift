import SwiftUI



struct TaskEditorView: View {
    let task: TodoTask?
    let onSave: (TodoTask) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var quadrant: TaskQuadrant
    @State private var isCompleted: Bool
    @State private var completionNotes: String
    @State private var incompleteReason: String
    
    init(task: TodoTask?, onSave: @escaping (TodoTask) -> Void) {
        self.task = task
        self.onSave = onSave
        
        _title = State(initialValue: task?.title ?? "")
        _quadrant = State(initialValue: task?.quadrant ?? .importantUrgent)
        _isCompleted = State(initialValue: task?.isCompleted ?? false)
        _completionNotes = State(initialValue: task?.completionNotes ?? "")
        _incompleteReason = State(initialValue: task?.incompleteReason ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("任务标题", text: $title)
                    
                    Picker("任务象限", selection: $quadrant) {
                        ForEach(TaskQuadrant.allCases) { quadrant in
                            HStack {
                                Circle()
                                    .fill(quadrant.color)
                                    .frame(width: 12, height: 12)
                                Text(quadrant.name)
                            }
                            .tag(quadrant)
                        }
                    }
                }
                
                Section(header: Text("完成状态")) {
                    Toggle("已完成", isOn: $isCompleted)
                    
                    if isCompleted {
                        TextField("完成备注", text: $completionNotes)
                    } else {
                        TextField("未完成原因", text: $incompleteReason)
                    }
                }
            }
            .navigationTitle(task == nil ? "新建任务" : "编辑任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let newTask = TodoTask(
                            id: task?.id ?? UUID(),
                            title: title,
                            quadrant: quadrant,
                            isCompleted: isCompleted
                        )
                        onSave(newTask)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
} 
