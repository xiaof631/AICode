import SwiftUI

struct TodoMainView: View {
    @StateObject private var dataManager = TodoDataManager()
    
    var body: some View {
        TabView {
            // 统计页面
            TodoStatsView(dataManager: dataManager)
                .tabItem {
                    Label("统计", systemImage: "chart.bar")
                }
            
            // 功能页面
            TodoLogView(dataManager: dataManager)
                .tabItem {
                    Label("任务", systemImage: "list.bullet")
                }
            
            // 复盘页面
            ReflectionView(dataManager: dataManager)
                .tabItem {
                    Label("复盘", systemImage: "brain")
                }
        }
    }
}

struct TodoMainView_Previews: PreviewProvider {
    static var previews: some View {
        TodoMainView()
    }
}