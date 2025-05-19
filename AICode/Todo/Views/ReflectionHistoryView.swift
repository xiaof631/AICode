import SwiftUI

struct ReflectionHistoryView: View {
    @ObservedObject var dataManager: TodoDataManager
    @State private var selectedLog: DailyLog? = nil
    @State private var showingDetail = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.allLogs.filter { $0.reflection != nil }) { log in
                    Button(action: {
                        selectedLog = log
                        showingDetail = true
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(log.dateString)
                                    .font(.headline)
                                
                                if let reflection = log.reflection {
                                    Text(reflection.description.prefix(50) + (reflection.description.count > 50 ? "..." : ""))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("复盘历史")
            .sheet(isPresented: $showingDetail) {
                if let log = selectedLog {
                    HistoricalReflectionDetailView(log: log)
                }
            }
            .onAppear {
                // 确保加载所有日志
                dataManager.loadAllLogs()
            }
        }
    }
}

struct HistoricalReflectionDetailView: View {
    let log: DailyLog
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题部分
                HStack {
                    Text(log.dateString)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        // 关闭视图
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                if let reflection = log.reflection {
                    // 描述经过部分
                    reflectionSection(
                        title: "① 描述经过",
                        subtitle: "以便日后回顾时能想起当时的场景",
                        content: reflection.description,
                        color: .blue
                    )
                    
                    // 分析原因部分
                    reflectionSection(
                        title: "② 分析原因",
                        subtitle: "多问几个为什么，直到有深度的启发",
                        content: reflection.analysis,
                        color: .orange
                    )
                    
                    // 改进措施部分
                    reflectionSection(
                        title: "③ 改进措施",
                        subtitle: "尽可能提炼出一个认知点或行动点",
                        content: reflection.improvement,
                        color: .green
                    )
                } else {
                    Text("该日期没有复盘记录")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    // 复盘部分通用视图（只读）
    private func reflectionSection(title: String, subtitle: String, content: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(content)
                .padding(12)
                .frame(minHeight: 80)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray5).opacity(0.3))
        .cornerRadius(10)
    }
}

struct ReflectionHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ReflectionHistoryView(dataManager: TodoDataManager())
    }
}